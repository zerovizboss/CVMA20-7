/**
 * @description Controller for managing CVMA Event RSVP functionality
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 * 
 * Handles RSVP operations including:
 * - Creating and updating RSVPs
 * - Retrieving member RSVP status
 * - Managing attendee lists with privacy controls
 * - Event capacity management
 */
public with sharing class CVMAEventRSVPController {
    
    private static final String RSVP_YES = 'Yes';
    private static final String RSVP_NO = 'No';
    private static final String RSVP_MAYBE = 'Maybe';
    
    /**
     * @description Get RSVP status for current user and specific event
     * @param eventId The Event Id to check RSVP status for
     * @return CVMA_Event_RSVP__c Current user's RSVP record or null
     */
    @AuraEnabled(cacheable=true)
    public static CVMA_Event_RSVP__c getCurrentUserRSVP(Id eventId) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Event_RSVP__c.getSObjectType(), 
                new List<String>{'Event__c', 'Member__c', 'Response__c', 'RSVP_Date__c'}, 
                'read'
            );
            
            Id currentUserId = UserInfo.getUserId();
            Contact currentMember = getCurrentMember(currentUserId);
            
            if (currentMember == null) {
                return null;
            }
            
            List<CVMA_Event_RSVP__c> rsvps = [
                SELECT Id, Event__c, Member__c, Response__c, RSVP_Date__c, 
                       Notes__c, Plus_One__c, Plus_One_Name__c
                FROM CVMA_Event_RSVP__c 
                WHERE Event__c = :eventId 
                AND Member__c = :currentMember.Id
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            return rsvps.isEmpty() ? null : rsvps[0];
            
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'getCurrentUserRSVP', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to retrieve RSVP status: ' + e.getMessage());
        }
    }
    
    /**
     * @description Submit or update RSVP for an event
     * @param eventId The Event Id to RSVP for
     * @param response RSVP response (Yes/No/Maybe)
     * @param notes Optional notes for the RSVP
     * @param plusOne Whether bringing a plus one
     * @param plusOneName Name of plus one if applicable
     * @return String Success message or error
     */
    @AuraEnabled
    public static String submitRSVP(Id eventId, String response, String notes, Boolean plusOne, String plusOneName) {
        try {
            // Validate inputs
            if (String.isBlank(eventId) || String.isBlank(response)) {
                throw new CVMAErrorHandler.ValidationException('Event ID and response are required');
            }
            
            if (!isValidResponse(response)) {
                throw new CVMAErrorHandler.ValidationException('Invalid RSVP response: ' + response);
            }
            
            // Sanitize inputs
            notes = CVMAErrorHandler.sanitizeInput(notes);
            plusOneName = CVMAErrorHandler.sanitizeInput(plusOneName);
            
            // Validate event exists and is accessible
            Campaign targetEvent = getEventById(eventId);
            if (targetEvent == null) {
                throw new CVMAErrorHandler.ValidationException('Event not found or not accessible');
            }
            
            Id currentUserId = UserInfo.getUserId();
            Contact currentMember = getCurrentMember(currentUserId);
            
            if (currentMember == null) {
                throw new CVMAErrorHandler.SecurityException('Only CVMA members can RSVP to events');
            }
            
            // Check for existing RSVP
            CVMA_Event_RSVP__c existingRSVP = getCurrentUserRSVP(eventId);
            
            if (existingRSVP != null) {
                // Update existing RSVP
                CVMAErrorHandler.validateCRUDPermissions(
                    CVMA_Event_RSVP__c.getSObjectType(), 
                    new List<String>{'Event__c', 'Member__c', 'Response__c', 'RSVP_Date__c'}, 
                    'update'
                );
                
                existingRSVP.Response__c = response;
                existingRSVP.RSVP_Date__c = DateTime.now();
                existingRSVP.Notes__c = notes;
                existingRSVP.Plus_One__c = plusOne != null ? plusOne : false;
                existingRSVP.Plus_One_Name__c = (plusOne == true) ? plusOneName : null;
                
                update existingRSVP;
                return 'RSVP updated successfully';
                
            } else {
                // Create new RSVP
                CVMAErrorHandler.validateCRUDPermissions(
                    CVMA_Event_RSVP__c.getSObjectType(), 
                    new List<String>{'Event__c', 'Member__c', 'Response__c', 'RSVP_Date__c'}, 
                    'create'
                );
                
                CVMA_Event_RSVP__c newRSVP = new CVMA_Event_RSVP__c(
                    Event__c = eventId,
                    Member__c = currentMember.Id,
                    Response__c = response,
                    RSVP_Date__c = DateTime.now(),
                    Notes__c = notes,
                    Plus_One__c = plusOne != null ? plusOne : false,
                    Plus_One_Name__c = (plusOne == true) ? plusOneName : null
                );
                
                insert newRSVP;
                return 'RSVP submitted successfully';
            }
            
        } catch (CVMAErrorHandler.ValidationException e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'submitRSVP', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException(e.getMessage());
        } catch (CVMAErrorHandler.SecurityException e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'submitRSVP', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'submitRSVP', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to submit RSVP: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get attendee list for an event with privacy controls
     * @param eventId The Event Id to get attendees for
     * @param showPrivateInfo Whether to show private member information
     * @return List<AttendeeInfo> List of attendee information
     */
    @AuraEnabled(cacheable=true)
    public static List<AttendeeInfo> getEventAttendees(Id eventId, Boolean showPrivateInfo) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Event_RSVP__c.getSObjectType(), 
                new List<String>{'Event__c', 'Member__c', 'Response__c', 'RSVP_Date__c'}, 
                'read'
            );
            
            // Validate event access
            Campaign targetEvent = getEventById(eventId);
            if (targetEvent == null) {
                return new List<AttendeeInfo>();
            }
            
            List<AttendeeInfo> attendees = new List<AttendeeInfo>();
            
            List<CVMA_Event_RSVP__c> rsvps = [
                SELECT Id, Member__c, Member__r.Name, Member__r.FirstName, 
                       Response__c, RSVP_Date__c, Plus_One__c, Plus_One_Name__c
                FROM CVMA_Event_RSVP__c 
                WHERE Event__c = :eventId 
                AND Response__c = :RSVP_YES
                WITH SECURITY_ENFORCED
                ORDER BY RSVP_Date__c ASC
            ];
            
            for (CVMA_Event_RSVP__c rsvp : rsvps) {
                AttendeeInfo attendee = new AttendeeInfo();
                attendee.rsvpId = rsvp.Id;
                attendee.memberId = rsvp.Member__c;
                attendee.response = rsvp.Response__c;
                attendee.rsvpDate = rsvp.RSVP_Date__c;
                attendee.plusOne = rsvp.Plus_One__c;
                
                // Apply privacy controls
                if (showPrivateInfo == true && canViewPrivateInfo()) {
                    attendee.memberName = rsvp.Member__r.Name;
                    attendee.plusOneName = rsvp.Plus_One_Name__c;
                } else {
                    // Show only first name for privacy
                    attendee.memberName = rsvp.Member__r.FirstName != null ? 
                        rsvp.Member__r.FirstName + ' (Member)' : 'CVMA Member';
                    attendee.plusOneName = rsvp.Plus_One__c ? 'Guest' : null;
                }
                
                attendees.add(attendee);
            }
            
            return attendees;
            
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'getEventAttendees', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to retrieve attendee list: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get RSVP summary statistics for an event
     * @param eventId The Event Id to get statistics for
     * @return RSVPSummary Summary of RSVP responses
     */
    @AuraEnabled(cacheable=true)
    public static RSVPSummary getRSVPSummary(Id eventId) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Event_RSVP__c.getSObjectType(), 
                new List<String>{'Event__c', 'Member__c', 'Response__c', 'RSVP_Date__c'}, 
                'read'
            );
            
            RSVPSummary summary = new RSVPSummary();
            
            List<AggregateResult> results = [
                SELECT Response__c, COUNT(Id) responseCount
                FROM CVMA_Event_RSVP__c 
                WHERE Event__c = :eventId
                WITH SECURITY_ENFORCED
                GROUP BY Response__c
            ];
            
            for (AggregateResult result : results) {
                String response = (String) result.get('Response__c');
                Integer count = (Integer) result.get('responseCount');
                
                if (response == RSVP_YES) {
                    summary.yesCount = count;
                } else if (response == RSVP_NO) {
                    summary.noCount = count;
                } else if (response == RSVP_MAYBE) {
                    summary.maybeCount = count;
                }
            }
            
            // Calculate plus ones separately for Yes responses
            List<CVMA_Event_RSVP__c> yesRSVPs = [
                SELECT Plus_One__c
                FROM CVMA_Event_RSVP__c 
                WHERE Event__c = :eventId 
                AND Response__c = :RSVP_YES
                AND Plus_One__c = true
                WITH SECURITY_ENFORCED
            ];
            summary.plusOnes = yesRSVPs.size();
            
            summary.totalAttending = summary.yesCount + summary.plusOnes;
            summary.totalResponses = summary.yesCount + summary.noCount + summary.maybeCount;
            
            return summary;
            
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'getRSVPSummary', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to retrieve RSVP summary: ' + e.getMessage());
        }
    }
    
    // Helper Methods
    
    /**
     * @description Get current user's member contact record
     * @param userId Current user Id
     * @return Contact Member contact or null
     */
    private static Contact getCurrentMember(Id userId) {
        try {
            List<Contact> members = [
                SELECT Id, Name, FirstName, LastName, Email
                FROM Contact 
                WHERE Id IN (
                    SELECT ContactId FROM User WHERE Id = :userId AND ContactId != null
                )
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            return members.isEmpty() ? null : members[0];
            
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'getCurrentMember', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            return null;
        }
    }
    
    /**
     * @description Get campaign (used as event) by Id with security validation
     * @param eventId Campaign Id to retrieve
     * @return Campaign Campaign record or null
     */
    private static Campaign getEventById(Id eventId) {
        try {
            List<Campaign> campaigns = [
                SELECT Id, Name, StartDate, EndDate, IsActive
                FROM Campaign 
                WHERE Id = :eventId 
                AND IsActive = true
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            return campaigns.isEmpty() ? null : campaigns[0];
            
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPController', 'getEventById', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            return null;
        }
    }
    
    /**
     * @description Validate RSVP response value
     * @param response Response to validate
     * @return Boolean True if valid response
     */
    private static Boolean isValidResponse(String response) {
        return response == RSVP_YES || response == RSVP_NO || response == RSVP_MAYBE;
    }
    
    /**
     * @description Check if current user can view private member information
     * @return Boolean True if can view private info
     */
    private static Boolean canViewPrivateInfo() {
        // Check if user has officer or admin privileges
        Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        return currentProfile.Name.contains('System Administrator') || 
               currentProfile.Name.contains('Officer') ||
               currentProfile.Name.contains('Custom: Sales Profile');
    }
    
    // Wrapper Classes
    
    /**
     * @description Wrapper class for attendee information with privacy controls
     */
    public class AttendeeInfo {
        @AuraEnabled public Id rsvpId { get; set; }
        @AuraEnabled public Id memberId { get; set; }
        @AuraEnabled public String memberName { get; set; }
        @AuraEnabled public String response { get; set; }
        @AuraEnabled public DateTime rsvpDate { get; set; }
        @AuraEnabled public Boolean plusOne { get; set; }
        @AuraEnabled public String plusOneName { get; set; }
    }
    
    /**
     * @description Wrapper class for RSVP summary statistics
     */
    public class RSVPSummary {
        @AuraEnabled public Integer yesCount { get; set; }
        @AuraEnabled public Integer noCount { get; set; }
        @AuraEnabled public Integer maybeCount { get; set; }
        @AuraEnabled public Integer plusOnes { get; set; }
        @AuraEnabled public Integer totalAttending { get; set; }
        @AuraEnabled public Integer totalResponses { get; set; }
        
        public RSVPSummary() {
            this.yesCount = 0;
            this.noCount = 0;
            this.maybeCount = 0;
            this.plusOnes = 0;
            this.totalAttending = 0;
            this.totalResponses = 0;
        }
    }
}