/**
 * Utility class for monitoring and managing async jobs
 * Provides methods to check job status and cache contents
 */
public class AsyncJobUtils {
    private static final String CACHE_PARTITION_NAME = 'local.QueueCache';
    
    /**
     * Check if a job exists in cache
     * @param jobId The job ID to check
     * @return true if the job exists in cache, false otherwise
     */
    public static Boolean jobExists(String jobId) {
        if (String.isBlank(jobId)) {
            return false;
        }
        
        try {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
            return orgPart.contains(jobId);
        } catch (Exception ex) {
            AsyncLogger.logError(jobId, 'JobUtils', 'Error checking job existence', ex);
            return false;
        }
    }
    
    /**
     * Get information about a job if it exists in cache
     * @param jobId The job ID to query
     * @return Map with job information or null if not found
     */
    public static Map<String, Object> getJobInfo(String jobId) {
        if (String.isBlank(jobId)) {
            return null;
        }
        
        try {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
            Map<String, Object> jobInfo = new Map<String, Object>();
            
            jobInfo.put('jobId', jobId);
            jobInfo.put('exists', orgPart.contains(jobId));
            
            if (jobId.startsWith('asyncBatch')) {
                jobInfo.put('type', 'Batch');
                jobInfo.put('hasCursorWrapper', orgPart.contains(jobId + 'cursorWrapper'));
                
                if (orgPart.contains(jobId + 'cursorWrapper')) {
                    CursorWrapper wrapper = (CursorWrapper)orgPart.get(jobId + 'cursorWrapper');
                    jobInfo.put('totalRecords', wrapper.getTotalRecords());
                    jobInfo.put('currentPosition', wrapper.getCurrentPosition());
                    jobInfo.put('hasMoreRecords', wrapper.hasMoreRecords());
                }
            } else if (jobId.startsWith('async')) {
                jobInfo.put('type', 'Queue');
            }
            
            return jobInfo;
        } catch (Exception ex) {
            AsyncLogger.logError(jobId, 'JobUtils', 'Error getting job info', ex);
            return null;
        }
    }
    
    /**
     * Cancel a pending job by removing it from cache
     * Note: This only works if the job hasn't been picked up by the event handler yet
     * @param jobId The job ID to cancel
     * @return true if successfully cancelled, false otherwise
     */
    public static Boolean cancelJob(String jobId) {
        if (String.isBlank(jobId)) {
            return false;
        }
        
        try {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
            
            if (!orgPart.contains(jobId)) {
                AsyncLogger.logWarning(jobId, 'JobUtils', 'Job not found in cache, may have already completed');
                return false;
            }
            
            // Remove job from cache
            orgPart.remove(jobId);
            
            // If it's a batch job, also remove cursor wrapper
            if (jobId.startsWith('asyncBatch') && orgPart.contains(jobId + 'cursorWrapper')) {
                orgPart.remove(jobId + 'cursorWrapper');
            }
            
            AsyncLogger.logInfo(jobId, 'JobUtils', 'Job cancelled successfully');
            return true;
        } catch (Exception ex) {
            AsyncLogger.logError(jobId, 'JobUtils', 'Error cancelling job', ex);
            return false;
        }
    }
    
    /**
     * Get a list of all active job IDs in cache
     * @return List of job IDs currently in cache
     */
    public static List<String> getActiveJobIds() {
        try {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
            List<String> allKeys = orgPart.getKeys();
            List<String> jobIds = new List<String>();
            
            for (String key : allKeys) {
                // Filter out cursorWrapper keys
                if (!key.endsWith('cursorWrapper')) {
                    jobIds.add(key);
                }
            }
            
            return jobIds;
        } catch (Exception ex) {
            AsyncLogger.logError(null, 'JobUtils', 'Error getting active job IDs', ex);
            return new List<String>();
        }
    }
    
    /**
     * Get count of active jobs in cache
     * @return Number of active jobs
     */
    public static Integer getActiveJobCount() {
        return getActiveJobIds().size();
    }
}
