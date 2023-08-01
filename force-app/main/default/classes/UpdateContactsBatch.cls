public without sharing class UpdateContactsBatch implements Async.Batch, Async.Stateful{
    Integer recordsProcessed = 0;
    public Iterable<Sobject> start() {
        return new IterableSobject(
            'SELECT ID, BillingStreet, BillingCity, BillingState, ' +
            'BillingPostalCode, BillingCountry, (SELECT ID, MailingStreet, MailingCity, ' +
            'MailingState, MailingPostalCode, MailingCountry FROM Contacts) FROM Account LIMIT 1500'
        );    
    }
    public void execute(List<Account> scope){
        // process each batch of records
        List<Contact> contacts = new List<Contact>();
        for (Account account : scope) {
            for (Contact contact : account.contacts) {
                contact.MailingStreet = account.BillingStreet;
                contact.MailingCity = account.BillingCity;
                contact.MailingState = account.BillingState;
                contact.MailingPostalCode = account.BillingPostalCode;
                contact.MailingCountry = account.BillingCountry;
                // add contact to list to be updated
                contacts.add(contact);
                // increment the instance member counter
                recordsProcessed = recordsProcessed + 1;
            }
        }
        update contacts;
    }
    public void finish(){
        System.debug(recordsProcessed + ' records processed. Shazam!');
        System.debug('Everything finished');
    }

}