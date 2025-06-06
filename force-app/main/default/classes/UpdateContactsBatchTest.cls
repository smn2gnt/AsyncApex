@isTest
private class UpdateContactsBatchTest {

    @TestSetup
    static void makeData() {
        List<Account> accounts = new List<Account>();
        List<Contact> contactsToInsert = new List<Contact>();

        for (Integer i = 0; i < 3; i++) { // Create 3 Accounts
            Account acc = new Account(
                Name = 'BatchTestAcc' + i,
                BillingStreet = '123 Billing St ' + i,
                BillingCity = 'Billing City ' + i,
                BillingState = 'BS ' + i,
                BillingPostalCode = 'BPC' + i,
                BillingCountry = 'BC' + i
            );
            accounts.add(acc);
        }
        insert accounts;

        // Create 2 contacts for each account
        for (Account acc : accounts) {
            for (Integer j = 0; j < 2; j++) {
                contactsToInsert.add(new Contact(
                    AccountId = acc.Id,
                    FirstName = 'ContactFirst' + acc.Name + j,
                    LastName = 'TestLastName' + j,
                    MailingStreet = 'Old Mailing St', // Different from billing
                    MailingCity = 'Old Mailing City',
                    MailingState = 'OMS',
                    MailingPostalCode = 'OMPC',
                    MailingCountry = 'OMC'
                ));
            }
        }
        insert contactsToInsert; // Total 3 * 2 = 6 contacts
    }

    @isTest
    static void testUpdateContactsBatch_EndToEnd() {
        // --- Setup Test ---
        UpdateContactsBatch batchJob = new UpdateContactsBatch();
        // The query in UpdateContactsBatch is on Account.
        // 3 accounts exist.
        Integer accountBatchSize = 1; // Process 3 Accounts in 3 chunks. Each Account has 2 contacts.

        // --- Enqueue the Batch ---
        Test.startTest();
        String initialJobId = EnqueueJobs.Batch(batchJob, accountBatchSize);
        System.assert(String.isNotBlank(initialJobId), 'Initial JobId should not be blank');

        // --- Simulate Event Processing Loop ---
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.QueueCache');
        String currentJobId = initialJobId;
        Integer maxLoops = 5; // Safety break for test (3 accounts chunks + finish logic)

        for (Integer i = 0; i < maxLoops; i++) {
            System.debug('Simulating event loop for UpdateContactsBatch. Iteration: ' + (i + 1) + ', JobId: ' + currentJobId);

            // Ensure items are in cache before processing
            if (!orgPart.contains(currentJobId) || !orgPart.contains(currentJobId + 'cursorWrapper')) {
                System.debug('Cache items missing for JobId: ' + currentJobId + '. Assuming batch finished or error in previous step.');
                break;
            }

            AsyncJobEvent__e currentEvent = new AsyncJobEvent__e(
                QueueId__c = currentJobId,
                Context__c = 'Batch',
                BatchSize__c = accountBatchSize
            );

            // Call the handler
            AsyncJobTriggerHandler.handleBatchEvents(new List<AsyncJobEvent__e>{currentEvent});

            // Try to find the next job ID if not finished
            String nextJobId = null;
            // If currentJobId was removed by the handler (because it chained or finished)
            if (!orgPart.contains(currentJobId)) {
                List<String> allKeys = orgPart.getKeys();
                for (String key : allKeys) {
                    // A chained job will have a new key for the batch and its cursorWrapper
                    if (key.startsWith('asyncBatch') && orgPart.contains(key + 'cursorWrapper') && orgPart.contains(key)) {
                        nextJobId = key;
                        break;
                    }
                }
            } else {
                // This case should ideally not happen if the job is processing,
                // as the handler should remove the processed job's cache entries.
                // If it's still here, it might be an issue or the very last step (finish didn't remove).
                System.debug('Current JobId ' + currentJobId + ' still in cache after handling. This might be unusual.');
            }

            if (nextJobId != null) {
                System.debug('Chaining to next JobId: ' + nextJobId);
                currentJobId = nextJobId;
            } else {
                System.debug('No next JobId found, or current job ID not removed. Assuming batch processing completed or error.');
                break;
            }
        }
        Test.stopTest();

        // --- Assertions ---
        List<Contact> updatedContacts = [
            SELECT Id, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                   Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry
            FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name LIKE 'BatchTestAcc%')
            ORDER BY Account.Name, FirstName
        ];

        System.assertEquals(6, updatedContacts.size(), 'Should have 6 contacts in total.');

        for (Contact c : updatedContacts) {
            System.assertEquals(c.Account.BillingStreet, c.MailingStreet, 'MailingStreet should match Account BillingStreet for Contact ID: ' + c.Id);
            System.assertEquals(c.Account.BillingCity, c.MailingCity, 'MailingCity should match Account BillingCity for Contact ID: ' + c.Id);
            System.assertEquals(c.Account.BillingState, c.MailingState, 'MailingState should match Account BillingState for Contact ID: ' + c.Id);
            System.assertEquals(c.Account.BillingPostalCode, c.MailingPostalCode, 'MailingPostalCode should match Account BillingPostalCode for Contact ID: ' + c.Id);
            System.assertEquals(c.Account.BillingCountry, c.MailingCountry, 'MailingCountry should match Account BillingCountry for Contact ID: ' + c.Id);
        }

        // Verifying 'recordsProcessed' from UpdateContactsBatch.cls
        // The batch instance is stateful. After the last chunk, AsyncJobTriggerHandler calls batch.finish().
        // The batch object instance associated with the *last processed job ID* (before finish was called and it was removed)
        // would have the final recordsProcessed count.
        // Since currentJobId is the ID of the *last processed chunk's event data*, and it's removed upon processing,
        // we can't directly get the batch from cache *after* finish with that ID.
        // If we could capture the debug log from UpdateContactsBatch.finish(), that would be one way.
        // For this test, the data verification is the primary success criteria.
        // The static variable approach from AsyncJobFrameworkTest isn't used here as we are testing a specific batch class.
    }
}
