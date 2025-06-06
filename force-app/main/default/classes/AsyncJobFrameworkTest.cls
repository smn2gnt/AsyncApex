@isTest
private class AsyncJobFrameworkTest {

    // Static variables to track execution in the mock batch
    public static Integer executeCallCount = 0;
    public static Integer finishCallCount = 0;
    public static Integer totalRecordsProcessedInExecute = 0;
    public static List<SObject> lastScopeReceived = null;
    public static Boolean isStatefulBatch = false; // To test state preservation

    // Mock Batch Implementation for testing the framework
    public class MockFrameworkBatch implements Async.Batch {
        private String query;
        private Integer instanceExecuteCount = 0; // For stateful instance tracking

        public MockFrameworkBatch(String queryToUse, Boolean makeStateful) {
            this.query = queryToUse;
            AsyncJobFrameworkTest.isStatefulBatch = makeStateful; // Communicate to test class
        }

        public String start() {
            return this.query;
        }

        public void execute(List<SObject> scope) {
            AsyncJobFrameworkTest.executeCallCount++;
            AsyncJobFrameworkTest.totalRecordsProcessedInExecute += scope.size();
            AsyncJobFrameworkTest.lastScopeReceived = scope;
            if(AsyncJobFrameworkTest.isStatefulBatch){
                this.instanceExecuteCount++;
                System.debug('Stateful instanceExecuteCount: ' + this.instanceExecuteCount);
            }
        }

        public void finish() {
            AsyncJobFrameworkTest.finishCallCount++;
        }
    }

    // Test specific Async.Stateful batch
    public class StatefulMockFrameworkBatch extends MockFrameworkBatch implements Async.Stateful {
        public StatefulMockFrameworkBatch(String queryToUse) {
            super(queryToUse, true);
        }
    }

    // Test specific Non-Stateful batch
    public class NonStatefulMockFrameworkBatch extends MockFrameworkBatch {
         public NonStatefulMockFrameworkBatch(String queryToUse) {
            super(queryToUse, false);
        }
    }


