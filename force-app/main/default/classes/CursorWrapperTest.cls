@isTest
private class CursorWrapperTest {

    @TestSetup
    static void makeData(){
        List<Account> accs = new List<Account>();
        for(Integer i = 0; i < 7; i++){ // Create 7 records for testing various chunk sizes
            accs.add(new Account(Name = 'CW_TestAcc' + i, AnnualRevenue = i * 1000.0));
        }
        insert accs;
    }

    @isTest
    static void testInitializationAndTotalRecords() {
        String query = 'SELECT Id, Name FROM Account WHERE Name LIKE \'CW_TestAcc%\'';
        CursorWrapper wrapper = new CursorWrapper(query);

        System.assertEquals(query, wrapper.getQuery(), 'Query should be stored.');
        System.assertEquals(0, wrapper.getCurrentPosition(), 'Initial position should be 0.');
        System.assertEquals(false, wrapper.getIsInitialized(), 'Should not be initialized before first fetch/check.');

        Test.startTest();
        Integer total = wrapper.getTotalRecords();
        Test.stopTest();

        System.assertEquals(7, total, 'Should return total number of records matching query.');
        System.assertEquals(true, wrapper.getIsInitialized(), 'Should be initialized after getTotalRecords.');
    }

    @isTest
    static void testFetchNextChunk_Basic() {
        String query = 'SELECT Id, Name FROM Account WHERE Name LIKE \'CW_TestAcc%\' ORDER BY Name';
        CursorWrapper wrapper = new CursorWrapper(query);

        Test.startTest();
        List<SObject> chunk1 = wrapper.fetchNextChunk(3);
        Test.stopTest();

        System.assertEquals(3, chunk1.size(), 'Chunk 1 should have 3 records.');
        System.assertEquals(3, wrapper.getCurrentPosition(), 'Position should be 3 after first fetch.');
        System.assertEquals(true, wrapper.hasMoreRecords(), 'Should have more records after first chunk.');

        Test.startTest();
        List<SObject> chunk2 = wrapper.fetchNextChunk(3);
        Test.stopTest();

        System.assertEquals(3, chunk2.size(), 'Chunk 2 should have 3 records.');
        System.assertEquals(6, wrapper.getCurrentPosition(), 'Position should be 6 after second fetch.');
        System.assertEquals(true, wrapper.hasMoreRecords(), 'Should have more records after second chunk.');

        Test.startTest();
        List<SObject> chunk3 = wrapper.fetchNextChunk(3);
        Test.stopTest();

        System.assertEquals(1, chunk3.size(), 'Chunk 3 should have 1 record (remainder).');
        System.assertEquals(7, wrapper.getCurrentPosition(), 'Position should be 7 after third fetch.');
        System.assertEquals(false, wrapper.hasMoreRecords(), 'Should have no more records after third chunk.');

        Test.startTest();
        List<SObject> chunk4 = wrapper.fetchNextChunk(3); // Fetching beyond the end
        Test.stopTest();
        System.assertEquals(0, chunk4.size(), 'Chunk 4 should be empty when fetching beyond total.');
        System.assertEquals(7, wrapper.getCurrentPosition(), 'Position should remain at total.');
    }

    @isTest
    static void testFetchWithNoRecords() {
        String query = 'SELECT Id FROM Account WHERE Name = \'NON_EXISTENT_ACCOUNT\'';
        CursorWrapper wrapper = new CursorWrapper(query);

        Test.startTest();
        System.assertEquals(0, wrapper.getTotalRecords(), 'Total records should be 0.');
        List<SObject> chunk = wrapper.fetchNextChunk(100);
        Test.stopTest();

        System.assertEquals(0, chunk.size(), 'Chunk should be empty.');
        System.assertEquals(false, wrapper.hasMoreRecords(), 'Should have no more records.');
        System.assertEquals(0, wrapper.getCurrentPosition(), 'Position should be 0.');
    }

    @isTest
    static void testBlankQuery() {
        CursorWrapper wrapper = new CursorWrapper(''); // Blank query

        Test.startTest();
        // Initialize by calling a method that triggers it
        System.assertEquals(false, wrapper.hasMoreRecords(), 'Should have no records for blank query.');
        Test.stopTest();

        System.assertEquals(0, wrapper.getTotalRecords(), 'Total records should be 0 for blank query.');
        System.assertEquals(true, wrapper.getIsInitialized(), 'Should be initialized.');

        Test.startTest();
        List<SObject> chunk = wrapper.fetchNextChunk(10);
        Test.stopTest();
        System.assertEquals(0, chunk.size(), 'Chunk should be empty for blank query.');
    }

    @isTest
    static void testNullQuery() {
        CursorWrapper wrapper = new CursorWrapper(null); // Null query

        Test.startTest();
        System.assertEquals(false, wrapper.hasMoreRecords(), 'Should have no records for null query.');
        Test.stopTest();

        System.assertEquals(0, wrapper.getTotalRecords(), 'Total records should be 0 for null query.');
        System.assertEquals(true, wrapper.getIsInitialized(), 'Should be initialized.');

        Test.startTest();
        List<SObject> chunk = wrapper.fetchNextChunk(10);
        Test.stopTest();
        System.assertEquals(0, chunk.size(), 'Chunk should be empty for null query.');
    }

    @isTest
    static void testReinitializationOfTransientCursor() {
        String query = 'SELECT Id, Name FROM Account WHERE Name LIKE \'CW_TestAcc%\' ORDER BY Name LIMIT 3';
        CursorWrapper wrapperOriginal = new CursorWrapper(query);

        // Simulate fetching first chunk
        Test.startTest();
        List<SObject> chunkOriginal = wrapperOriginal.fetchNextChunk(2); // Fetches 2, currentPos=2, total=3 based on LIMIT
        Test.stopTest();

        System.assertEquals(2, chunkOriginal.size());
        System.assertEquals(2, wrapperOriginal.getCurrentPosition());
        System.assertEquals(3, wrapperOriginal.getTotalRecords()); // Total records from query with LIMIT 3
        System.assertEquals(true, wrapperOriginal.hasMoreRecords());

        // Simulate state after deserialization for wrapper2
        CursorWrapper wrapper2_simulatedDeserialized = new CursorWrapper(wrapperOriginal.getQuery());
        // Manually copy state fields (Apex cache would do this for non-transient fields)
        wrapper2_simulatedDeserialized.currentPosition = wrapperOriginal.getCurrentPosition();
        wrapper2_simulatedDeserialized.totalRecords = wrapperOriginal.getTotalRecords();
        wrapper2_simulatedDeserialized.isInitialized = wrapperOriginal.getIsInitialized(); // Should be true

        Test.startTest();
        // When fetchNextChunk is called, initializeCursor will find this.cursor is null (transient)
        // and isInitialized is true, and query is not blank. It should re-acquire the cursor.
        List<SObject> chunk1_w2 = wrapper2_simulatedDeserialized.fetchNextChunk(2); // Should fetch remaining 1 record
        Test.stopTest();

        System.assertEquals(1, chunk1_w2.size(), 'Should fetch the remaining 1 record.');
        System.assertEquals(3, wrapper2_simulatedDeserialized.getCurrentPosition(), 'Position should be 3.');
        System.assertEquals(3, wrapper2_simulatedDeserialized.getTotalRecords(), 'Total records should still be 3.');
        System.assertEquals(false, wrapper2_simulatedDeserialized.hasMoreRecords(), 'No more records.');
    }
}
