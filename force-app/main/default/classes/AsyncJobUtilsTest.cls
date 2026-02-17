@isTest
private class AsyncJobUtilsTest {
    @TestSetup
    static void setupData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'TestAccount' + i));
        }
        insert accounts;
    }
    
    @isTest
    static void testJobExists() {
        TestQueue queue = new TestQueue();
        
        Test.startTest();
        String jobId = EnqueueJobs.Enqueue(queue);
        
        // Job should exist right after enqueue
        Boolean exists = AsyncJobUtils.jobExists(jobId);
        Test.stopTest();
        
        System.assertEquals(true, exists, 'Job should exist in cache after enqueue');
    }
    
    @isTest
    static void testJobExistsBlankId() {
        Test.startTest();
        Boolean exists = AsyncJobUtils.jobExists('');
        Test.stopTest();
        
        System.assertEquals(false, exists, 'Blank job ID should return false');
    }
    
    @isTest
    static void testGetJobInfoQueue() {
        TestQueue queue = new TestQueue();
        
        Test.startTest();
        String jobId = EnqueueJobs.Enqueue(queue);
        Map<String, Object> jobInfo = AsyncJobUtils.getJobInfo(jobId);
        Test.stopTest();
        
        System.assertNotEquals(null, jobInfo, 'Job info should not be null');
        System.assertEquals(jobId, jobInfo.get('jobId'));
        System.assertEquals('Queue', jobInfo.get('type'));
        System.assertEquals(true, jobInfo.get('exists'));
    }
    
    @isTest
    static void testGetJobInfoBatch() {
        TestBatch batch = new TestBatch();
        
        Test.startTest();
        String jobId = EnqueueJobs.Batch(batch, 100);
        Map<String, Object> jobInfo = AsyncJobUtils.getJobInfo(jobId);
        Test.stopTest();
        
        System.assertNotEquals(null, jobInfo, 'Job info should not be null');
        System.assertEquals(jobId, jobInfo.get('jobId'));
        System.assertEquals('Batch', jobInfo.get('type'));
        System.assertEquals(true, jobInfo.get('exists'));
        System.assertEquals(true, jobInfo.get('hasCursorWrapper'));
    }
    
    @isTest
    static void testCancelJob() {
        TestQueue queue = new TestQueue();
        
        Test.startTest();
        String jobId = EnqueueJobs.Enqueue(queue);
        
        // Verify job exists
        System.assertEquals(true, AsyncJobUtils.jobExists(jobId), 'Job should exist before cancel');
        
        // Cancel job
        Boolean cancelled = AsyncJobUtils.cancelJob(jobId);
        
        // Verify job was cancelled
        System.assertEquals(true, cancelled, 'Cancel should return true');
        System.assertEquals(false, AsyncJobUtils.jobExists(jobId), 'Job should not exist after cancel');
        Test.stopTest();
    }
    
    @isTest
    static void testCancelBatchJob() {
        TestBatch batch = new TestBatch();
        
        Test.startTest();
        String jobId = EnqueueJobs.Batch(batch, 100);
        
        // Verify job and cursor wrapper exist
        System.assertEquals(true, AsyncJobUtils.jobExists(jobId), 'Job should exist before cancel');
        
        // Cancel job
        Boolean cancelled = AsyncJobUtils.cancelJob(jobId);
        
        // Verify both job and cursor wrapper were removed
        System.assertEquals(true, cancelled, 'Cancel should return true');
        System.assertEquals(false, AsyncJobUtils.jobExists(jobId), 'Job should not exist after cancel');
        
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.QueueCache');
        System.assertEquals(false, orgPart.contains(jobId + 'cursorWrapper'), 'Cursor wrapper should be removed');
        Test.stopTest();
    }
    
    @isTest
    static void testGetActiveJobIds() {
        TestQueue queue1 = new TestQueue();
        TestQueue queue2 = new TestQueue();
        
        Test.startTest();
        String jobId1 = EnqueueJobs.Enqueue(queue1);
        String jobId2 = EnqueueJobs.Enqueue(queue2);
        
        List<String> activeJobs = AsyncJobUtils.getActiveJobIds();
        Test.stopTest();
        
        System.assert(activeJobs.size() >= 2, 'Should have at least 2 active jobs');
        System.assert(activeJobs.contains(jobId1), 'Should contain first job');
        System.assert(activeJobs.contains(jobId2), 'Should contain second job');
    }
    
    @isTest
    static void testGetActiveJobCount() {
        Test.startTest();
        Integer initialCount = AsyncJobUtils.getActiveJobCount();
        
        TestQueue queue = new TestQueue();
        EnqueueJobs.Enqueue(queue);
        
        Integer newCount = AsyncJobUtils.getActiveJobCount();
        Test.stopTest();
        
        System.assertEquals(initialCount + 1, newCount, 'Job count should increase by 1');
    }
    
    // Helper classes
    private class TestQueue implements Async.Queue {
        public void execute() {
            System.debug('TestQueue executed');
        }
    }
    
    private class TestBatch implements Async.Batch {
        public String start() {
            return 'SELECT Id, Name FROM Account WHERE Name LIKE \'TestAccount%\'';
        }
        
        public void execute(List<SObject> scope) {
            System.debug('TestBatch executed with ' + scope.size() + ' records');
        }
        
        public void finish() {
            System.debug('TestBatch finished');
        }
    }
}
