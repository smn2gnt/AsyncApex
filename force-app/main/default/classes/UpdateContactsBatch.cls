public without sharing class UpdateContactsBatch implements Async.Batch, Async.Stateful {
    Integer recordsProcessed = 0;

    public String start() { // MODIFIED: Return type and implementation
        return 'SELECT ID, BillingStreet, BillingCity, BillingState, ' +
               'BillingPostalCode, BillingCountry, (SELECT ID, MailingStreet, MailingCity, ' +
               'MailingState, MailingPostalCode, MailingCountry FROM Contacts) FROM Account LIMIT 1500';
    }

    public void execute(List<SObject> scope) { // MODIFIED: Parameter type
        List<Contact> contactsToUpdate = new List<Contact>();

        for (SObject sObj : scope) {
            Account account = (Account)sObj; // Cast to Account

            // Sub-queried contacts should be accessible via account.Contacts
            if (account.Contacts != null && !account.Contacts.isEmpty()) {
                for (Contact contact : account.Contacts) {
                    contact.MailingStreet = account.BillingStreet;
                    contact.MailingCity = account.BillingCity;
                    contact.MailingState = account.BillingState;
                    contact.MailingPostalCode = account.BillingPostalCode;
                    contact.MailingCountry = account.BillingCountry;

                    contactsToUpdate.add(contact);
                    recordsProcessed = recordsProcessed + 1; // Ensure this is incremented appropriately
                }
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    public void finish() {
        System.debug(recordsProcessed + ' records processed. Shazam!');
        System.debug('Everything finished');
    }
}