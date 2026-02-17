@isTest
private class AsyncExceptionTest {
    @isTest
    static void testExceptionWithErrorType() {
        Test.startTest();
        AsyncException ex = new AsyncException(
            AsyncException.ErrorType.CACHE_ERROR,
            'Test cache error'
        );
        Test.stopTest();
        
        System.assertEquals(AsyncException.ErrorType.CACHE_ERROR, ex.getErrorType());
        System.assertEquals('Test cache error', ex.getMessage());
    }
    
    @isTest
    static void testExceptionWithJobId() {
        String testJobId = 'test123';
        
        Test.startTest();
        AsyncException ex = new AsyncException(
            AsyncException.ErrorType.BATCH_EXECUTION_ERROR,
            'Test batch error',
            testJobId
        );
        Test.stopTest();
        
        System.assertEquals(AsyncException.ErrorType.BATCH_EXECUTION_ERROR, ex.getErrorType());
        System.assertEquals('Test batch error', ex.getMessage());
        System.assertEquals(testJobId, ex.getJobId());
    }
    
    @isTest
    static void testAllErrorTypes() {
        // Test that all error types can be used
        List<AsyncException.ErrorType> errorTypes = new List<AsyncException.ErrorType>{
            AsyncException.ErrorType.CACHE_ERROR,
            AsyncException.ErrorType.BATCH_EXECUTION_ERROR,
            AsyncException.ErrorType.QUEUE_EXECUTION_ERROR,
            AsyncException.ErrorType.INVALID_CONFIGURATION,
            AsyncException.ErrorType.CURSOR_ERROR
        };
        
        Test.startTest();
        for (AsyncException.ErrorType errorType : errorTypes) {
            AsyncException ex = new AsyncException(errorType, 'Test message');
            System.assertEquals(errorType, ex.getErrorType());
        }
        Test.stopTest();
    }
}
