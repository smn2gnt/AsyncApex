@isTest
private class CursorWrapperErrorTest {
    /**
     * Test invalid chunk size - zero
     */
    @isTest
    static void testInvalidChunkSizeZero() {
        String query = 'SELECT Id FROM Account LIMIT 1';
        CursorWrapper wrapper = new CursorWrapper(query);
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            wrapper.fetchNextChunk(0);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
            System.assert(ex.getMessage().contains('greater than 0'), 'Should mention chunk size requirement');
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw exception for zero chunk size');
    }
    
    /**
     * Test invalid chunk size - negative
     */
    @isTest
    static void testInvalidChunkSizeNegative() {
        String query = 'SELECT Id FROM Account LIMIT 1';
        CursorWrapper wrapper = new CursorWrapper(query);
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            wrapper.fetchNextChunk(-5);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.INVALID_CONFIGURATION, ex.getErrorType());
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw exception for negative chunk size');
    }
    
    /**
     * Test that invalid SOQL throws appropriate exception
     */
    @isTest
    static void testInvalidSOQL() {
        String invalidQuery = 'SELECT Invalid FROM NonExistent';
        CursorWrapper wrapper = new CursorWrapper(invalidQuery);
        
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            wrapper.fetchNextChunk(10);
        } catch (AsyncException ex) {
            exceptionThrown = true;
            System.assertEquals(AsyncException.ErrorType.CURSOR_ERROR, ex.getErrorType());
        } catch (Exception ex) {
            // May also throw QueryException from Salesforce
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw exception for invalid SOQL');
    }
}
