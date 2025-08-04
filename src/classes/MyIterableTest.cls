/**
 * Test class for MyIterable - Enhanced with CVMATestDataFactory usage
 * Demonstrates Salesforce best practices for test data creation
 */
@IsTest
private class MyIterableTest {

    @IsTest
    static void testIterableForLoop() {
        // Using test data factory for consistent test data
        CVMATestDataFactory.TestDataBundle testData = CVMATestDataFactory.setupBasicTestData();
        
        Test.startTest();
        
        // Test basic iterable functionality
        List<String> strings = new List<String> {'Hello','World'};
        MyIterable tstIterator = new MyIterable(strings);

        // Collect results from iterator
        List<String> results = new List<String>();
        for(String str : tstIterator){
            System.debug(str);
            results.add(str);
        }
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, results.size(), 'Should iterate over 2 strings');
        System.assertEquals('Hello', results[0], 'First string should be Hello');
        System.assertEquals('World', results[1], 'Second string should be World');
    }
    
    @IsTest
    static void testIterableWithContactNames() {
        Test.startTest();
        
        // Create test contacts using factory
        List<Contact> testContacts = CVMATestDataFactory.createAndInsertContacts(3);
        
        // Extract names for iteration
        List<String> contactNames = new List<String>();
        for (Contact contact : testContacts) {
            contactNames.add(contact.FirstName + ' ' + contact.LastName);
        }
        
        // Test iterator with contact names
        MyIterable nameIterator = new MyIterable(contactNames);
        List<String> iteratedNames = new List<String>();
        
        for (String name : nameIterator) {
            iteratedNames.add(name);
        }
        
        Test.stopTest();
        
        // Verify iteration worked correctly
        System.assertEquals(3, iteratedNames.size(), 'Should iterate over 3 contact names');
        System.assertEquals(contactNames.size(), iteratedNames.size(), 'Iterated count should match original');
        
        for (Integer i = 0; i < contactNames.size(); i++) {
            System.assertEquals(contactNames[i], iteratedNames[i], 'Names should match at index ' + i);
        }
    }
    
    @IsTest
    static void testIterableWithEmptyList() {
        Test.startTest();
        
        // Test with empty list
        List<String> emptyList = new List<String>();
        MyIterable emptyIterator = new MyIterable(emptyList);
        
        Integer count = 0;
        for (String str : emptyIterator) {
            count++;
        }
        
        Test.stopTest();
        
        // Verify empty list behavior
        System.assertEquals(0, count, 'Should not iterate over empty list');
    }
    
    @IsTest
    static void testIterableWithNullValues() {
        Test.startTest();
        
        // Test with list containing null values
        List<String> listWithNulls = new List<String>{'First', null, 'Third'};
        MyIterable nullIterator = new MyIterable(listWithNulls);
        
        List<String> results = new List<String>();
        for (String str : nullIterator) {
            results.add(str);
        }
        
        Test.stopTest();
        
        // Verify null handling
        System.assertEquals(3, results.size(), 'Should iterate over all elements including null');
        System.assertEquals('First', results[0], 'First element should be First');
        System.assertEquals(null, results[1], 'Second element should be null');
        System.assertEquals('Third', results[2], 'Third element should be Third');
    }
}