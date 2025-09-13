/**
 * @description Guest User-friendly helper class for Lightning Calendar integration
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-10
 *
 * Standard Feature Integration for Guest Users:
 * - Provides limited, public event data for community users
 * - Maintains security boundaries for guest access
 * - Enables calendar functionality without full CRUD permissions
 *
 * Multi-Agent Development:
 * - Strategic Agent (Claude): Guest access security design and data filtering
 * - Tactical Agent (Copilot): Implementation and community testing
 */
public without sharing class CVMAGuestCalendarHelper {

    private static final String EVENT_TYPE_CVMA = 'CVMA Event';
    private static final String PUBLIC_EVENT_STATUS = 'Planned';

    /**
     * @description Get public CVMA events for guest users (read-only, limited data)
     * @param startDate Start date for event range
     * @param endDate End date for event range
     * @return List<Event> Public events safe for guest user access
     */
    @AuraEnabled(cacheable=true)
    public static List<Event> getPublicCalendarEvents(Date startDate, Date endDate) {
        try {
            // Validate date parameters
            if (startDate == null || endDate == null) {
                Date today = Date.today();
                startDate = startDate != null ? startDate : today.toStartOfMonth();
                endDate = endDate != null ? endDate : today.toStartOfMonth().addMonths(1).addDays(-1);
            }

            // Query public events with basic security (no sensitive data)
            List<Event> publicEvents = [
                SELECT Id, Subject, Description, StartDateTime, EndDateTime,
                       IsAllDayEvent, Type, WhatId
                FROM Event
                WHERE StartDateTime >= :startDate
                AND EndDateTime <= :endDate
                AND Type = :EVENT_TYPE_CVMA
                AND IsVisibleInSelfService = true
                AND IsPrivate = false
                WITH SECURITY_ENFORCED
                ORDER BY StartDateTime ASC
                LIMIT 50
            ];

            return sanitizeEventsForGuests(publicEvents);

        } catch (Exception e) {
            // Log error but don't expose details to guest users
            System.debug('Error retrieving public events: ' + e.getMessage());
            return new List<Event>();
        }
    }

    /**
     * @description Get public event details for guest users
     * @param eventId Event ID to retrieve details for
     * @return Map<String, Object> Basic event information safe for guest access
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPublicEventDetails(Id eventId) {
        try {
            if (eventId == null) return null;

            Event eventRecord = [
                SELECT Id, Subject, Description, StartDateTime, EndDateTime,
                       IsAllDayEvent, Type, WhatId
                FROM Event
                WHERE Id = :eventId
                AND Type = :EVENT_TYPE_CVMA
                AND IsVisibleInSelfService = true
                AND IsPrivate = false
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            Map<String, Object> eventDetails = new Map<String, Object>();
            eventDetails.put('id', eventRecord.Id);
            eventDetails.put('subject', sanitizeContent(eventRecord.Subject));
            eventDetails.put('description', sanitizeContent(eventRecord.Description));
            eventDetails.put('startDateTime', eventRecord.StartDateTime);
            eventDetails.put('endDateTime', eventRecord.EndDateTime);
            eventDetails.put('isAllDay', eventRecord.IsAllDayEvent);
            eventDetails.put('type', eventRecord.Type);

            // Add basic RSVP summary for guests (no member names)
            if (eventRecord.WhatId != null && eventRecord.WhatId.getSObjectType() == Campaign.getSObjectType()) {
                eventDetails.put('rsvpSummary', getPublicRSVPSummary(eventRecord.WhatId));
            }

            return eventDetails;

        } catch (Exception e) {
            System.debug('Error retrieving public event details: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Get current month's public events for calendar display
     * @return List<Event> Current month's public events
     */
    @AuraEnabled(cacheable=true)
    public static List<Event> getCurrentMonthPublicEvents() {
        Date today = Date.today();
        Date monthStart = today.toStartOfMonth();
        Date monthEnd = monthStart.addMonths(1).addDays(-1);

        return getPublicCalendarEvents(monthStart, monthEnd);
    }

    /**
     * @description Get basic RSVP summary for public events (no member details)
     * @param campaignId Campaign ID to get RSVP summary for
     * @return Map<String, Object> Basic attendance numbers only
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPublicRSVPSummary(Id campaignId) {
        try {
            if (campaignId == null) return new Map<String, Object>();

            // Get basic attendance counts without exposing member information
            AggregateResult[] results = [
                SELECT Status, COUNT(Id) memberCount
                FROM CampaignMember
                WHERE CampaignId = :campaignId
                AND Status IN ('Responded - Yes', 'Plus One - Yes', 'Responded - Maybe')
                WITH SECURITY_ENFORCED
                GROUP BY Status
            ];

            Integer yesCount = 0;
            Integer maybeCount = 0;
            Integer plusOneCount = 0;

            for (AggregateResult result : results) {
                String status = (String) result.get('Status');
                Integer count = (Integer) result.get('memberCount');

                if (status == 'Responded - Yes') {
                    yesCount += count;
                } else if (status == 'Plus One - Yes') {
                    yesCount += count;
                    plusOneCount += count;
                } else if (status == 'Responded - Maybe') {
                    maybeCount += count;
                }
            }

            Map<String, Object> summary = new Map<String, Object>();
            summary.put('attendingCount', yesCount);
            summary.put('maybeCount', maybeCount);
            summary.put('plusOneCount', plusOneCount);
            summary.put('totalInterested', yesCount + maybeCount);

            return summary;

        } catch (Exception e) {
            System.debug('Error retrieving public RSVP summary: ' + e.getMessage());
            return new Map<String, Object>();
        }
    }

    // PRIVATE HELPER METHODS

    /**
     * @description Sanitize events for guest user consumption
     * @param events List of events to sanitize
     * @return List<Event> Sanitized events safe for guest access
     */
    private static List<Event> sanitizeEventsForGuests(List<Event> events) {
        List<Event> sanitizedEvents = new List<Event>();

        for (Event evt : events) {
            Event sanitizedEvent = new Event();
            sanitizedEvent.Id = evt.Id;
            sanitizedEvent.Subject = sanitizeContent(evt.Subject);
            sanitizedEvent.Description = sanitizeContent(evt.Description);
            sanitizedEvent.StartDateTime = evt.StartDateTime;
            sanitizedEvent.EndDateTime = evt.EndDateTime;
            sanitizedEvent.IsAllDayEvent = evt.IsAllDayEvent;
            sanitizedEvent.Type = evt.Type;
            sanitizedEvent.WhatId = evt.WhatId;

            sanitizedEvents.add(sanitizedEvent);
        }

        return sanitizedEvents;
    }

    /**
     * @description Sanitize content for guest user display
     * @param content Content to sanitize
     * @return String Sanitized content
     */
    private static String sanitizeContent(String content) {
        if (String.isBlank(content)) return '';

        // Remove potentially sensitive information patterns
        String sanitized = content;

        // Remove email patterns
        sanitized = sanitized.replaceAll('(?i)\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b', '[Email Hidden]');

        // Remove phone patterns
        sanitized = sanitized.replaceAll('(?i)\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b', '[Phone Hidden]');

        // Remove member-only content markers
        sanitized = sanitized.replaceAll('(?i)\\[MEMBERS?\\s*ONLY\\].*?(?=\\n|$)', '[Members Only Content]');

        return sanitized.trim();
    }

    /**
     * @description Check if current user is a guest user
     * @return Boolean True if current user is guest
     */
    private static Boolean isGuestUser() {
        try {
            User currentUser = [SELECT UserType FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
            return currentUser.UserType == 'Guest';
        } catch (Exception e) {
            // If we can't determine user type, assume guest for security
            return true;
        }
    }
}
