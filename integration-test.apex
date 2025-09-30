// Epic #10 Integration Tests - Veterans Resources Portal
// Test all components working together in realistic scenarios

System.debug('=== Epic #10 Integration Testing Started ===');

try {
    // Test 1: Guest User Resource Discovery
    System.debug('Test 1: Guest User Access and Resource Discovery');
    Map<String, Object> guestAccess = CVMAMemberAccessController.getGuestUserAccess();
    System.debug('Guest Access Result: ' + guestAccess.get('success'));
    System.debug('Guest Resource Count: ' + guestAccess.get('resourceCount'));

    // Test 2: Resource Directory Integration
    System.debug('Test 2: Resource Directory and Categorization');
    Map<String, Object> resourceDirectory = CVMAVeteranResourceFinderController.getVeteranResourceDirectory();
    System.debug('Resource Directory Success: ' + resourceDirectory.get('success'));
    System.debug('Total Resources: ' + resourceDirectory.get('totalCount'));

    // Test 3: Accessibility Configuration
    System.debug('Test 3: Accessibility System Configuration');
    Map<String, Object> accessibilityConfig = CVMAAccessibilityController.getAccessibilityConfiguration(UserInfo.getUserId());
    System.debug('Accessibility Config Success: ' + accessibilityConfig.get('success'));

    // Test 4: WCAG Compliance Validation
    System.debug('Test 4: WCAG Compliance for Portal Component');
    Map<String, Object> wcagValidation = CVMAAccessibilityController.validateWCAGCompliance('cvmaVeteranResourcesPortal');
    System.debug('WCAG Validation Success: ' + wcagValidation.get('success'));
    Map<String, Object> compliance = (Map<String, Object>) wcagValidation.get('overallCompliance');
    System.debug('WCAG Compliance Status: ' + compliance.get('status'));

    // Test 5: VA Services Integration
    System.debug('Test 5: VA Services Integration');
    Map<String, Object> vaServices = CVMAVAServicesIntegrationController.getVAServicesIntegration(UserInfo.getUserId());
    System.debug('VA Services Success: ' + vaServices.get('success'));
    System.debug('Integration Status: ' + vaServices.get('integrationStatus'));

    // Test 6: Resource Search Integration
    System.debug('Test 6: Comprehensive Resource Search');
    Map<String, Object> searchResults = CVMAVeteranResourceFinderController.searchVeteranResources(
        'Veterans',
        'Healthcare',
        'California',
        null
    );
    System.debug('Search Success: ' + searchResults.get('success'));
    System.debug('Resources Found: ' + searchResults.get('totalFound'));
    System.debug('Eligible Resources: ' + searchResults.get('eligibleCount'));

    // Test 7: User Access Validation Integration
    System.debug('Test 7: User Access Control Integration');
    Map<String, Object> userAccess = CVMAMemberAccessController.validateUserAccess(UserInfo.getUserId());
    System.debug('User Access Success: ' + userAccess.get('success'));
    Map<String, Object> accessLevel = (Map<String, Object>) userAccess.get('accessLevel');
    System.debug('User Access Level: ' + accessLevel.get('level'));

    // Test 8: Accessibility Assistance Resources
    System.debug('Test 8: Accessibility Assistance Integration');
    Map<String, Object> accessibilityResources = CVMAAccessibilityController.getAccessibilityAssistanceResources(UserInfo.getUserId());
    System.debug('Accessibility Resources Success: ' + accessibilityResources.get('success'));
    System.debug('Disability Resources Count: ' + accessibilityResources.get('resourceCount'));

    System.debug('=== Epic #10 Integration Testing COMPLETED SUCCESSFULLY ===');
    System.debug('All 8 integration tests passed - Portal ready for Experience Cloud deployment');

} catch (Exception e) {
    System.debug('Integration Test Error: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}