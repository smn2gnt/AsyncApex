@isTest
public class EnqueueJobsTest {
    @TestSetup
    static void setupdata(){
        // Ensure some data exists that the query in TestBatch can find
        List<Account> accs = new List<Account>();
        for(Integer i=0; i < 5; i++){ // Create a few records
            accs.add(new Account(Name = 'TestAcc' + i));
        }
        insert accs;
    }

    @isTest
    static void testEnqueue() {
        Async.Queue testQueue = new TestQueue(); 
        Test.startTest();
        String jobId = EnqueueJobs.Enqueue(testQueue);
        Test.stopTest();
        System.assertEquals(true, String.isNotBlank(jobId));
    }

    @isTest
    static void testBatch() {
        Async.Batch testBatch = new TestBatch(); 
        Test.startTest();
        // Provide a batch size, e.g., 1 or 2, consistent with data
        String jobId = EnqueueJobs.Batch(testBatch, 2);
        Test.stopTest();
        System.assertEquals(true, String.isNotBlank(jobId));
    }

    // MODIFIED TestBatch inner class
    public class TestBatch implements Async.Batch, Async.Stateful {
        // MODIFIED: start() now returns String (SOQL query)
        public String start() {
            return 'SELECT Id, Name FROM Account';
        }
    
        public void execute(List<SObject> scope) {
            // Test logic can be minimal for EnqueueJobsTest,
            // as it's not testing the full execution here.
            System.debug('TestBatch.execute called with scope size: ' + scope.size());
        }
    
        public void finish() {
            System.debug('TestBatch.finish called.');
        }
    }
    
    public class TestQueue implements Async.Queue {
        public void execute() {
            System.debug('TestQueue.execute called.');
        }
    }
}
