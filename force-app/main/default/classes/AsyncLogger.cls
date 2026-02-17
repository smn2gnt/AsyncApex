/**
 * Logging utility for the Async Framework
 * Provides structured logging for monitoring and troubleshooting
 */
public class AsyncLogger {
    public enum LogLevel {
        ERROR,
        WARNING,
        INFO,
        DEBUG
    }
    
    /**
     * Log an error with job context
     */
    public static void logError(String jobId, String context, String message, Exception ex) {
        String logMessage = buildLogMessage(LogLevel.ERROR, jobId, context, message);
        if (ex != null) {
            logMessage += '\nException: ' + ex.getTypeName() + '\nMessage: ' + ex.getMessage() + '\nStack Trace: ' + ex.getStackTraceString();
        }
        System.debug(LoggingLevel.ERROR, logMessage);
    }
    
    /**
     * Log a warning with job context
     */
    public static void logWarning(String jobId, String context, String message) {
        String logMessage = buildLogMessage(LogLevel.WARNING, jobId, context, message);
        System.debug(LoggingLevel.WARN, logMessage);
    }
    
    /**
     * Log info message with job context
     */
    public static void logInfo(String jobId, String context, String message) {
        String logMessage = buildLogMessage(LogLevel.INFO, jobId, context, message);
        System.debug(LoggingLevel.INFO, logMessage);
    }
    
    /**
     * Log debug message with job context
     */
    public static void logDebug(String jobId, String context, String message) {
        String logMessage = buildLogMessage(LogLevel.DEBUG, jobId, context, message);
        System.debug(LoggingLevel.DEBUG, logMessage);
    }
    
    private static String buildLogMessage(LogLevel level, String jobId, String context, String message) {
        String safeJobId = String.isBlank(jobId) ? 'N/A' : jobId;
        String safeContext = String.isBlank(context) ? 'N/A' : context;
        return '[AsyncFramework] [' + level.name() + '] [JobId: ' + safeJobId + '] [Context: ' + safeContext + '] ' + message;
    }
}
