/**
 * Test class for CVMA Membership Level and Format validation rules
 * 
 * Tests validation rules:
 * - CVMA_Membership_Level_Validation: Ensures Level__c matches Membership_Id__c prefix
 * - CVMA_Membership_Format_Validation: Ensures Membership_Id__c follows correct format
 * 
 * Updated flexible format (max 8 characters):
 * - Full Member: FM + 1-5 digits (3-8 characters total)
 * - Support Member: SUP + 1-5 digits (4-8 characters total)
 * - Auxiliary Member: AUX + 1-5 digits (4-8 characters total)
 */
@IsTest
public class CVMAMembershipValidationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'CVMA Test Account'
        );
        insert testAccount;
    }
    
    /**
     * Test successful Contact creation with valid Level and Membership ID combinations
     */
    @IsTest
    static void testValidMembershipCombinations() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        List<Contact> validContacts = new List<Contact>();
        
        // Valid Full Member - minimum length
        validContacts.add(new Contact(
            FirstName = 'John',
            LastName = 'FullMemberMin',
            Email = 'john.min@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'FM1'
        ));
        
        // Valid Full Member - maximum length
        validContacts.add(new Contact(
            FirstName = 'Jane',
            LastName = 'FullMemberMax',
            Email = 'jane.max@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'FM12345'
        ));
        
        // Valid Support Member - minimum length
        validContacts.add(new Contact(
            FirstName = 'Bob',
            LastName = 'SupportMemberMin',
            Email = 'bob.min@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Support Member',
            Membership_Id__c = 'SUP1'
        ));
        
        // Valid Support Member - maximum length
        validContacts.add(new Contact(
            FirstName = 'Alice',
            LastName = 'SupportMemberMax',
            Email = 'alice.max@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Support Member',
            Membership_Id__c = 'SUP12345'
        ));
        
        // Valid Auxiliary Member - minimum length
        validContacts.add(new Contact(
            FirstName = 'Charlie',
            LastName = 'AuxiliaryMemberMin',
            Email = 'charlie.min@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Auxiliary Member',
            Membership_Id__c = 'AUX1'
        ));
        
        // Valid Auxiliary Member - maximum length
        validContacts.add(new Contact(
            FirstName = 'Diana',
            LastName = 'AuxiliaryMemberMax',
            Email = 'diana.max@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Auxiliary Member',
            Membership_Id__c = 'AUX12345'
        ));
        
        // Valid with lowercase prefix (should be accepted due to UPPER() function)
        validContacts.add(new Contact(
            FirstName = 'Eve',
            LastName = 'LowercasePrefix',
            Email = 'eve.lower@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Support Member',
            Membership_Id__c = 'sup999'
        ));
        
        Test.startTest();
        try {
            insert validContacts;
            System.assertEquals(7, validContacts.size(), 'All valid contacts should be inserted successfully');
        } catch (Exception e) {
            System.assert(false, 'Valid membership combinations should not throw validation errors: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test validation rule for mismatched Level and Membership ID prefix
     */
    @IsTest
    static void testInvalidLevelMembershipMismatch() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Full Member with wrong prefix
        Contact invalidContact1 = new Contact(
            FirstName = 'Invalid',
            LastName = 'FullMemberWrongPrefix',
            Email = 'invalid1@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'SUP1234' // Should be FM
        );
        
        Test.startTest();
        try {
            insert invalidContact1;
            System.assert(false, 'Should have thrown validation error for mismatched level and prefix');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('FM'), 
                'Should show validation error message: ' + e.getMessage());
        }
        
        // Support Member with wrong prefix
        Contact invalidContact2 = new Contact(
            FirstName = 'Invalid',
            LastName = 'SupportMemberWrongPrefix',
            Email = 'invalid2@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Support Member',
            Membership_Id__c = 'AUX6789' // Should be SUP
        );
        
        try {
            insert invalidContact2;
            System.assert(false, 'Should have thrown validation error for mismatched level and prefix');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('SUP'), 
                'Should show validation error message: ' + e.getMessage());
        }
        
        // Auxiliary Member with wrong prefix
        Contact invalidContact3 = new Contact(
            FirstName = 'Invalid',
            LastName = 'AuxiliaryMemberWrongPrefix',
            Email = 'invalid3@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Auxiliary Member',
            Membership_Id__c = 'FM11111' // Should be AUX
        );
        
        try {
            insert invalidContact3;
            System.assert(false, 'Should have thrown validation error for mismatched level and prefix');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('AUX'), 
                'Should show validation error message: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test validation rule for invalid Membership ID format
     */
    @IsTest
    static void testInvalidMembershipFormat() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Full Member: Too short (less than 3 characters)
        Contact invalidContact1 = new Contact(
            FirstName = 'Invalid',
            LastName = 'FullMemberTooShort',
            Email = 'invalid1@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'FM' // Too short, needs at least 1 digit
        );
        
        Test.startTest();
        try {
            insert invalidContact1;
            System.assert(false, 'Should have thrown validation error for invalid format');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('format'), 
                'Should show format validation error message: ' + e.getMessage());
        }
        
        // Support Member: Too short (less than 4 characters)
        Contact invalidContact2 = new Contact(
            FirstName = 'Invalid',
            LastName = 'SupportMemberTooShort',
            Email = 'invalid2@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Support Member',
            Membership_Id__c = 'SUP' // Too short, needs at least 1 digit
        );
        
        try {
            insert invalidContact2;
            System.assert(false, 'Should have thrown validation error for invalid format');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('format'), 
                'Should show format validation error message: ' + e.getMessage());
        }
        
        // Any Member: Too long (more than 8 characters)
        Contact invalidContact3 = new Contact(
            FirstName = 'Invalid',
            LastName = 'MemberTooLong',
            Email = 'invalid3@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'FM123456' // Too long, max is 8 characters
        );
        
        try {
            insert invalidContact3;
            System.assert(false, 'Should have thrown validation error for invalid format');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('format'), 
                'Should show format validation error message: ' + e.getMessage());
        }
        
        // Auxiliary Member: Letters in number portion
        Contact invalidContact4 = new Contact(
            FirstName = 'Invalid',
            LastName = 'AuxiliaryMemberLettersInNumbers',
            Email = 'invalid4@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Auxiliary Member',
            Membership_Id__c = 'AUX123A' // Letter in number portion
        );
        
        try {
            insert invalidContact4;
            System.assert(false, 'Should have thrown validation error for invalid format');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('format'), 
                'Should show format validation error message: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test updating existing Contact with invalid combinations
     */
    @IsTest
    static void testUpdateValidation() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create valid contact first
        Contact validContact = new Contact(
            FirstName = 'Valid',
            LastName = 'Member',
            Email = 'valid@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'FM12345'
        );
        insert validContact;
        
        Test.startTest();
        
        // Try to update to invalid combination
        validContact.Level__c = 'Support Member';
        // Keep Membership_Id__c as FM12345 (should be SUP for Support Member)
        
        try {
            update validContact;
            System.assert(false, 'Should have thrown validation error on update');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('SUP'), 
                'Should show validation error message on update: ' + e.getMessage());
        }
        
        // Try to update to invalid format
        validContact.Level__c = 'Full Member'; // Reset to valid level
        validContact.Membership_Id__c = 'INVALID123'; // Invalid format (too long)
        
        try {
            update validContact;
            System.assert(false, 'Should have thrown validation error for invalid format on update');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Membership ID') || 
                         e.getMessage().contains('format'), 
                'Should show format validation error message on update: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    /**
     * Test edge cases and boundary conditions
     */
    @IsTest
    static void testEdgeCases() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test with single digit - Full Member
        Contact edgeContact1 = new Contact(
            FirstName = 'Edge',
            LastName = 'FullMemberSingleDigit',
            Email = 'edge1@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'FM0'
        );
        
        try {
            insert edgeContact1;
            System.assert(true, 'Single digit should be valid for Full Member');
        } catch (Exception e) {
            System.assert(false, 'Single digit should be valid for Full Member: ' + e.getMessage());
        }
        
        // Test with maximum digits - Support Member
        Contact edgeContact2 = new Contact(
            FirstName = 'Edge',
            LastName = 'SupportMemberMaxDigits',
            Email = 'edge2@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Support Member',
            Membership_Id__c = 'SUP99999'
        );
        
        try {
            insert edgeContact2;
            System.assert(true, 'Max digits should be valid for Support Member');
        } catch (Exception e) {
            System.assert(false, 'Max digits should be valid for Support Member: ' + e.getMessage());
        }
        
        // Test with mixed case - Auxiliary Member
        Contact edgeContact3 = new Contact(
            FirstName = 'Edge',
            LastName = 'AuxiliaryMemberMixedCase',
            Email = 'edge3@cvma.org',
            AccountId = testAccount.Id,
            Level__c = 'Auxiliary Member',
            Membership_Id__c = 'aux123'
        );
        
        try {
            insert edgeContact3;
            System.assert(true, 'Mixed case should be valid for Auxiliary Member');
        } catch (Exception e) {
            System.assert(false, 'Mixed case should be valid for Auxiliary Member: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    /**
     * Test various valid length combinations
     */
    @IsTest
    static void testValidLengthCombinations() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        List<Contact> validContacts = new List<Contact>();
        
        // Full Member: 3, 4, 5, 6, 7, 8 character combinations
        validContacts.add(new Contact(
            FirstName = 'Length3', LastName = 'FM', Email = 'fm3@test.com',
            AccountId = testAccount.Id, Level__c = 'Full Member', Membership_Id__c = 'FM1'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length4', LastName = 'FM', Email = 'fm4@test.com',
            AccountId = testAccount.Id, Level__c = 'Full Member', Membership_Id__c = 'FM12'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length5', LastName = 'FM', Email = 'fm5@test.com',
            AccountId = testAccount.Id, Level__c = 'Full Member', Membership_Id__c = 'FM123'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length6', LastName = 'FM', Email = 'fm6@test.com',
            AccountId = testAccount.Id, Level__c = 'Full Member', Membership_Id__c = 'FM1234'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length7', LastName = 'FM', Email = 'fm7@test.com',
            AccountId = testAccount.Id, Level__c = 'Full Member', Membership_Id__c = 'FM12345'
        ));
        
        // Support Member: 4, 5, 6, 7, 8 character combinations
        validContacts.add(new Contact(
            FirstName = 'Length4', LastName = 'SUP', Email = 'sup4@test.com',
            AccountId = testAccount.Id, Level__c = 'Support Member', Membership_Id__c = 'SUP1'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length5', LastName = 'SUP', Email = 'sup5@test.com',
            AccountId = testAccount.Id, Level__c = 'Support Member', Membership_Id__c = 'SUP12'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length6', LastName = 'SUP', Email = 'sup6@test.com',
            AccountId = testAccount.Id, Level__c = 'Support Member', Membership_Id__c = 'SUP123'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length7', LastName = 'SUP', Email = 'sup7@test.com',
            AccountId = testAccount.Id, Level__c = 'Support Member', Membership_Id__c = 'SUP1234'
        ));
        validContacts.add(new Contact(
            FirstName = 'Length8', LastName = 'SUP', Email = 'sup8@test.com',
            AccountId = testAccount.Id, Level__c = 'Support Member', Membership_Id__c = 'SUP12345'
        ));
        
        Test.startTest();
        try {
            insert validContacts;
            System.assertEquals(10, validContacts.size(), 'All length combinations should be valid');
        } catch (Exception e) {
            System.assert(false, 'All length combinations should be valid: ' + e.getMessage());
        }
        Test.stopTest();
    }
}