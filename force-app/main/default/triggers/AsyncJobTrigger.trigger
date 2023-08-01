trigger AsyncJobTrigger on AsyncJobEvent__e (after Insert) {
    AsyncJobTriggerHandler.handleQueueEvents(Trigger.new);
    AsyncJobTriggerHandler.handleBatchEvents(Trigger.new);
}