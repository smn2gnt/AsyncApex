@isTest
private class EnqueueJobsErrorTest {
    /**
     * Test that null queue throws exception
     */
    @isTest
    static void testEnqueueNullQueue() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            EnqueueJobs.Enqueue((Async.Queue)null);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
            System.assert(ex.getMessage().contains('cannot be null'), 'Should mention null in message');
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AsyncException for null queue');
    }
    
    /**
     * Test that null batch throws exception
     */
    @isTest
    static void testBatchNullBatch() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            EnqueueJobs.Batch((Async.Batch)null);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AsyncException for null batch');
    }
    
    /**
     * Test that empty queue list throws exception
     */
    @isTest
    static void testEnqueueEmptyList() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            EnqueueJobs.Enqueue(new List<Async.Queue>());
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AsyncException for empty list');
    }
    
    /**
     * Test that invalid batch size throws exception - zero
     */
    @isTest
    static void testBatchInvalidSizeZero() {
        Async.Batch testBatch = new TestBatch();
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            EnqueueJobs.Batch(testBatch, 0);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
            System.assert(ex.getMessage().contains('Batch size'), 'Should mention batch size in message');
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AsyncException for zero batch size');
    }
    
    /**
     * Test that invalid batch size throws exception - negative
     */
    @isTest
    static void testBatchInvalidSizeNegative() {
        Async.Batch testBatch = new TestBatch();
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            EnqueueJobs.Batch(testBatch, -10);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AsyncException for negative batch size');
    }
    
    /**
     * Test that invalid batch size throws exception - too large
     */
    @isTest
    static void testBatchInvalidSizeTooLarge() {
        Async.Batch testBatch = new TestBatch();
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            EnqueueJobs.Batch(testBatch, 2001);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw AsyncException for batch size over 2000');
    }
    
    /**
     * Test batch list with null items
     */
    @isTest
    static void testBatchListWithNulls() {
        List<Async.Batch> batches = new List<Async.Batch>{
            new TestBatch(),
            null,
            new TestBatch()
        };
        
        Test.startTest();
        List<String> jobIds = EnqueueJobs.Batch(batches, 100);
        Test.stopTest();
        
        // Should skip null items and only enqueue valid batches
        System.assertEquals(2, jobIds.size(), 'Should only enqueue non-null batches');
    }
    
    /**
     * Test queue list with null items
     */
    @isTest
    static void testQueueListWithNulls() {
        List<Async.Queue> queues = new List<Async.Queue>{
            new TestQueue(),
            null,
            new TestQueue()
        };
        
        Test.startTest();
        List<String> jobIds = EnqueueJobs.Enqueue(queues);
        Test.stopTest();
        
        // Should skip null items and only enqueue valid queues
        System.assertEquals(2, jobIds.size(), 'Should only enqueue non-null queues');
    }
    
    // Helper classes
    private class TestBatch implements Async.Batch {
        public String start() {
            return 'SELECT Id FROM Account LIMIT 1';
        }
        
        public void execute(List<SObject> scope) {
            // Test implementation
        }
        
        public void finish() {
            // Test implementation
        }
    }
    
    private class TestQueue implements Async.Queue {
        public void execute() {
            // Test implementation
        }
    }
}
