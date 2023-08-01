/**
 * Handles Queue and Batch events
 **/
public class AsyncJobTriggerHandler {
    public static void handleQueueEvents(List<AsyncJobEvent__e> newEvents) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.QueueCache');

        for (AsyncJobEvent__e event : newEvents) {
            if (!(event.Context__c == 'Queueable' && orgPart.contains(event.QueueId__c))) {
                continue;
            }
            Async.Queue queue = (Async.Queue)orgPart.get(event.QueueId__c);
            System.debug(JSON.serialize(queue));
            try {
                queue.execute();
                orgPart.remove(event.QueueId__c);
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
        }
    }

    public static void handleBatchEvents(List<AsyncJobEvent__e> newEvents) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.QueueCache');
        for (AsyncJobEvent__e event : newEvents) {
            if (!(event.Context__c == 'Batch' && orgPart.contains(event.QueueId__c))) {
                continue;
            }
            Async.Batch batch = (Async.Batch)orgPart.get(event.QueueId__c);
            Iterator<sObject> iterator = (Iterator<sObject>)orgPart.get(event.QueueId__c+'iterator');
            Integer batchSize = (Integer)event.BatchSize__c;
    
            try {
                List<Sobject> scope = new List<Sobject>();
                while (iterator.hasNext() && scope.size() < batchSize) {
                    scope.add(iterator.next()); 
                }
                processScope(batch, scope);
                if(iterator.hasNext())
                    publishBatchEvent(batch, iterator, batchSize);
                else 
                    batch.finish();
                orgPart.remove(event.QueueId__c);
                orgPart.remove(event.QueueId__c+'iterator');
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
        }
    }

    private static void processScope(Async.Batch batch, List<SObject> scope) {
        if(scope.isEmpty())
            return;
        if (!(batch instanceof Async.Stateful)) {
            batch = (Async.Batch)Type.forName(String.valueOf(batch).split(':')[0]).newInstance(); 
        }
        batch.execute(scope);
    }

    private static void publishBatchEvent(Async.Batch batch, Iterator<sObject> iterator, Integer batchSize) {
        String batchID = 'asyncBatch' + EnqueueJobs.generateUniqueID();
        AsyncJobEvent__e batchEvent = new AsyncJobEvent__e();
        batchEvent.Context__c = 'Batch';
        batchEvent.BatchSize__c = batchSize;
        batchEvent.QueueId__c = batchID;

        Cache.Org.put(batchID, batch);
        Cache.Org.put(batchID + 'iterator', iterator);

        EventBus.publish(batchEvent);
    }
}