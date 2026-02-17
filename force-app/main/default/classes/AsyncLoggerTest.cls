@isTest
private class AsyncLoggerTest {
    @isTest
    static void testLogError() {
        String jobId = 'testJob123';
        Exception testEx = new AsyncException(AsyncException.ErrorType.CACHE_ERROR, 'Test error');
        
        Test.startTest();
        AsyncLogger.logError(jobId, 'TestContext', 'Error occurred', testEx);
        Test.stopTest();
        
        // Verify no exceptions thrown
        System.assert(true, 'Logger should handle errors gracefully');
    }
    
    @isTest
    static void testLogWarning() {
        String jobId = 'testJob456';
        
        Test.startTest();
        AsyncLogger.logWarning(jobId, 'TestContext', 'Warning message');
        Test.stopTest();
        
        System.assert(true, 'Logger should handle warnings gracefully');
    }
    
    @isTest
    static void testLogInfo() {
        String jobId = 'testJob789';
        
        Test.startTest();
        AsyncLogger.logInfo(jobId, 'TestContext', 'Info message');
        Test.stopTest();
        
        System.assert(true, 'Logger should handle info messages gracefully');
    }
    
    @isTest
    static void testLogDebug() {
        String jobId = 'testJob000';
        
        Test.startTest();
        AsyncLogger.logDebug(jobId, 'TestContext', 'Debug message');
        Test.stopTest();
        
        System.assert(true, 'Logger should handle debug messages gracefully');
    }
    
    @isTest
    static void testLogErrorWithNullException() {
        String jobId = 'testJobNull';
        
        Test.startTest();
        AsyncLogger.logError(jobId, 'TestContext', 'Error without exception', null);
        Test.stopTest();
        
        System.assert(true, 'Logger should handle null exception gracefully');
    }
}
