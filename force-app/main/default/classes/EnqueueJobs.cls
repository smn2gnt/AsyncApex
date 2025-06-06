/* The EnqueueJobs class is responsible for enqueuing asynchronous jobs, either Queueable or Batch.*/
public with sharing class EnqueueJobs {
    private static final String CACHE_PARTITION_NAME = 'local.QueueCache'; // Define constant

    public static String Enqueue(Async.Queue queue) {
        return Enqueue(new List<Async.Queue>{queue})[0];
    }

    public static List<String> Enqueue(List<Async.Queue> queues) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME); // Get partition
        List<AsyncJobEvent__e> events = new List<AsyncJobEvent__e>();
        List<String> jobIds = new List<String>();
        for (Async.Queue queue : queues) {
            String queueID = 'async' + generateUniqueID();
            // Cache.Org.put(queueID, queue); // OLD
            orgPart.put(queueID, queue); // MODIFIED: Use specific partition

            AsyncJobEvent__e event = new AsyncJobEvent__e();
            event.QueueId__c = queueID;
            event.Context__c = 'Queueable';
            events.add(event);
            jobIds.add(queueID);
        }

        EventBus.publish(events);
        return jobIds;
    }

    public static List<String> Batch(List<Async.Batch> Batches, Integer batchSize) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME); // Get partition
        List<AsyncJobEvent__e> events = new List<AsyncJobEvent__e>();
        List<String> jobIds = new List<String>();
        for (Async.Batch batch : Batches) {
            String soqlQuery = batch.start();
            String batchID = 'asyncBatch' + generateUniqueID();

            CursorWrapper cursorWrapper = new CursorWrapper(soqlQuery);

            // Cache.Org.put(batchID, batch); // OLD
            // Cache.Org.put(batchID + 'cursorWrapper', cursorWrapper); // OLD
            orgPart.put(batchID, batch); // MODIFIED: Use specific partition
            orgPart.put(batchID + 'cursorWrapper', cursorWrapper); // MODIFIED: Use specific partition

            AsyncJobEvent__e event = new AsyncJobEvent__e();
            event.QueueId__c = batchID;
            event.Context__c = 'Batch';
            event.BatchSize__c = batchSize;
            events.add(event);
            jobIds.add(batchID);
        }

        EventBus.publish(events);
        return jobIds;
    }
    public static List<String> Batch(List<Async.Batch> Batches) {
        return Batch(Batches, 200);
    }
    public static String Batch(Async.Batch Batch) {
        return Batch(new List<Async.Batch>{Batch}, 200)[0];
    }
    public static String Batch(Async.Batch Batch, Integer batchSize) {
        return Batch(new List<Async.Batch>{Batch}, batchSize)[0];
    }

    public static String generateUniqueID() {
        Blob randomBytes = Crypto.GenerateAESKey(128);
        String hex = EncodingUtil.ConvertToHex(randomBytes);
        return hex;
    }
}