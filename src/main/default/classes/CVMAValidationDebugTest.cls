@IsTest
public class CVMAValidationDebugTest {
    
    @IsTest
    static void debugValidationError() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact invalidContact = new Contact(
            FirstName = 'Test',
            LastName = 'Invalid',
            Email = 'test@test.com',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'SUP1234' // Wrong prefix
        );
        
        try {
            insert invalidContact;
            System.assert(false, 'Should have failed');
        } catch (DmlException e) {
            System.debug('Error message: ' + e.getMessage());
            System.debug('Error type: ' + e.getDmlType(0));
            System.debug('Error fields: ' + e.getDmlFields(0));
        }
    }
}