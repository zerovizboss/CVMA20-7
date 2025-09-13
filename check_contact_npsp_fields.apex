// Check specific Contact NPSP fields for User Story #17
System.debug('=== Contact NPSP Fields Available ===');

Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
for(String fieldName : contactFields.keySet()) {
    if(fieldName.toLowerCase().contains('npsp__')) {
        System.debug('Contact NPSP Field: ' + fieldName);
    }
}

// Test specific fields we need
List<String> requiredFields = new List<String>{
    'npsp__Total_Gifts__c',
    'npsp__Last_Gift_Date__c', 
    'npsp__Average_Gift__c',
    'npsp__Largest_Gift__c',
    'npsp__Number_of_Gifts__c',
    'npsp__First_Gift_Date__c',
    'npsp__Soft_Credit_Total__c'
};

System.debug('=== Testing Required Fields ===');
for(String field : requiredFields) {
    if(contactFields.containsKey(field.toLowerCase())) {
        System.debug('✅ Field exists: ' + field);
    } else {
        System.debug('❌ Field missing: ' + field);
    }
}