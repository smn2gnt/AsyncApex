/**
 * Example Batch job that updates Contact mailing addresses from Account billing addresses
 * Demonstrates stateful batch processing with record counting
 */
public without sharing class UpdateContactsBatch implements Async.Batch, Async.Stateful {
    Integer recordsProcessed = 0;

    /**
     * Start method - returns SOQL query for accounts with contacts
     * @return SOQL query string
     */
    public String start() {
        return 'SELECT ID, BillingStreet, BillingCity, BillingState, ' +
               'BillingPostalCode, BillingCountry, (SELECT ID, MailingStreet, MailingCity, ' +
               'MailingState, MailingPostalCode, MailingCountry FROM Contacts) FROM Account LIMIT 1500';
    }

    /**
     * Execute method - updates contact mailing addresses for each batch
     * @param scope List of Account SObjects with related Contacts
     */
    public void execute(List<SObject> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();

        for (SObject sObj : scope) {
            Account account = (Account)sObj;

            if (account.Contacts != null && !account.Contacts.isEmpty()) {
                for (Contact contact : account.Contacts) {
                    contact.MailingStreet = account.BillingStreet;
                    contact.MailingCity = account.BillingCity;
                    contact.MailingState = account.BillingState;
                    contact.MailingPostalCode = account.BillingPostalCode;
                    contact.MailingCountry = account.BillingCountry;

                    contactsToUpdate.add(contact);
                    recordsProcessed++;
                }
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    /**
     * Finish method - logs completion message with total records processed
     */
    public void finish() {
        System.debug(recordsProcessed + ' records processed. Batch job complete!');
    }
}