/* The EnqueueJobs class is responsible for enqueuing asynchronous jobs, either Queueable or Batch.*/
public with sharing class EnqueueJobs {
    public static String Enqueue(Async.Queue queue) {
        return Enqueue(new List<Async.Queue>{queue})[0];
    }
    public static List<String> Enqueue(List<Async.Queue> queues) {
        List<AsyncJobEvent__e> events = new List<AsyncJobEvent__e>();
        List<String> jobIds = new List<String>();
        for (Async.Queue queue : queues) {
            String queueID = 'async'+generateUniqueID();
            Cache.Org.put(queueID, queue);
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
        List<AsyncJobEvent__e> events = new List<AsyncJobEvent__e>();
        List<String> jobIds = new List<String>();
        for (Async.Batch batch : Batches) {
            Iterable<sObject> iterable = batch.start();
            Iterator<sObject> iterator = iterable.iterator();
            //iterator.next();
            String batchID = 'asyncBatch'+generateUniqueID();
            Cache.Org.put(batchID, batch);
            Cache.Org.put(batchID+'iterator', iterator);
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