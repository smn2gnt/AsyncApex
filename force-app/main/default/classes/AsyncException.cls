/**
 * Custom exception class for the Async Framework
 * Provides better error categorization and handling
 */
public class AsyncException extends Exception {
    public enum ErrorType {
        CACHE_ERROR,
        BATCH_EXECUTION_ERROR,
        QUEUE_EXECUTION_ERROR,
        INVALID_CONFIGURATION,
        CURSOR_ERROR
    }
    
    private ErrorType errorType;
    private String jobId;
    
    public AsyncException(ErrorType errorType, String message) {
        this(message);
        this.errorType = errorType;
    }
    
    public AsyncException(ErrorType errorType, String message, String jobId) {
        this(message);
        this.errorType = errorType;
        this.jobId = jobId;
    }
    
    public ErrorType getErrorType() {
        return this.errorType;
    }
    
    public String getJobId() {
        return this.jobId;
    }
}
