/**
 * @description Streamlined Event Controller for LDS integration
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * Minimal server-side controller that handles:
 * - Recurring event creation logic
 * - Capacity calculations with CampaignMember
 * - Event statistics and summaries
 * - Business logic not available through LDS
 */
public with sharing class CVMAEventControllerLDS {

    public class EventException extends Exception {}

    /**
     * @description Create recurring events from a base event
     * @param baseEventId Id of the base event
     * @param recurrenceType weekly, monthly, yearly
     * @param recurrenceCount Number of additional events to create
     * @param endRecurrenceDate Optional end date for recurrence
     * @return List<Id> Ids of created recurring events
     */
    @AuraEnabled
    public static List<Id> createRecurringEvents(Id baseEventId, String recurrenceType, Integer recurrenceCount, Date endRecurrenceDate) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Type', 'Status'},
                'create'
            );

            Campaign baseEvent = [
                SELECT Id, Name, Description, StartDate, EndDate, Type, Status, NumberSent, IsActive
                FROM Campaign
                WHERE Id = :baseEventId
                AND Type = 'CVMA Event'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (String.isBlank(recurrenceType) || recurrenceCount == null || recurrenceCount <= 0) {
                throw new EventException('Invalid recurrence parameters');
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

            List<Id> createdIds = new List<Id>();
            for (Campaign event : recurringEvents) {
                createdIds.add(event.Id);
            }

            return createdIds;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventControllerLDS', 'createRecurringEvents', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventException('Unable to create recurring events: ' + e.getMessage());
        }
    }

    /**
     * @description Get event capacity and RSVP statistics
     * @param eventId Id of the event
     * @return EventStats Statistics about the event
     */
    @AuraEnabled(cacheable=true)
    public static EventStats getEventStats(Id eventId) {
        try {
            Campaign event = [
                SELECT Id, Name, NumberSent,
                       (SELECT Id, Status, ContactId, Contact.Name
                        FROM CampaignMembers
                        WHERE Status IN ('Responded', 'Sent'))
                FROM Campaign
                WHERE Id = :eventId
                AND Type = 'CVMA Event'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            EventStats stats = new EventStats();
            stats.eventId = event.Id;
            stats.eventName = event.Name;
            stats.capacity = event.NumberSent != null ? Integer.valueOf(event.NumberSent) : -1;
            stats.totalMembers = event.CampaignMembers != null ? event.CampaignMembers.size() : 0;

            stats.respondedCount = 0;
            stats.sentCount = 0;

            if (event.CampaignMembers != null) {
                for (CampaignMember member : event.CampaignMembers) {
                    if (member.Status == 'Responded') {
                        stats.respondedCount++;
                    } else if (member.Status == 'Sent') {
                        stats.sentCount++;
                    }
                }
            }

            stats.availableSpots = stats.capacity > 0 ?
                Math.max(0, stats.capacity - stats.respondedCount) : -1;

            return stats;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventControllerLDS', 'getEventStats', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventException('Unable to retrieve event statistics: ' + e.getMessage());
        }
    }

    /**
     * @description Get upcoming events summary for dashboard
     * @param limitCount Number of events to return
     * @return List<EventSummary> Upcoming events with basic stats
     */
    @AuraEnabled(cacheable=true)
    public static List<EventSummary> getUpcomingEventsSummary(Integer limitCount) {
        try {
            if (limitCount == null || limitCount <= 0) {
                limitCount = 10;
            }

            List<Campaign> events = [
                SELECT Id, Name, StartDate, EndDate, Status,
                       (SELECT Id, Status FROM CampaignMembers)
                FROM Campaign
                WHERE Type = 'CVMA Event'
                AND IsActive = true
                AND StartDate >= TODAY
                AND Status != 'Aborted'
                WITH SECURITY_ENFORCED
                ORDER BY StartDate ASC
                LIMIT :limitCount
            ];

            List<EventSummary> summaries = new List<EventSummary>();
            for (Campaign event : events) {
                EventSummary summary = new EventSummary();
                summary.eventId = event.Id;
                summary.eventName = event.Name;
                summary.startDate = event.StartDate;
                summary.endDate = event.EndDate;
                summary.status = event.Status;

                // Calculate counts manually
                summary.respondedCount = 0;
                summary.totalMembers = event.CampaignMembers != null ? event.CampaignMembers.size() : 0;

                if (event.CampaignMembers != null) {
                    for (CampaignMember member : event.CampaignMembers) {
                        if (member.Status == 'Responded') {
                            summary.respondedCount++;
                        }
                    }
                }

                summaries.add(summary);
            }

            return summaries;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventControllerLDS', 'getUpcomingEventsSummary', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventException('Unable to retrieve upcoming events: ' + e.getMessage());
        }
    }

    /**
     * @description Get available event types for picklist
     * @return List<String> Available CVMA event types
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
     * @description Add member to event (create CampaignMember)
     * @param eventId Id of the event
     * @param contactId Id of the contact/member
     * @param status Campaign member status
     * @return Id CampaignMember Id
     */
    @AuraEnabled
    public static Id addMemberToEvent(Id eventId, Id contactId, String status) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                CampaignMember.getSObjectType(),
                new List<String>{'CampaignId', 'ContactId', 'Status'},
                'create'
            );

            // Check if member already exists
            List<CampaignMember> existing = [
                SELECT Id
                FROM CampaignMember
                WHERE CampaignId = :eventId
                AND ContactId = :contactId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (!existing.isEmpty()) {
                throw new EventException('Member already added to this event');
            }

            CampaignMember newMember = new CampaignMember(
                CampaignId = eventId,
                ContactId = contactId,
                Status = String.isNotBlank(status) ? status : 'Sent'
            );

            insert newMember;
            return newMember.Id;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventControllerLDS', 'addMemberToEvent', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new EventException('Unable to add member to event: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for event statistics
     */
    public class EventStats {
        @AuraEnabled public Id eventId { get; set; }
        @AuraEnabled public String eventName { get; set; }
        @AuraEnabled public Integer capacity { get; set; }
        @AuraEnabled public Integer totalMembers { get; set; }
        @AuraEnabled public Integer respondedCount { get; set; }
        @AuraEnabled public Integer sentCount { get; set; }
        @AuraEnabled public Integer availableSpots { get; set; }
    }

    /**
     * @description Wrapper class for event summary
     */
    public class EventSummary {
        @AuraEnabled public Id eventId { get; set; }
        @AuraEnabled public String eventName { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Integer respondedCount { get; set; }
        @AuraEnabled public Integer totalMembers { get; set; }
    }
}
