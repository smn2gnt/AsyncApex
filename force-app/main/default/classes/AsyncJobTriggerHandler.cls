/**
 * Handles Queue and Batch events triggered by Platform Events
 * Processes async jobs with comprehensive error handling and logging
 */
public class AsyncJobTriggerHandler {
    private static final String CACHE_PARTITION_NAME = 'local.QueueCache';

    /**
     * Handle Queue job events
     * @param newEvents List of AsyncJobEvent__e platform events
     */
    public static void handleQueueEvents(List<AsyncJobEvent__e> newEvents) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);

        for (AsyncJobEvent__e event : newEvents) {
            String jobId = event.QueueId__c;
            
            if (event.Context__c != 'Queueable') {
                continue;
            }
            
            if (!orgPart.contains(jobId)) {
                AsyncLogger.logWarning(jobId, 'Queue', 'Job not found in cache, may have already been processed or expired');
                continue;
            }
            
            try {
                Async.Queue queue = (Async.Queue)orgPart.get(jobId);
                AsyncLogger.logInfo(jobId, 'Queue', 'Starting queue job execution');
                
                queue.execute();
                
                orgPart.remove(jobId);
                AsyncLogger.logInfo(jobId, 'Queue', 'Queue job completed successfully');
            } catch (Exception ex) {
                AsyncLogger.logError(jobId, 'Queue', 'Queue job execution failed', ex);
                // Clean up cache on error
                try {
                    orgPart.remove(jobId);
                } catch (Exception cleanupEx) {
                    AsyncLogger.logError(jobId, 'Queue', 'Failed to clean up cache after error', cleanupEx);
                }
            }
        }
    }

    /**
     * Handle Batch job events
     * @param newEvents List of AsyncJobEvent__e platform events
     */
    public static void handleBatchEvents(List<AsyncJobEvent__e> newEvents) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
        
        for (AsyncJobEvent__e event : newEvents) {
            String jobId = event.QueueId__c;
            
            if (event.Context__c != 'Batch') {
                continue;
            }
            
            if (!orgPart.contains(jobId)) {
                AsyncLogger.logWarning(jobId, 'Batch', 'Batch job not found in cache');
                continue;
            }
            
            if (!orgPart.contains(jobId + 'cursorWrapper')) {
                AsyncLogger.logError(jobId, 'Batch', 'CursorWrapper not found in cache, cannot process batch', null);
                // Clean up orphaned batch object
                try {
                    orgPart.remove(jobId);
                } catch (Exception cleanupEx) {
                    AsyncLogger.logError(jobId, 'Batch', 'Failed to clean up orphaned batch', cleanupEx);
                }
                continue;
            }
            
            try {
                Async.Batch batch = (Async.Batch)orgPart.get(jobId);
                CursorWrapper cursorWrapper = (CursorWrapper)orgPart.get(jobId + 'cursorWrapper');
                Integer batchSize = (Integer)event.BatchSize__c;
                
                AsyncLogger.logInfo(jobId, 'Batch', 'Processing batch chunk with size: ' + batchSize);
                
                List<SObject> scope = cursorWrapper.fetchNextChunk(batchSize);
                
                if (!scope.isEmpty()) {
                    processScope(batch, scope, jobId);
                    AsyncLogger.logInfo(jobId, 'Batch', 'Processed ' + scope.size() + ' records');
                }
                
                if (cursorWrapper.hasMoreRecords()) {
                    AsyncLogger.logInfo(jobId, 'Batch', 'More records to process, publishing next batch event');
                    publishBatchEvent(batch, cursorWrapper, batchSize);
                } else {
                    AsyncLogger.logInfo(jobId, 'Batch', 'All records processed, calling finish');
                    batch.finish();
                    AsyncLogger.logInfo(jobId, 'Batch', 'Batch job completed successfully');
                }
                
                // Clean up current cache entries
                orgPart.remove(jobId);
                orgPart.remove(jobId + 'cursorWrapper');
            } catch (Exception ex) {
                AsyncLogger.logError(jobId, 'Batch', 'Batch job execution failed', ex);
                // Clean up cache on error
                try {
                    orgPart.remove(jobId);
                    orgPart.remove(jobId + 'cursorWrapper');
                } catch (Exception cleanupEx) {
                    AsyncLogger.logError(jobId, 'Batch', 'Failed to clean up cache after error', cleanupEx);
                }
            }
        }
    }

    /**
     * Process a scope of records for a batch job
     * Handles both stateful and non-stateful batch instances
     */
    private static void processScope(Async.Batch batch, List<SObject> scope, String jobId) {
        if (scope.isEmpty()) {
            AsyncLogger.logDebug(jobId, 'Batch', 'Empty scope, skipping processing');
            return;
        }
        
        // For non-stateful batches, create a new instance
        if (!(batch instanceof Async.Stateful)) {
            try {
                batch = (Async.Batch)Type.forName(String.valueOf(batch).split(':')[0]).newInstance();
            } catch (Exception ex) {
                AsyncLogger.logError(jobId, 'Batch', 'Failed to instantiate non-stateful batch', ex);
                throw new AsyncException(AsyncException.ErrorType.BATCH_EXECUTION_ERROR, 'Failed to create batch instance: ' + ex.getMessage(), jobId);
            }
        }
        
        batch.execute(scope);
    }

    /**
     * Publish the next batch event for continued processing
     * Creates new cache entries with a new job ID
     */
    private static void publishBatchEvent(Async.Batch batch, CursorWrapper cursorWrapper, Integer batchSize) {
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
        String batchID = 'asyncBatch' + EnqueueJobs.generateUniqueID();
        
        try {
            orgPart.put(batchID, batch);
            orgPart.put(batchID + 'cursorWrapper', cursorWrapper);
            AsyncLogger.logDebug(batchID, 'Batch', 'Cached continuation batch and cursor');
        } catch (Exception ex) {
            AsyncLogger.logError(batchID, 'Batch', 'Failed to cache continuation batch', ex);
            throw new AsyncException(AsyncException.ErrorType.CACHE_ERROR, 'Failed to cache batch continuation: ' + ex.getMessage(), batchID);
        }
        
        AsyncJobEvent__e batchEvent = new AsyncJobEvent__e();
        batchEvent.Context__c = 'Batch';
        batchEvent.BatchSize__c = batchSize;
        batchEvent.QueueId__c = batchID;

        EventBus.publish(batchEvent);
        AsyncLogger.logDebug(batchID, 'Batch', 'Published continuation event');
    }
}