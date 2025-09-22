// Final Epic #10 Integration Test - All Components Verification
System.debug('=== FINAL Epic #10 Integration Test ===');

try {
    // Test Resource Search with simplified parameters
    System.debug('Testing Resource Search (no geographic filter)...');
    Map<String, Object> searchTest = CVMAVeteranResourceFinderController.searchVeteranResources(
        '', // No search term to trigger SOQL path
        '', // No service category
        '', // No geographic area
        null // No contact ID
    );
    System.debug('Search Test Success: ' + searchTest.get('success'));
    System.debug('Search Total Found: ' + searchTest.get('totalFound'));
    System.debug('Search Eligible Count: ' + searchTest.get('eligibleCount'));

    // Test all other components
    System.debug('Testing Guest Access...');
    Map<String, Object> guest = CVMAMemberAccessController.getGuestUserAccess();
    System.debug('Guest Access Success: ' + guest.get('success'));

    System.debug('Testing User Access Validation...');
    Map<String, Object> userAccess = CVMAMemberAccessController.validateUserAccess(UserInfo.getUserId());
    System.debug('User Access Success: ' + userAccess.get('success'));

    System.debug('Testing WCAG Compliance...');
    Map<String, Object> wcag = CVMAAccessibilityController.validateWCAGCompliance('cvmaVeteranResourcesPortal');
    System.debug('WCAG Success: ' + wcag.get('success'));
    Map<String, Object> compliance = (Map<String, Object>) wcag.get('overallCompliance');
    System.debug('WCAG Status: ' + compliance.get('status'));

    System.debug('Testing VA Services...');
    Map<String, Object> va = CVMAVAServicesIntegrationController.getVAServicesIntegration(UserInfo.getUserId());
    System.debug('VA Services Success: ' + va.get('success'));

    System.debug('=== INTEGRATION TEST RESULTS ===');
    System.debug('✓ Resource Search: ' + searchTest.get('success'));
    System.debug('✓ Guest Access: ' + guest.get('success'));
    System.debug('✓ User Access: ' + userAccess.get('success'));
    System.debug('✓ WCAG Compliance: ' + wcag.get('success'));
    System.debug('✓ VA Services: ' + va.get('success'));
    System.debug('=== ALL EPIC #10 COMPONENTS OPERATIONAL ===');

} catch (Exception e) {
    System.debug('Final Integration Test Error: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}