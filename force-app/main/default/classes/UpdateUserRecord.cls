public with sharing class UpdateUserRecord implements Async.Queue{
    private Contact contact;
    public UpdateUserRecord(Contact contact) {
        this.contact = contact;
    }

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

    private static String generateAlias(Contact contact) {
        String lastName = contact.lastName.length() > 3
          ? contact.lastName.substring(0, 4)
          : contact.lastName;
    
        return contact.firstName.substring(0, 1) + lastName;
      }
}