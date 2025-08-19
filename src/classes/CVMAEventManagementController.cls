/**
 * @description Controller for CVMA Event Creation and Management functionality
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * Handles event operations including:
 * - Creating and managing events (using Campaign objects)
 * - Recurring event series creation
 * - Event capacity and registration limits
 * - Integration with RSVP system
 * - Officer-level event administration
 */
public with sharing class CVMAEventManagementController {

    public class EventManagementException extends Exception {}
    
    private static final String CVMA_EVENT_RECORD_TYPE = 'CVMA_Event';
    private static final String EVENT_STATUS_PLANNED = 'Planned';
    private static final String EVENT_STATUS_IN_PROGRESS = 'In Progress';
    private static final String EVENT_STATUS_COMPLETED = 'Completed';
    private static final String EVENT_STATUS_CANCELLED = 'Aborted';

    /**
     * @description Get all events for display in management interface
     * @return List<Campaign> List of CVMA events with RSVP counts
     */
    @AuraEnabled(cacheable=true)
    public static List<EventWrapper> getAllEvents() {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Status', 'Type', 'IsActive'},
                'read'
            );

            List<Campaign> events = [
                SELECT Id, Name, Description, StartDate, EndDate, Status, Type, IsActive,
                       NumberSent, NumberOfContacts, NumberOfResponses,
                       (SELECT COUNT() FROM CVMA_Event_RSVPs__r WHERE Response__c = 'Yes') YesCount,
                       (SELECT COUNT() FROM CVMA_Event_RSVPs__r WHERE Response__c = 'No') NoCount,
                       (SELECT COUNT() FROM CVMA_Event_RSVPs__r WHERE Response__c = 'Maybe') MaybeCount,
                       (SELECT COUNT() FROM CVMA_Event_RSVPs__r) TotalRSVPs
                FROM Campaign
                WHERE Type = 'CVMA Event'
                AND IsActive = true
                WITH SECURITY_ENFORCED
                ORDER BY StartDate DESC
                LIMIT 50
            ];

            List<EventWrapper> eventWrappers = new List<EventWrapper>();
            for (Campaign event : events) {
                EventWrapper wrapper = new EventWrapper();
                wrapper.event = event;
                wrapper.yesCount = (Integer)event.get('YesCount');
                wrapper.noCount = (Integer)event.get('NoCount');
                wrapper.maybeCount = (Integer)event.get('MaybeCount');
                wrapper.totalRSVPs = (Integer)event.get('TotalRSVPs');
                wrapper.availableSpots = calculateAvailableSpots(event);
                eventWrappers.add(wrapper);
            }

            return eventWrappers;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'getAllEvents', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventManagementException('Unable to retrieve events: ' + e.getMessage());
        }
    }

    /**
     * @description Create a new CVMA event
     * @param eventData Map containing event information
     * @return String Event Id of created event
     */
    @AuraEnabled
    public static String createEvent(Map<String, Object> eventData) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Type', 'Status'},
                'create'
            );

            // Validate required fields
            if (!eventData.containsKey('name') || String.isBlank((String)eventData.get('name'))) {
                throw new EventManagementException('Event name is required');
            }

            if (!eventData.containsKey('startDate') || eventData.get('startDate') == null) {
                throw new EventManagementException('Event start date is required');
            }

            // Sanitize inputs
            String eventName = CVMAErrorHandler.sanitizeInput((String)eventData.get('name'));
            String eventDescription = CVMAErrorHandler.sanitizeInput((String)eventData.get('description'));

            Campaign newEvent = new Campaign();
            newEvent.Name = eventName;
            newEvent.Description = eventDescription;
            newEvent.StartDate = Date.valueOf((String)eventData.get('startDate'));
            newEvent.Type = 'CVMA Event';
            newEvent.Status = EVENT_STATUS_PLANNED;
            newEvent.IsActive = true;

            // Optional fields
            if (eventData.containsKey('endDate') && eventData.get('endDate') != null) {
                newEvent.EndDate = Date.valueOf((String)eventData.get('endDate'));
            }

            if (eventData.containsKey('location') && !String.isBlank((String)eventData.get('location'))) {
                // Note: Campaign doesn't have location field by default, would need custom field
                // For now, include in description
                newEvent.Description = (newEvent.Description != null ? newEvent.Description + '\n\n' : '') + 
                                     'Location: ' + CVMAErrorHandler.sanitizeInput((String)eventData.get('location'));
            }

            if (eventData.containsKey('capacity') && eventData.get('capacity') != null) {
                newEvent.NumberSent = (Integer)eventData.get('capacity');
            }

            insert newEvent;

            // Handle recurring events
            if (eventData.containsKey('isRecurring') && (Boolean)eventData.get('isRecurring')) {
                createRecurringEvents(newEvent, eventData);
            }

            return newEvent.Id;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'createEvent', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventManagementException('Unable to create event: ' + e.getMessage());
        }
    }

    /**
     * @description Update an existing CVMA event
     * @param eventId Id of event to update
     * @param eventData Map containing updated event information
     * @return Boolean Success status
     */
    @AuraEnabled
    public static Boolean updateEvent(Id eventId, Map<String, Object> eventData) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Status'},
                'update'
            );

            Campaign existingEvent = [
                SELECT Id, Name, Description, StartDate, EndDate, Status, Type
                FROM Campaign
                WHERE Id = :eventId
                AND Type = 'CVMA Event'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (eventData.containsKey('name') && !String.isBlank((String)eventData.get('name'))) {
                existingEvent.Name = CVMAErrorHandler.sanitizeInput((String)eventData.get('name'));
            }

            if (eventData.containsKey('description')) {
                existingEvent.Description = CVMAErrorHandler.sanitizeInput((String)eventData.get('description'));
            }

            if (eventData.containsKey('startDate') && eventData.get('startDate') != null) {
                existingEvent.StartDate = Date.valueOf((String)eventData.get('startDate'));
            }

            if (eventData.containsKey('endDate') && eventData.get('endDate') != null) {
                existingEvent.EndDate = Date.valueOf((String)eventData.get('endDate'));
            }

            if (eventData.containsKey('status') && !String.isBlank((String)eventData.get('status'))) {
                existingEvent.Status = (String)eventData.get('status');
            }

            update existingEvent;
            return true;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'updateEvent', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventManagementException('Unable to update event: ' + e.getMessage());
        }
    }

    /**
     * @description Cancel an event and notify attendees
     * @param eventId Id of event to cancel
     * @param cancellationReason Reason for cancellation
     * @return Boolean Success status
     */
    @AuraEnabled
    public static Boolean cancelEvent(Id eventId, String cancellationReason) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Status', 'Description'},
                'update'
            );

            Campaign eventToCancel = [
                SELECT Id, Name, Description, Status
                FROM Campaign
                WHERE Id = :eventId
                AND Type = 'CVMA Event'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            eventToCancel.Status = EVENT_STATUS_CANCELLED;
            eventToCancel.Description = (eventToCancel.Description != null ? eventToCancel.Description + '\n\n' : '') +
                                      'CANCELLED: ' + CVMAErrorHandler.sanitizeInput(cancellationReason);

            update eventToCancel;

            // Send cancellation notifications to RSVPed members
            sendCancellationNotifications(eventId, cancellationReason);

            return true;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'cancelEvent', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventManagementException('Unable to cancel event: ' + e.getMessage());
        }
    }

    /**
     * @description Get event details including RSVP summary
     * @param eventId Id of event to retrieve
     * @return EventWrapper Detailed event information
     */
    @AuraEnabled(cacheable=true)
    public static EventWrapper getEventDetails(Id eventId) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Status', 'Type'},
                'read'
            );

            Campaign event = [
                SELECT Id, Name, Description, StartDate, EndDate, Status, Type, IsActive,
                       NumberSent, NumberOfContacts, NumberOfResponses,
                       (SELECT Id, Member__c, Member__r.Name, Response__c, RSVP_Date__c, 
                               Plus_One__c, Plus_One_Name__c, Notes__c
                        FROM CVMA_Event_RSVPs__r 
                        ORDER BY RSVP_Date__c DESC)
                FROM Campaign
                WHERE Id = :eventId
                AND Type = 'CVMA Event'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            EventWrapper wrapper = new EventWrapper();
            wrapper.event = event;
            wrapper.rsvpList = event.CVMA_Event_RSVPs__r;
            
            // Calculate RSVP counts
            wrapper.yesCount = 0;
            wrapper.noCount = 0;
            wrapper.maybeCount = 0;
            
            for (CVMA_Event_RSVP__c rsvp : event.CVMA_Event_RSVPs__r) {
                if (rsvp.Response__c == 'Yes') wrapper.yesCount++;
                else if (rsvp.Response__c == 'No') wrapper.noCount++;
                else if (rsvp.Response__c == 'Maybe') wrapper.maybeCount++;
            }
            
            wrapper.totalRSVPs = event.CVMA_Event_RSVPs__r.size();
            wrapper.availableSpots = calculateAvailableSpots(event);

            return wrapper;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'getEventDetails', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventManagementException('Unable to retrieve event details: ' + e.getMessage());
        }
    }

    /**
     * @description Create recurring events based on pattern
     * @param baseEvent The original event to use as template
     * @param eventData Map containing recurrence information
     */
    private static void createRecurringEvents(Campaign baseEvent, Map<String, Object> eventData) {
        try {
            String recurrenceType = (String)eventData.get('recurrenceType'); // weekly, monthly, yearly
            Integer recurrenceCount = (Integer)eventData.get('recurrenceCount');
            Date endRecurrenceDate = eventData.containsKey('endRecurrenceDate') ? 
                                   Date.valueOf((String)eventData.get('endRecurrenceDate')) : null;

            if (String.isBlank(recurrenceType) || recurrenceCount == null || recurrenceCount <= 0) {
                return;
            }

            List<Campaign> recurringEvents = new List<Campaign>();
            Date currentDate = baseEvent.StartDate;

            for (Integer i = 1; i <= recurrenceCount && (endRecurrenceDate == null || currentDate <= endRecurrenceDate); i++) {
                
                // Calculate next occurrence date
                if (recurrenceType == 'weekly') {
                    currentDate = currentDate.addDays(7);
                } else if (recurrenceType == 'monthly') {
                    currentDate = currentDate.addMonths(1);
                } else if (recurrenceType == 'yearly') {
                    currentDate = currentDate.addYears(1);
                }

                if (endRecurrenceDate != null && currentDate > endRecurrenceDate) {
                    break;
                }

                Campaign recurringEvent = baseEvent.clone(false, false, false, false);
                recurringEvent.Name = baseEvent.Name + ' (' + currentDate.format() + ')';
                recurringEvent.StartDate = currentDate;
                
                if (baseEvent.EndDate != null) {
                    Integer daysDifference = baseEvent.StartDate.daysBetween(baseEvent.EndDate);
                    recurringEvent.EndDate = currentDate.addDays(daysDifference);
                }

                recurringEvents.add(recurringEvent);
            }

            if (!recurringEvents.isEmpty()) {
                insert recurringEvents;
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'createRecurringEvents', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            // Don't throw here - we want the base event to succeed even if recurring fails
        }
    }

    /**
     * @description Send cancellation notifications to RSVPed members
     * @param eventId Id of cancelled event
     * @param reason Cancellation reason
     */
    private static void sendCancellationNotifications(Id eventId, String reason) {
        try {
            // Get all members who RSVPed Yes or Maybe
            List<CVMA_Event_RSVP__c> notifyList = [
                SELECT Id, Member__c, Member__r.Email, Member__r.Name, Event__r.Name
                FROM CVMA_Event_RSVP__c
                WHERE Event__c = :eventId
                AND Response__c IN ('Yes', 'Maybe')
                AND Member__r.Email != null
                WITH SECURITY_ENFORCED
            ];

            if (notifyList.isEmpty()) {
                return;
            }

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (CVMA_Event_RSVP__c rsvp : notifyList) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{rsvp.Member__r.Email});
                email.setSubject('CVMA Event Cancelled: ' + rsvp.Event__r.Name);
                
                String emailBody = 'Dear ' + rsvp.Member__r.Name + ',\n\n' +
                                 'We regret to inform you that the following CVMA event has been cancelled:\n\n' +
                                 'Event: ' + rsvp.Event__r.Name + '\n' +
                                 'Reason: ' + reason + '\n\n' +
                                 'We apologize for any inconvenience and will notify you of any rescheduled dates.\n\n' +
                                 'Thank you for your understanding.\n\n' +
                                 'Combat Veterans Motorcycle Association\n' +
                                 'Chapter 20-7 - Vets Serving Vets';
                
                email.setPlainTextBody(emailBody);
                emails.add(email);
            }

            if (!emails.isEmpty() && emails.size() <= 10) { // Respect email limits
                Messaging.sendEmail(emails);
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'sendCancellationNotifications', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            // Don't throw - cancellation should succeed even if notifications fail
        }
    }

    /**
     * @description Calculate available spots for an event
     * @param event Campaign record representing the event
     * @return Integer Number of available spots
     */
    private static Integer calculateAvailableSpots(Campaign event) {
        if (event.NumberSent == null || event.NumberSent <= 0) {
            return -1; // Unlimited capacity
        }

        Integer currentAttendees = 0;
        if (event.getSObjects('CVMA_Event_RSVPs__r') != null) {
            for (SObject rsvp : event.getSObjects('CVMA_Event_RSVPs__r')) {
                if (((CVMA_Event_RSVP__c)rsvp).Response__c == 'Yes') {
                    currentAttendees++;
                    if (((CVMA_Event_RSVP__c)rsvp).Plus_One__c == true) {
                        currentAttendees++; // Count plus ones
                    }
                }
            }
        }

        return Math.max(0, Integer.valueOf(event.NumberSent) - currentAttendees);
    }

    /**
     * @description Get event types for picklist
     * @return List<String> Available event types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getEventTypes() {
        return new List<String>{
            'Chapter Meeting',
            'Ride',
            'Social Event',
            'Charity Event',
            'Training',
            'Memorial Service',
            'Other'
        };
    }

    /**
     * @description Get event statuses for picklist
     * @return List<String> Available event statuses
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getEventStatuses() {
        return new List<String>{
            EVENT_STATUS_PLANNED,
            EVENT_STATUS_IN_PROGRESS,
            EVENT_STATUS_COMPLETED,
            EVENT_STATUS_CANCELLED
        };
    }

    /**
     * @description Delete an event and associated RSVPs
     * @param eventId Id of event to delete
     * @return Boolean Success status
     */
    @AuraEnabled
    public static Boolean deleteEvent(Id eventId) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Id'},
                'delete'
            );

            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Event_RSVP__c.getSObjectType(),
                new List<String>{'Id'},
                'delete'
            );

            // Delete associated RSVPs first
            List<CVMA_Event_RSVP__c> rsvpsToDelete = [
                SELECT Id
                FROM CVMA_Event_RSVP__c
                WHERE Event__c = :eventId
                WITH SECURITY_ENFORCED
            ];

            if (!rsvpsToDelete.isEmpty()) {
                delete rsvpsToDelete;
            }

            // Delete the event
            Campaign eventToDelete = [
                SELECT Id
                FROM Campaign
                WHERE Id = :eventId
                AND Type = 'CVMA Event'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            delete eventToDelete;
            return true;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'deleteEvent', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventManagementException('Unable to delete event: ' + e.getMessage());
        }
    }

    /**
     * @description Get upcoming events for dashboard display
     * @return List<EventWrapper> Upcoming events with RSVP data
     */
    @AuraEnabled(cacheable=true)
    public static List<EventWrapper> getUpcomingEvents() {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Status'},
                'read'
            );

            List<Campaign> events = [
                SELECT Id, Name, Description, StartDate, EndDate, Status, Type,
                       (SELECT COUNT() FROM CVMA_Event_RSVPs__r WHERE Response__c = 'Yes') YesCount,
                       (SELECT COUNT() FROM CVMA_Event_RSVPs__r WHERE Response__c = 'Maybe') MaybeCount,
                       (SELECT COUNT() FROM CVMA_Event_RSVPs__r) TotalRSVPs
                FROM Campaign
                WHERE Type = 'CVMA Event'
                AND IsActive = true
                AND StartDate >= TODAY
                AND Status != :EVENT_STATUS_CANCELLED
                WITH SECURITY_ENFORCED
                ORDER BY StartDate ASC
                LIMIT 10
            ];

            List<EventWrapper> eventWrappers = new List<EventWrapper>();
            for (Campaign event : events) {
                EventWrapper wrapper = new EventWrapper();
                wrapper.event = event;
                wrapper.yesCount = (Integer)event.get('YesCount');
                wrapper.maybeCount = (Integer)event.get('MaybeCount');
                wrapper.totalRSVPs = (Integer)event.get('TotalRSVPs');
                wrapper.availableSpots = calculateAvailableSpots(event);
                eventWrappers.add(wrapper);
            }

            return eventWrappers;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventManagementController', 'getUpcomingEvents', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventManagementException('Unable to retrieve upcoming events: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for event data with RSVP information
     */
    public class EventWrapper {
        @AuraEnabled public Campaign event { get; set; }
        @AuraEnabled public Integer yesCount { get; set; }
        @AuraEnabled public Integer noCount { get; set; }
        @AuraEnabled public Integer maybeCount { get; set; }
        @AuraEnabled public Integer totalRSVPs { get; set; }
        @AuraEnabled public Integer availableSpots { get; set; }
        @AuraEnabled public List<CVMA_Event_RSVP__c> rsvpList { get; set; }

        public EventWrapper() {
            this.yesCount = 0;
            this.noCount = 0;
            this.maybeCount = 0;
            this.totalRSVPs = 0;
            this.availableSpots = -1;
        }
    }
}