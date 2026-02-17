/**
 * Core interfaces for the Async Framework
 * Defines contracts for Queue and Batch jobs with optional state preservation
 */
public with sharing class Async {
    /**
     * Interface for batch processing jobs
     * Implement this interface to create custom batch jobs
     */
    public Interface Batch {
        /**
         * Start method - returns SOQL query for records to process
         * @return SOQL query string
         */
        String start();
        
        /**
         * Execute method - processes a batch of records
         * @param scope List of SObjects to process in this batch
         */
        void execute(List<SObject> scope);
        
        /**
         * Finish method - called after all batches are processed
         * Use for cleanup, sending notifications, etc.
         */
        void finish();
    }
    
    /**
     * Interface for queue (single execution) jobs
     * Implement this interface to create custom queue jobs
     */
    public Interface Queue {
        /**
         * Execute method - performs the async operation
         */
        void execute();
    }
    
    /**
     * Marker interface for stateful batch jobs
     * Implement this along with Batch to preserve state across execute() calls
     * Without this, a new instance is created for each batch chunk
     */
    public Interface Stateful {
        // Marker Interface - no methods required
    }
}