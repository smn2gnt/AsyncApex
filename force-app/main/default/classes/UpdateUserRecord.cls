/**
 * Example Queue job that creates a User from a Contact
 * Demonstrates simple queue-based async processing
 */
public with sharing class UpdateUserRecord implements Async.Queue {
    private Contact contact;
    
    /**
     * Constructor
     * @param contact The contact to create a user from
     */
    public UpdateUserRecord(Contact contact) {
        if (contact == null) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Contact cannot be null');
        }
        this.contact = contact;
    }

    /**
     * Execute method - creates a new User from the Contact
     */
    public void execute() {
        User newUser = new User();
        newUser.FirstName = contact.FirstName;
        newUser.LastName = contact.LastName;
        newUser.Email = contact.Email;
        newUser.Username = contact.Email + '.Test2';
        newUser.IsActive = true;
        newUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        newUser.ContactId = contact.Id;
        newUser.Alias = generateAlias(contact);
        newUser.TimeZoneSidKey = 'Australia/Melbourne';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LocaleSidKey = 'en_AU';
        newUser.LanguageLocaleKey = 'en_US';
        insert newUser;
    }

    /**
     * Generate a user alias from the contact name
     * @param contact The contact to generate alias for
     * @return Generated alias
     */
    private static String generateAlias(Contact contact) {
        if (String.isBlank(contact.firstName)) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Contact firstName cannot be blank for alias generation');
        }
        if (String.isBlank(contact.lastName)) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Contact lastName cannot be blank for alias generation');
        }
        
        String lastName = contact.lastName.length() > 4
          ? contact.lastName.substring(0, 4)
          : contact.lastName;
    
        return contact.firstName.substring(0, 1) + lastName;
    }
}
