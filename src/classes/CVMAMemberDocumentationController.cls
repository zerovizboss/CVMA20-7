/**
 * @description Controller for CVMA Member Documentation System
 * Handles documentation requests from Experience Cloud portal
 * Validates Campaign Member access and delivers content via email
 *
 * Epic #11 User Story #37: CVMA Member Documentation Portal Integration
 *
 * @author Claude Code
 * @version 1.0
 * @since 2025-09-22
 */
public without sharing class CVMAMemberDocumentationController {

    /**
     * @description Get available documentation categories for portal display
     * @return List of documentation categories visible to members
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAvailableMemberDocumentation() {
        try {
            List<Map<String, Object>> documentationCategories = new List<Map<String, Object>>();

            // Use hardcoded documentation categories for initial deployment
            return getHardcodedDocumentationCategories();

        } catch (Exception e) {
            System.debug('Error retrieving documentation categories: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve documentation categories: ' + e.getMessage());
        }
    }

    /**
     * @description Request documentation delivery via email
     * Validates Campaign Member access before sending
     * @param category Documentation category requested
     * @param memberEmail Email address for delivery
     * @param memberName Name for personalization
     * @return Success message or error
     */
    @AuraEnabled
    public static String requestMemberDocumentation(String category, String memberEmail, String memberName) {
        try {
            // Input validation and sanitization
            if (String.isBlank(category) || String.isBlank(memberEmail)) {
                throw new IllegalArgumentException('Category and email are required');
            }

            String sanitizedEmail = String.escapeSingleQuotes(memberEmail);
            String sanitizedCategory = String.escapeSingleQuotes(category);
            String sanitizedName = String.escapeSingleQuotes(memberName);

            // Validate Campaign Member access (except for public documents)
            Boolean isValidMember = validateCampaignMemberAccess(sanitizedEmail, sanitizedCategory);

            if (!isValidMember) {
                return 'Access denied: Documentation requires CVMA membership validation.';
            }

            // For initial deployment, use hardcoded template mapping
            Map<String, String> categoryTemplateMap = getCategoryTemplateMapping();
            String templateName = categoryTemplateMap.get(sanitizedCategory);

            if (String.isBlank(templateName)) {
                return 'Documentation category not found or not available.';
            }

            // Send documentation email
            Boolean emailSent = sendDocumentationEmail(
                sanitizedEmail,
                sanitizedName,
                templateName,
                sanitizedCategory
            );

            if (emailSent) {
                // Log successful request for analytics
                logDocumentationRequest(sanitizedCategory, sanitizedEmail, 'SUCCESS');
                return 'Documentation sent successfully to ' + sanitizedEmail;
            } else {
                logDocumentationRequest(sanitizedCategory, sanitizedEmail, 'EMAIL_FAILED');
                return 'Unable to send documentation. Please contact CVMA support.';
            }

        } catch (Exception e) {
            System.debug('Documentation request failed: ' + e.getMessage());
            throw new AuraHandledException('Documentation request failed: ' + e.getMessage());
        }
    }

    /**
     * @description Validate Campaign Member access for documentation
     * Public documents available to all, restricted docs require membership
     * @param email Member email address
     * @param category Documentation category
     * @return Boolean indicating access permission
     */
    private static Boolean validateCampaignMemberAccess(String email, String category) {
        try {
            // For public documents, allow access
            Set<String> publicCategories = new Set<String>{'member-application', 'ride-guidelines', 'public-info'};
            if (publicCategories.contains(category)) {
                return true;
            }

            // For restricted documents, validate Campaign Member status
            List<CampaignMember> members = [
                SELECT Id, Contact.Email, Status
                FROM CampaignMember
                WHERE Contact.Email = :email
                AND Status IN ('Sent', 'Responded', 'Member')
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            return !members.isEmpty();

        } catch (Exception e) {
            System.debug('Campaign member validation failed: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Send documentation email using Email Template
     * @param recipientEmail Email address for delivery
     * @param recipientName Name for personalization
     * @param templateName Email template developer name
     * @param documentTitle Title for logging
     * @return Boolean indicating email success
     */
    private static Boolean sendDocumentationEmail(String recipientEmail, String recipientName,
                                                String templateName, String documentTitle) {
        try {
            // Get Email Template
            List<EmailTemplate> templates = [
                SELECT Id, Subject, Body, HtmlValue
                FROM EmailTemplate
                WHERE DeveloperName = :templateName
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (templates.isEmpty()) {
                return false;
            }

            // Create single email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(templates[0].Id);
            email.setToAddresses(new String[]{recipientEmail});
            email.setSaveAsActivity(false);
            email.setUseSignature(false);

            // Send email
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});

            return results[0].isSuccess();

        } catch (Exception e) {
            System.debug('Email sending failed: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Log documentation request for analytics
     * @param category Documentation category
     * @param email Requester email
     * @param status Request status
     */
    private static void logDocumentationRequest(String category, String email, String status) {
        try {
            // Create custom object record for analytics (if exists)
            // For now, use System.debug for logging
            System.debug('Documentation Request - Category: ' + category +
                        ', Email: ' + email + ', Status: ' + status +
                        ', Timestamp: ' + System.now());

        } catch (Exception e) {
            // Silent logging failure - don't impact user experience
            System.debug('Logging failed: ' + e.getMessage());
        }
    }

    /**
     * @description Get hardcoded documentation categories for initial deployment
     * @return List of documentation categories
     */
    private static List<Map<String, Object>> getHardcodedDocumentationCategories() {
        List<Map<String, Object>> categories = new List<Map<String, Object>>();

        categories.add(new Map<String, Object>{
            'id' => 'member-application',
            'title' => 'CVMA Member Application Process',
            'category' => 'Membership',
            'summary' => 'Complete guide to joining CVMA Chapter 20-7',
            'templateName' => 'CVMA_Member_Application_Guide'
        });

        categories.add(new Map<String, Object>{
            'id' => 'ride-guidelines',
            'title' => 'Ride Guidelines and Safety',
            'category' => 'Safety',
            'summary' => 'Safety protocols and ride participation guidelines',
            'templateName' => 'CVMA_Ride_Guidelines'
        });

        categories.add(new Map<String, Object>{
            'id' => 'fundraiser-events',
            'title' => 'Fundraiser Events Information',
            'category' => 'Events',
            'summary' => 'Information about upcoming fundraising events',
            'templateName' => 'CVMA_Fundraiser_Events'
        });

        categories.add(new Map<String, Object>{
            'id' => 'meeting-procedures',
            'title' => 'Chapter Meeting Procedures',
            'category' => 'Governance',
            'summary' => 'Meeting schedules, procedures, and member expectations',
            'templateName' => 'CVMA_Meeting_Procedures'
        });

        return categories;
    }

    /**
     * @description Get mapping of categories to email template names
     * @return Map of category to template name
     */
    private static Map<String, String> getCategoryTemplateMapping() {
        Map<String, String> templateMap = new Map<String, String>();
        templateMap.put('member-application', 'CVMA_Member_Application_Guide');
        templateMap.put('ride-guidelines', 'CVMA_Ride_Guidelines');
        templateMap.put('fundraiser-events', 'CVMA_Fundraiser_Events');
        templateMap.put('meeting-procedures', 'CVMA_Meeting_Procedures');
        return templateMap;
    }
}
