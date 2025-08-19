/**
 * @description Controller for Guest Event Access and Registration functionality
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * Handles guest user operations including:
 * - Viewing public events available to guests
 * - Guest registration for events 
 * - Guest attendance approval workflow
 * - Communication with approved guests
 */
public with sharing class CVMAGuestEventController {

    public class GuestEventException extends Exception {}

    private static final String GUEST_REQUEST_STATUS_PENDING = 'Pending';
    private static final String GUEST_REQUEST_STATUS_APPROVED = 'Approved';
    private static final String GUEST_REQUEST_STATUS_DENIED = 'Denied';
    private static final String GUEST_REQUEST_STATUS_ATTENDED = 'Attended';

    /**
     * @description Get all public events available for guest viewing
     * @return List<PublicEventWrapper> List of public events with basic info
     */
    @AuraEnabled(cacheable=true)
    public static List<PublicEventWrapper> getPublicEvents() {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Status', 'Type'},
                'read'
            );

            List<Campaign> allEvents = [
                SELECT Id, Name, Description, StartDate, EndDate, Status, Type, IsActive
                FROM Campaign
                WHERE Type = 'CVMA Event'
                AND IsActive = true
                AND StartDate >= TODAY
                AND Status != 'Aborted'
                WITH SECURITY_ENFORCED
                ORDER BY StartDate ASC
                LIMIT 50
            ];

            List<Campaign> publicEvents = new List<Campaign>();
            for (Campaign event : allEvents) {
                if (checkEventAllowsGuests(event)) {
                    publicEvents.add(event);
                }
            }

            List<PublicEventWrapper> eventWrappers = new List<PublicEventWrapper>();
            for (Campaign event : publicEvents) {
                PublicEventWrapper wrapper = new PublicEventWrapper();
                wrapper.eventId = event.Id;
                wrapper.eventName = event.Name;
                wrapper.eventDescription = sanitizeEventDescription(event.Description);
                wrapper.startDate = event.StartDate;
                wrapper.endDate = event.EndDate;
                wrapper.status = event.Status;
                wrapper.allowsGuests = checkEventAllowsGuests(event);
                eventWrappers.add(wrapper);
            }

            return eventWrappers;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAGuestEventController', 'getPublicEvents', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new GuestEventException('Unable to retrieve public events: ' + e.getMessage());
        }
    }

    /**
     * @description Submit a guest attendance request for an event
     * @param eventId Id of the event to request attendance
     * @param guestInfo Map containing guest information
     * @return String Request ID for tracking
     */
    @AuraEnabled
    public static String submitGuestRequest(Id eventId, Map<String, Object> guestInfo) {
        try {
            // Validate required guest information
            if (!guestInfo.containsKey('firstName') || String.isBlank((String)guestInfo.get('firstName'))) {
                throw new GuestEventException('First name is required');
            }

            if (!guestInfo.containsKey('lastName') || String.isBlank((String)guestInfo.get('lastName'))) {
                throw new GuestEventException('Last name is required');
            }

            if (!guestInfo.containsKey('email') || String.isBlank((String)guestInfo.get('email'))) {
                throw new GuestEventException('Email is required');
            }

            if (!guestInfo.containsKey('phone') || String.isBlank((String)guestInfo.get('phone'))) {
                throw new GuestEventException('Phone number is required');
            }

            // Verify event exists and allows guests
            Campaign targetEvent = [
                SELECT Id, Name, StartDate, Description
                FROM Campaign
                WHERE Id = :eventId
                AND Type = 'CVMA Event'
                AND IsActive = true
                AND StartDate >= TODAY
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (!checkEventAllowsGuests(targetEvent)) {
                throw new GuestEventException('This event does not accept guest registrations');
            }

            // Check for duplicate requests
            List<CVMA_Guest_Request__c> existingRequests = [
                SELECT Id
                FROM CVMA_Guest_Request__c
                WHERE Event__c = :eventId
                AND Guest_Email__c = :(String)guestInfo.get('email')
                AND Status__c != :GUEST_REQUEST_STATUS_DENIED
                WITH SECURITY_ENFORCED
            ];

            if (!existingRequests.isEmpty()) {
                throw new GuestEventException('You have already submitted a request for this event');
            }

            // Create guest request record
            CVMA_Guest_Request__c guestRequest = new CVMA_Guest_Request__c();
            guestRequest.Event__c = eventId;
            guestRequest.Guest_First_Name__c = CVMAErrorHandler.sanitizeInput((String)guestInfo.get('firstName'));
            guestRequest.Guest_Last_Name__c = CVMAErrorHandler.sanitizeInput((String)guestInfo.get('lastName'));
            guestRequest.Guest_Email__c = CVMAErrorHandler.sanitizeInput((String)guestInfo.get('email'));
            guestRequest.Guest_Phone__c = CVMAErrorHandler.sanitizeInput((String)guestInfo.get('phone'));
            guestRequest.Status__c = GUEST_REQUEST_STATUS_PENDING;
            guestRequest.Request_Date__c = System.now();

            // Optional fields
            if (guestInfo.containsKey('veteranStatus') && guestInfo.get('veteranStatus') != null) {
                guestRequest.Veteran_Status__c = (Boolean)guestInfo.get('veteranStatus');
            }

            if (guestInfo.containsKey('emergencyContact') && !String.isBlank((String)guestInfo.get('emergencyContact'))) {
                guestRequest.Emergency_Contact__c = CVMAErrorHandler.sanitizeInput((String)guestInfo.get('emergencyContact'));
            }

            if (guestInfo.containsKey('additionalInfo') && !String.isBlank((String)guestInfo.get('additionalInfo'))) {
                guestRequest.Additional_Information__c = CVMAErrorHandler.sanitizeInput((String)guestInfo.get('additionalInfo'));
            }

            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Guest_Request__c.getSObjectType(),
                new List<String>{'Event__c', 'Guest_First_Name__c', 'Guest_Last_Name__c', 'Guest_Email__c', 'Guest_Phone__c', 'Status__c'},
                'create'
            );

            insert guestRequest;

            // Send notification to officers
            sendGuestRequestNotification(guestRequest.Id, targetEvent.Name);

            return guestRequest.Id;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAGuestEventController', 'submitGuestRequest', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new GuestEventException('Unable to submit guest request: ' + e.getMessage());
        }
    }

    /**
     * @description Get guest request status
     * @param requestId Id of the guest request
     * @return GuestRequestWrapper Request details and status
     */
    @AuraEnabled(cacheable=true)
    public static GuestRequestWrapper getGuestRequestStatus(Id requestId) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Guest_Request__c.getSObjectType(),
                new List<String>{'Guest_First_Name__c', 'Guest_Last_Name__c', 'Status__c', 'Request_Date__c'},
                'read'
            );

            CVMA_Guest_Request__c guestRequest = [
                SELECT Id, Event__c, Event__r.Name, Event__r.StartDate,
                       Guest_First_Name__c, Guest_Last_Name__c, Guest_Email__c,
                       Status__c, Request_Date__c, Response_Date__c, Response_Notes__c
                FROM CVMA_Guest_Request__c
                WHERE Id = :requestId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            GuestRequestWrapper wrapper = new GuestRequestWrapper();
            wrapper.requestId = guestRequest.Id;
            wrapper.eventId = guestRequest.Event__c;
            wrapper.eventName = guestRequest.Event__r.Name;
            wrapper.eventDate = guestRequest.Event__r.StartDate;
            wrapper.guestName = guestRequest.Guest_First_Name__c + ' ' + guestRequest.Guest_Last_Name__c;
            wrapper.status = guestRequest.Status__c;
            wrapper.requestDate = guestRequest.Request_Date__c;
            wrapper.responseDate = guestRequest.Response_Date__c;
            wrapper.responseNotes = guestRequest.Response_Notes__c;

            return wrapper;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAGuestEventController', 'getGuestRequestStatus', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new GuestEventException('Unable to retrieve request status: ' + e.getMessage());
        }
    }

    /**
     * @description Get pending guest requests for officer review (internal use)
     * @return List<GuestRequestWrapper> Pending guest requests
     */
    @AuraEnabled(cacheable=true)
    public static List<GuestRequestWrapper> getPendingGuestRequests() {
        try {
            // Verify user has officer permissions
            if (!hasOfficerPermissions()) {
                throw new GuestEventException('Insufficient permissions to view guest requests');
            }

            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Guest_Request__c.getSObjectType(),
                new List<String>{'Guest_First_Name__c', 'Guest_Last_Name__c', 'Guest_Email__c', 'Status__c'},
                'read'
            );

            List<CVMA_Guest_Request__c> pendingRequests = [
                SELECT Id, Event__c, Event__r.Name, Event__r.StartDate,
                       Guest_First_Name__c, Guest_Last_Name__c, Guest_Email__c, Guest_Phone__c,
                       Veteran_Status__c, Emergency_Contact__c, Additional_Information__c,
                       Status__c, Request_Date__c
                FROM CVMA_Guest_Request__c
                WHERE Status__c = :GUEST_REQUEST_STATUS_PENDING
                AND Event__r.StartDate >= TODAY
                WITH SECURITY_ENFORCED
                ORDER BY Request_Date__c ASC
            ];

            List<GuestRequestWrapper> requestWrappers = new List<GuestRequestWrapper>();
            for (CVMA_Guest_Request__c request : pendingRequests) {
                GuestRequestWrapper wrapper = new GuestRequestWrapper();
                wrapper.requestId = request.Id;
                wrapper.eventId = request.Event__c;
                wrapper.eventName = request.Event__r.Name;
                wrapper.eventDate = request.Event__r.StartDate;
                wrapper.guestName = request.Guest_First_Name__c + ' ' + request.Guest_Last_Name__c;
                wrapper.guestEmail = request.Guest_Email__c;
                wrapper.guestPhone = request.Guest_Phone__c;
                wrapper.veteranStatus = request.Veteran_Status__c;
                wrapper.emergencyContact = request.Emergency_Contact__c;
                wrapper.additionalInfo = request.Additional_Information__c;
                wrapper.status = request.Status__c;
                wrapper.requestDate = request.Request_Date__c;
                requestWrappers.add(wrapper);
            }

            return requestWrappers;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAGuestEventController', 'getPendingGuestRequests', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new GuestEventException('Unable to retrieve pending guest requests: ' + e.getMessage());
        }
    }

    /**
     * @description Approve or deny a guest request (officer only)
     * @param requestId Id of the guest request
     * @param approved Boolean indicating approval or denial
     * @param responseNotes Notes from the reviewing officer
     * @return Boolean Success status
     */
    @AuraEnabled
    public static Boolean processGuestRequest(Id requestId, Boolean approved, String responseNotes) {
        try {
            // Verify user has officer permissions
            if (!hasOfficerPermissions()) {
                throw new GuestEventException('Insufficient permissions to process guest requests');
            }

            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Guest_Request__c.getSObjectType(),
                new List<String>{'Status__c', 'Response_Date__c', 'Response_Notes__c'},
                'update'
            );

            CVMA_Guest_Request__c guestRequest = [
                SELECT Id, Event__c, Event__r.Name, Guest_First_Name__c, Guest_Last_Name__c, Guest_Email__c, Status__c
                FROM CVMA_Guest_Request__c
                WHERE Id = :requestId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (guestRequest.Status__c != GUEST_REQUEST_STATUS_PENDING) {
                throw new GuestEventException('This request has already been processed');
            }

            guestRequest.Status__c = approved ? GUEST_REQUEST_STATUS_APPROVED : GUEST_REQUEST_STATUS_DENIED;
            guestRequest.Response_Date__c = System.now();
            guestRequest.Response_Notes__c = CVMAErrorHandler.sanitizeInput(responseNotes);

            update guestRequest;

            // Send notification to guest
            sendGuestResponseNotification(guestRequest, approved);

            return true;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAGuestEventController', 'processGuestRequest', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new GuestEventException('Unable to process guest request: ' + e.getMessage());
        }
    }

    /**
     * @description Check if an event allows guest attendance
     * @param event Campaign record representing the event
     * @return Boolean Whether guests are allowed
     */
    private static Boolean checkEventAllowsGuests(Campaign event) {
        if (event.Description == null) {
            return false;
        }

        String description = event.Description.toLowerCase();
        return description.contains('public') || 
               description.contains('guest') || 
               description.contains('open') ||
               description.contains('community');
    }

    /**
     * @description Sanitize event description for public display
     * @param description Original event description
     * @return String Sanitized description
     */
    private static String sanitizeEventDescription(String description) {
        if (String.isBlank(description)) {
            return '';
        }

        // Remove sensitive information and keep only public-appropriate content
        String sanitized = CVMAErrorHandler.sanitizeInput(description);
        
        // Remove internal notes or member-only information
        String[] lines = sanitized.split('\n');
        List<String> publicLines = new List<String>();
        
        for (String line : lines) {
            String lowercaseLine = line.toLowerCase();
            if (!lowercaseLine.contains('internal') && 
                !lowercaseLine.contains('member only') && 
                !lowercaseLine.contains('confidential') &&
                !lowercaseLine.contains('private')) {
                publicLines.add(line);
            }
        }

        return String.join(publicLines, '\n');
    }

    /**
     * @description Check if current user has officer permissions
     * @return Boolean Whether user has officer permissions
     */
    private static Boolean hasOfficerPermissions() {
        try {
            // Check if user has permission set or profile that allows officer functions
            List<PermissionSetAssignment> officerPermissions = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                AND (PermissionSet.Name = 'CVMA_Officer_Permissions' 
                     OR PermissionSet.Name = 'CVMA_Administrator_Permissions')
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            return !officerPermissions.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * @description Send notification to officers about new guest request
     * @param requestId Id of the guest request
     * @param eventName Name of the event
     */
    private static void sendGuestRequestNotification(Id requestId, String eventName) {
        try {
            // Get officer email addresses
            List<User> officers = [
                SELECT Id, Email, Name
                FROM User
                WHERE IsActive = true
                AND Id IN (
                    SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE PermissionSet.Name IN ('CVMA_Officer_Permissions', 'CVMA_Administrator_Permissions')
                )
                AND Email != null
                WITH SECURITY_ENFORCED
                LIMIT 10
            ];

            if (officers.isEmpty()) {
                return;
            }

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<String> officerEmails = new List<String>();

            for (User officer : officers) {
                officerEmails.add(officer.Email);
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(officerEmails);
            email.setSubject('New Guest Request for CVMA Event: ' + eventName);

            String emailBody = 'A new guest attendance request has been submitted for the CVMA event:\n\n' +
                             'Event: ' + eventName + '\n' +
                             'Request ID: ' + requestId + '\n\n' +
                             'Please review and process this request in the CVMA system.\n\n' +
                             'Combat Veterans Motorcycle Association\n' +
                             'Chapter 20-7 - Vets Serving Vets';

            email.setPlainTextBody(emailBody);
            emails.add(email);

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAGuestEventController', 'sendGuestRequestNotification', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            // Don't throw - request should succeed even if notification fails
        }
    }

    /**
     * @description Send response notification to guest
     * @param guestRequest CVMA_Guest_Request__c record
     * @param approved Whether request was approved
     */
    private static void sendGuestResponseNotification(CVMA_Guest_Request__c guestRequest, Boolean approved) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{guestRequest.Guest_Email__c});

            String subject = 'CVMA Guest Request ' + (approved ? 'Approved' : 'Denied') + ': ' + guestRequest.Event__r.Name;
            email.setSubject(subject);

            String emailBody = 'Dear ' + guestRequest.Guest_First_Name__c + ' ' + guestRequest.Guest_Last_Name__c + ',\n\n' +
                             'Your request to attend the CVMA event "' + guestRequest.Event__r.Name + '" has been ' +
                             (approved ? 'approved' : 'denied') + '.\n\n';

            if (approved) {
                emailBody += 'We look forward to having you join us for this event. Please arrive on time and follow any specific instructions provided.\n\n';
            } else {
                emailBody += 'We appreciate your interest in CVMA events. Please feel free to submit requests for other appropriate events.\n\n';
            }

            if (!String.isBlank(guestRequest.Response_Notes__c)) {
                emailBody += 'Additional Notes: ' + guestRequest.Response_Notes__c + '\n\n';
            }

            emailBody += 'Thank you for your interest in the Combat Veterans Motorcycle Association.\n\n' +
                        'Combat Veterans Motorcycle Association\n' +
                        'Chapter 20-7 - Vets Serving Vets';

            email.setPlainTextBody(emailBody);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAGuestEventController', 'sendGuestResponseNotification', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            // Don't throw - approval should succeed even if notification fails
        }
    }

    /**
     * @description Wrapper class for public event information
     */
    public class PublicEventWrapper {
        @AuraEnabled public Id eventId { get; set; }
        @AuraEnabled public String eventName { get; set; }
        @AuraEnabled public String eventDescription { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Boolean allowsGuests { get; set; }

        public PublicEventWrapper() {
            this.allowsGuests = false;
        }
    }

    /**
     * @description Wrapper class for guest request information
     */
    public class GuestRequestWrapper {
        @AuraEnabled public Id requestId { get; set; }
        @AuraEnabled public Id eventId { get; set; }
        @AuraEnabled public String eventName { get; set; }
        @AuraEnabled public Date eventDate { get; set; }
        @AuraEnabled public String guestName { get; set; }
        @AuraEnabled public String guestEmail { get; set; }
        @AuraEnabled public String guestPhone { get; set; }
        @AuraEnabled public Boolean veteranStatus { get; set; }
        @AuraEnabled public String emergencyContact { get; set; }
        @AuraEnabled public String additionalInfo { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public DateTime requestDate { get; set; }
        @AuraEnabled public DateTime responseDate { get; set; }
        @AuraEnabled public String responseNotes { get; set; }
    }
}