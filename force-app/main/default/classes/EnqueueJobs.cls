/**
 * The EnqueueJobs class is responsible for enqueuing asynchronous jobs, either Queueable or Batch.
 * Provides methods to submit Queue and Batch jobs to the custom async framework.
 */
public with sharing class EnqueueJobs {
    private static final String CACHE_PARTITION_NAME = 'local.QueueCache';

    /**
     * Enqueue a single Queue job
     * @param queue The Queue job to enqueue
     * @return The unique job ID for tracking
     * @throws AsyncException if queue is null or cache operation fails
     */
    public static String Enqueue(Async.Queue queue) {
        if (queue == null) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Queue cannot be null');
        }
        return Enqueue(new List<Async.Queue>{queue})[0];
    }

    /**
     * Enqueue multiple Queue jobs
     * @param queues List of Queue jobs to enqueue
     * @return List of unique job IDs for tracking
     * @throws AsyncException if queues is null/empty or cache operation fails
     */
    public static List<String> Enqueue(List<Async.Queue> queues) {
        if (queues == null || queues.isEmpty()) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Queues list cannot be null or empty');
        }
        
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
        List<AsyncJobEvent__e> events = new List<AsyncJobEvent__e>();
        List<String> jobIds = new List<String>();
        
        for (Async.Queue queue : queues) {
            if (queue == null) {
                AsyncLogger.logWarning(null, 'Enqueue', 'Skipping null queue in batch enqueue');
                continue;
            }
            
            String queueID = 'async' + generateUniqueID();
            
            try {
                orgPart.put(queueID, queue);
                AsyncLogger.logInfo(queueID, 'Enqueue', 'Queue job cached successfully');
            } catch (Exception ex) {
                AsyncLogger.logError(queueID, 'Enqueue', 'Failed to cache queue job', ex);
                throw new AsyncException(AsyncException.ErrorType.CACHE_ERROR, 'Failed to cache queue job: ' + ex.getMessage(), queueID);
            }

            AsyncJobEvent__e event = new AsyncJobEvent__e();
            event.QueueId__c = queueID;
            event.Context__c = 'Queueable';
            events.add(event);
            jobIds.add(queueID);
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
            AsyncLogger.logInfo(null, 'Enqueue', 'Published ' + events.size() + ' queue job events');
        }
        
        return jobIds;
    }

    /**
     * Enqueue multiple Batch jobs with specified batch size
     * @param Batches List of Batch jobs to enqueue
     * @param batchSize Number of records to process in each batch
     * @return List of unique job IDs for tracking
     * @throws AsyncException if batches is null/empty, batchSize is invalid, or operations fail
     */
    public static List<String> Batch(List<Async.Batch> Batches, Integer batchSize) {
        if (Batches == null || Batches.isEmpty()) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Batches list cannot be null or empty');
        }
        if (batchSize == null || batchSize <= 0 || batchSize > 2000) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Batch size must be between 1 and 2000');
        }
        
        Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
        List<AsyncJobEvent__e> events = new List<AsyncJobEvent__e>();
        List<String> jobIds = new List<String>();
        
        for (Async.Batch batch : Batches) {
            if (batch == null) {
                AsyncLogger.logWarning(null, 'Batch', 'Skipping null batch in batch enqueue');
                continue;
            }
            
            String batchID = 'asyncBatch' + generateUniqueID();
            
            try {
                String soqlQuery = batch.start();
                
                if (String.isBlank(soqlQuery)) {
                    AsyncLogger.logWarning(batchID, 'Batch', 'Batch start() returned empty query, skipping');
                    continue;
                }
                
                CursorWrapper cursorWrapper = new CursorWrapper(soqlQuery);

                orgPart.put(batchID, batch);
                orgPart.put(batchID + 'cursorWrapper', cursorWrapper);
                AsyncLogger.logInfo(batchID, 'Batch', 'Batch job and cursor cached successfully');
            } catch (Exception ex) {
                AsyncLogger.logError(batchID, 'Batch', 'Failed to cache batch job or create cursor', ex);
                throw new AsyncException(AsyncException.ErrorType.CACHE_ERROR, 'Failed to cache batch job: ' + ex.getMessage(), batchID);
            }

            AsyncJobEvent__e event = new AsyncJobEvent__e();
            event.QueueId__c = batchID;
            event.Context__c = 'Batch';
            event.BatchSize__c = batchSize;
            events.add(event);
            jobIds.add(batchID);
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
            AsyncLogger.logInfo(null, 'Batch', 'Published ' + events.size() + ' batch job events');
        }
        
        return jobIds;
    }
    
    /**
     * Enqueue multiple Batch jobs with default batch size of 200
     */
    public static List<String> Batch(List<Async.Batch> Batches) {
        return Batch(Batches, 200);
    }
    
    /**
     * Enqueue a single Batch job with default batch size of 200
     */
    public static String Batch(Async.Batch Batch) {
        if (Batch == null) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Batch cannot be null');
        }
        return Batch(new List<Async.Batch>{Batch}, 200)[0];
    }
    
    /**
     * Enqueue a single Batch job with specified batch size
     */
    public static String Batch(Async.Batch Batch, Integer batchSize) {
        if (Batch == null) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Batch cannot be null');
        }
        return Batch(new List<Async.Batch>{Batch}, batchSize)[0];
    }

    /**
     * Generate a unique ID for job tracking
     * @return A unique hexadecimal string
     */
    public static String generateUniqueID() {
        Blob randomBytes = Crypto.GenerateAESKey(128);
        String hex = EncodingUtil.ConvertToHex(randomBytes);
        return hex;
    }
}