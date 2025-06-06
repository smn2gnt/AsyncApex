/**
 * Handles Queue and Batch events
 **/
public class AsyncJobTriggerHandler {
    private static final String CACHE_PARTITION_NAME = 'local.QueueCache'; // Define constant

    // ... handleQueueEvents (ensure it also uses CACHE_PARTITION_NAME if modified in future) ...
    public static void handleQueueEvents(List<AsyncJobEvent__e> newEvents) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME); // Use constant

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
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME); // Use constant
        for (AsyncJobEvent__e event : newEvents) {
            // ... (check if queueId is in orgPart before getting)
            if (!(event.Context__c == 'Batch' && orgPart.contains(event.QueueId__c) && orgPart.contains(event.QueueId__c + 'cursorWrapper'))) {
                System.debug('AsyncJobTriggerHandler: Batch event ' + event.QueueId__c + ' not found in cache or cursorWrapper missing.');
                continue;
            }
            Async.Batch batch = (Async.Batch)orgPart.get(event.QueueId__c);
            // MODIFIED: Retrieve CursorWrapper instead of Iterator
            CursorWrapper cursorWrapper = (CursorWrapper)orgPart.get(event.QueueId__c + 'cursorWrapper');

            Integer batchSize = (Integer)event.BatchSize__c;
    
            try {
                // MODIFIED: Fetch chunk using CursorWrapper
                List<SObject> scope = cursorWrapper.fetchNextChunk(batchSize);

                processScope(batch, scope); // processScope remains largely the same internally

                // MODIFIED: Check continuation and publish next event
                if (cursorWrapper.hasMoreRecords()) {
                    publishBatchEvent(batch, cursorWrapper, batchSize); // Pass CursorWrapper
                } else {
                    batch.finish();
                }

                orgPart.remove(event.QueueId__c);
                orgPart.remove(event.QueueId__c + 'cursorWrapper'); // MODIFIED: Remove CursorWrapper from cache
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

    // MODIFIED: Parameter type changed to CursorWrapper
    private static void publishBatchEvent(Async.Batch batch, CursorWrapper cursorWrapper, Integer batchSize) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME); // Get partition
        String batchID = 'asyncBatch' + EnqueueJobs.generateUniqueID();
        AsyncJobEvent__e batchEvent = new AsyncJobEvent__e();
        batchEvent.Context__c = 'Batch';
        batchEvent.BatchSize__c = batchSize;
        batchEvent.QueueId__c = batchID;

        // Cache.Org.put(batchID, batch); // OLD
        // Cache.Org.put(batchID + 'cursorWrapper', cursorWrapper); // OLD
        orgPart.put(batchID, batch); // MODIFIED: Use specific partition
        orgPart.put(batchID + 'cursorWrapper', cursorWrapper); // MODIFIED: Use specific partition

        EventBus.publish(batchEvent);
    }
}