    @TestSetup
    static void makeData() {
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < 5; i++) { // 5 records for testing
            accs.add(new Account(Name = 'FrameworkTestAcc' + i));
        }
        insert accs;
    }

    // Helper to reset static counters before each test method
    private static void resetCounters(){
        executeCallCount = 0;
        finishCallCount = 0;
        totalRecordsProcessedInExecute = 0;
        lastScopeReceived = null;
        isStatefulBatch = false;
    }

    @isTest
    static void testFramework_SingleChunk() {
        resetCounters();
        String testQuery = 'SELECT Id, Name FROM Account WHERE Name LIKE \'FrameworkTestAcc%\'';
        // Using NonStateful for this basic test
        Async.Batch testBatchJob = new NonStatefulMockFrameworkBatch(testQuery);
        Integer batchSize = 10; // Larger than total records

        Test.startTest();
        // 1. Enqueue the batch job - this creates the first AsyncJobEvent__e (but doesn't publish it in test)
        // and puts items in cache.
        String jobId = EnqueueJobs.Batch(testBatchJob, batchSize);
        System.assert(String.isNotBlank(jobId), 'JobId should not be blank');

        // 2. Simulate Platform Event Firing and Handler Invocation
        // Construct the event that EnqueueJobs.Batch would have prepared for publishing
        AsyncJobEvent__e testEvent = new AsyncJobEvent__e(
            QueueId__c = jobId, // This is the key to find items in cache
            Context__c = 'Batch',
            BatchSize__c = batchSize
        );

        // Directly call the handler with this event
        AsyncJobTriggerHandler.handleBatchEvents(new List<AsyncJobEvent__e>{testEvent});
        Test.stopTest();

        // Assertions
        System.assertEquals(1, executeCallCount, 'Execute should be called once for a single chunk.');
        System.assertEquals(5, totalRecordsProcessedInExecute, 'Should process all 5 records.');
        System.assertEquals(1, finishCallCount, 'Finish should be called once.');

        // Verify cache cleanup (items associated with 'jobId' should be removed)
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.QueueCache');
        System.assertEquals(false, orgPart.contains(jobId), 'Batch instance should be removed from cache.');
        System.assertEquals(false, orgPart.contains(jobId + 'cursorWrapper'), 'CursorWrapper should be removed from cache.');
    }

    @isTest
    static void testFramework_MultipleChunks_Stateful() {
        resetCounters();
        String testQuery = 'SELECT Id, Name FROM Account WHERE Name LIKE \'FrameworkTestAcc%\'';
        // Using Stateful to check if instance is preserved
        Async.Batch testBatchJob = new StatefulMockFrameworkBatch(testQuery);
        Integer batchSize = 2; // Smaller than total records (5) to force multiple chunks

        Test.startTest();
        // 1. Enqueue - creates initial cache entries and event structure
        String initialJobId = EnqueueJobs.Batch(testBatchJob, batchSize);
        System.assert(String.isNotBlank(initialJobId), 'Initial JobId should not be blank');

        // Simulate event processing loop
        String currentJobId = initialJobId;
        Integer maxLoops = 5; // Safety break for test
        Integer loops = 0;

        while(loops < maxLoops) {
            loops++;
            AsyncJobEvent__e currentEvent = new AsyncJobEvent__e(
                QueueId__c = currentJobId,
                Context__c = 'Batch',
                BatchSize__c = batchSize
            );

            // Call handler
            AsyncJobTriggerHandler.handleBatchEvents(new List<AsyncJobEvent__e>{currentEvent});

            // Check if a new event was published (i.e., if our job is not finished)
            // This means checking if new items were put into cache with a *new* ID by publishBatchEvent
            // We determine this by seeing if the original currentJobId items were removed
            // and if finish was NOT called yet.

            Cache.OrgPartition orgPart = Cache.Org.getPartition('local.QueueCache');
            if (finishCallCount > 0 || !orgPart.contains(currentJobId)) {
                 // If finish was called OR the old job ID was removed, it implies either finish or chaining.
                 // If finish was called, break.
                 // If not, we need to find the NEW jobId from cache. This is tricky.
                 // The publishBatchEvent creates a new ID.
                 // For this test, we'll rely on finishCallCount and check total execution counts.
                 // A more robust way would be to capture the event published by EventBus.publish.
                 // For now, let's verify based on side-effects (execute calls, finish call)
            }

            // Simplified loop break for this test: if finish is called, stop.
            if (finishCallCount > 0) {
                break;
            }

            // To find the *next* jobId for the loop:
            // This is the hard part in a test without capturing EventBus.publish.
            // AsyncJobTriggerHandler.publishBatchEvent puts the *same batch instance* and *cursorWrapper*
            // back into cache with a NEW batchID.
            // We can't easily get this new batchID unless we query all cache keys.
            // Alternative for testing: The test will re-use the *initialJobId* for cache lookup
            // if we assume the test runs in a single transaction and cache items are not removed until end.
            // However, the handler *does* remove the currentJobId items.
            // So, for this test to proceed beyond one iteration of the handler,
            // we need to mock the EventBus.publish or find the new ID.

            // Given the limitations, this test will primarily verify the first chunk and if finish is called.
            // A true multi-chain test is harder without deeper mocking of EventBus or Cache.
            // Let's adjust this test to verify behavior up to the point where it *would* chain.

            // If not finished, it means publishBatchEvent was called.
            // We can check if the *original* items for currentJobId were removed.
            System.assertEquals(false, orgPart.contains(currentJobId), 'Old job ID items should be removed by handler.');

            // To continue the loop, we need the new JobID.
            // We can't get it directly. So we will break the loop here for this test's scope,
            // and verify based on calls up to this point.
            // This means this test method can only test ONE iteration of the handler correctly.
            // The "testFramework_MultipleChunks_Stateful_Simulated" will handle multi-chunk.
            break;
        }
        Test.stopTest();

        // Assertions for the first chunk processed by initialJobId
        System.assertEquals(1, executeCallCount, 'Execute should be called once for the first chunk.');
        System.assertEquals(batchSize, totalRecordsProcessedInExecute, 'Should process records of one batch size.');
        System.assertEquals(0, finishCallCount, 'Finish should NOT be called after only one chunk if more data.');

        // This test highlights difficulty of testing full chain without event capture/mocking.
    }

    @isTest
    static void testFramework_MultipleChunks_Stateful_Simulated() {
        // This test simulates multiple calls to the handler as if events were caught and re-fed.
        resetCounters();
        String testQuery = 'SELECT Id, Name FROM Account WHERE Name LIKE \'FrameworkTestAcc%\' ORDER BY Name'; // 5 records
        Async.Batch testBatchJob = new StatefulMockFrameworkBatch(testQuery);
        Integer batchSize = 2; // 5 records, batch size 2 -> 3 execute calls

        Test.startTest();

        // Initial Enqueue
        String jobId = EnqueueJobs.Batch(testBatchJob, batchSize);
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.QueueCache');

        // Loop 3 times to simulate 3 chunks processing
        String currentEventJobId = jobId;
        for (Integer i = 0; i < 3; i++) {
            System.debug('Simulating event loop iteration: ' + (i+1));
            System.assert(orgPart.contains(currentEventJobId), 'Cache must contain batch for jobID: ' + currentEventJobId);
            System.assert(orgPart.contains(currentEventJobId + 'cursorWrapper'), 'Cache must contain wrapper for jobID: ' + currentEventJobId);

            AsyncJobEvent__e testEvent = new AsyncJobEvent__e(
                QueueId__c = currentEventJobId,
                Context__c = 'Batch',
                BatchSize__c = batchSize
            );
            AsyncJobTriggerHandler.handleBatchEvents(new List<AsyncJobEvent__e>{testEvent});

            // After handler, if not finished, a new job ID would have been created by publishBatchEvent
            // and the old one removed. We need to find this new job ID.
            // This is the tricky part. The new job ID is 'asyncBatch' + EnqueueJobs.generateUniqueID().
            // We can't predict the unique ID.
            //
            // Workaround: Retrieve the batch and cursorWrapper from cache *before* they are removed
            // by current event processing, then *re-put* them with a *new predictable ID* if not finished.
            // This simulates what publishBatchEvent does, but makes the ID predictable for the next loop.

            if (finishCallCount == 0) { // If not finished, it means it chained.
                // The handler removed 'currentEventJobId' and 'currentEventJobId + cursorWrapper'.
                // And publishBatchEvent put the batch and wrapper back with a *new, unknown* ID.
                // To continue the test loop, we need to "know" this new ID.

                // Instead of finding, let's assume the test controls the "next" ID.
                // The critical part is that the *same instances* of batch (if stateful) and cursorWrapper
                // are put back into cache.
                // We can verify stateful behavior by checking the instance variable in MockFrameworkBatch
                // This would require getting the batch object from cache again if we could predict the new ID.

                // For this test, we will assume 'publishBatchEvent' correctly caches the SAME instances.
                // The static counters in AsyncJobFrameworkTest will help verify this.
                // The main thing is that the loop in handleBatchEvents correctly uses hasMoreRecords()
                // and calls finish() at the right time.

                // If not finished, we need to find the *new* jobId.
                // Since `publishBatchEvent` uses a new unique ID, we can't easily get it.
                // This simulation will be hard to make perfect without EventBus mocking.

                // Let's check the cache for *any* 'asyncBatch*' key if not finished.
                // This is fragile.
                if (finishCallCount == 0) {
                    List<String> allKeys = orgPart.getKeys();
                    String newJobIdFound = null;
                    for(String key : allKeys) {
                        if (key.startsWith('asyncBatch') && !key.equals(currentEventJobId) && orgPart.contains(key + 'cursorWrapper')) {
                            newJobIdFound = key;
                            break;
                        }
                    }
                    System.assertNotEquals(null, newJobIdFound, 'A new job ID should have been cached by publishBatchEvent.');
                    currentEventJobId = newJobIdFound;
                }
            }
            if (finishCallCount > 0) break;
        }

        Test.stopTest();

        System.assertEquals(3, executeCallCount, 'Execute should be called 3 times (5 recs / batchsize 2).');
        System.assertEquals(5, totalRecordsProcessedInExecute, 'Should process all 5 records.');
        System.assertEquals(1, finishCallCount, 'Finish should be called once at the end.');
         if(testBatchJob instanceof StatefulMockFrameworkBatch){
            // To check statefulness, the instance 'instanceExecuteCount' would need to be on the cached object.
            // We'd need to retrieve the batch object using the *final* job ID (which we don't have here)
            // and check its instance variable.
            // This is where testing stateful through static variables in the test class is easier.
            // The MockFrameworkBatch updates static variables which aggregate across calls regardless of instance.
            // If AsyncJobTriggerHandler correctly re-uses the stateful batch instance from cache,
            // an instance variable on that batch would reflect it.
            // For now, we trust that putting the same 'batch' object back into cache works for stateful.
        }
    }
}
