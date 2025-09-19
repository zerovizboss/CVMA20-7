/**
 * @description Helper class for Lightning Calendar integration with CVMA Campaign events
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * This helper demonstrates Standard Feature Integration by syncing Campaign objects
 * with standard Event objects for Lightning Calendar display, eliminating the need
 * for custom calendar components.
 */
public with sharing class CVMACalendarHelper {

    private static final String EVENT_TYPE_CVMA = 'CVMA Event';
    private static final String EVENT_SUBJECT_PREFIX = '[CVMA] ';

    /**
     * @description Sync CVMA Campaigns to standard Events for Lightning Calendar display
     * @param campaignIds List of Campaign IDs to sync
     */
    @AuraEnabled
    public static void syncCampaignsToEvents(List<Id> campaignIds) {
        try {
            // Validate CRUD permissions
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Type', 'CVMA_Event_RSVP_Mapping__c'},
                'read'
            );

            CVMAErrorHandler.validateCRUDPermissions(
                Event.getSObjectType(),
                new List<String>{'Subject', 'Description', 'StartDateTime', 'EndDateTime', 'Type', 'WhatId'},
                'create'
            );

            // Get CVMA Campaigns that need Event sync
            List<Campaign> campaigns = [
                SELECT Id, Name, Description, StartDate, EndDate, Type, CVMA_Event_RSVP_Mapping__c
                FROM Campaign
                WHERE Id IN :campaignIds
                AND Type = 'CVMA Event'
                AND CVMA_Event_RSVP_Mapping__c = true
                WITH SECURITY_ENFORCED
            ];

            // Get existing Events for these Campaigns to avoid duplicates
            Map<Id, Event> existingEventsMap = new Map<Id, Event>();
            for (Event existingEvent : [
                SELECT Id, WhatId
                FROM Event
                WHERE WhatId IN :campaignIds
                WITH SECURITY_ENFORCED
            ]) {
                existingEventsMap.put(existingEvent.WhatId, existingEvent);
            }

            List<Event> eventsToUpsert = new List<Event>();

            // Create or update Events for each Campaign
            for (Campaign campaign : campaigns) {
                Event eventRecord = existingEventsMap.get(campaign.Id);

                if (eventRecord == null) {
                    // Create new Event
                    eventRecord = new Event();
                    eventRecord.WhatId = campaign.Id;
                }

                // Update Event fields from Campaign
                eventRecord.Subject = EVENT_SUBJECT_PREFIX + campaign.Name;
                eventRecord.Description = campaign.Description;
                eventRecord.Type = EVENT_TYPE_CVMA;

                // Handle date/time conversion
                if (campaign.StartDate != null) {
                    eventRecord.StartDateTime = DateTime.newInstance(
                        campaign.StartDate,
                        Time.newInstance(18, 0, 0, 0) // Default to 6 PM
                    );

                    // Set end time to 2 hours later if no end date
                    if (campaign.EndDate != null) {
                        eventRecord.EndDateTime = DateTime.newInstance(
                            campaign.EndDate,
                            Time.newInstance(20, 0, 0, 0) // Default to 8 PM
                        );
                    } else {
                        eventRecord.EndDateTime = eventRecord.StartDateTime.addHours(2);
                    }
                }

                eventsToUpsert.add(eventRecord);
            }

            // Upsert Events
            if (!eventsToUpsert.isEmpty()) {
                upsert eventsToUpsert;
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACalendarHelper', 'syncCampaignsToEvents',
                                           CVMAErrorHandler.Category.INTEGRATION);
            throw new AuraHandledException('Unable to sync campaigns to calendar: ' + e.getMessage());
        }
    }

    /**
     * @description Get calendar events for Lightning Calendar display
     * @param startDate Start date for calendar view
     * @param endDate End date for calendar view
     * @return List<Event> Events for calendar display
     */
    @AuraEnabled(cacheable=true)
    public static List<Event> getCalendarEvents(Date startDate, Date endDate) {
        try {
            // Validate parameters
            if (startDate == null || endDate == null) {
                throw new AuraHandledException('Start and end dates are required');
            }

            // Validate CRUD permissions
            CVMAErrorHandler.validateCRUDPermissions(
                Event.getSObjectType(),
                new List<String>{'Subject', 'Description', 'StartDateTime', 'EndDateTime', 'Type', 'WhatId'},
                'read'
            );

            // Query Events for the specified date range
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));

            return [
                SELECT Id, Subject, Description, StartDateTime, EndDateTime, Type, WhatId
                FROM Event
                WHERE StartDateTime >= :startDateTime
                AND StartDateTime <= :endDateTime
                AND Type = :EVENT_TYPE_CVMA
                WITH SECURITY_ENFORCED
                ORDER BY StartDateTime ASC
            ];

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACalendarHelper', 'getCalendarEvents',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to retrieve calendar events: ' + e.getMessage());
        }
    }

    /**
     * @description Create a new CVMA event (Campaign) from calendar
     * @param eventName Name of the event
     * @param eventDescription Description of the event
     * @param startDateTime Start date and time
     * @param endDateTime End date and time
     * @return Id Created Campaign Id
     */
    @AuraEnabled
    public static Id createCVMAEvent(String eventName, String eventDescription,
                                   DateTime startDateTime, DateTime endDateTime) {
        try {
            // Validate parameters
            if (String.isBlank(eventName) || startDateTime == null) {
                throw new AuraHandledException('Event name and start time are required');
            }

            // Validate CRUD permissions
            CVMAErrorHandler.validateCRUDPermissions(
                Campaign.getSObjectType(),
                new List<String>{'Name', 'Description', 'StartDate', 'EndDate', 'Type', 'Status', 'IsActive', 'CVMA_Event_RSVP_Mapping__c'},
                'create'
            );

            // Create Campaign for the event
            Campaign eventCampaign = new Campaign();
            eventCampaign.Name = eventName;
            eventCampaign.Description = eventDescription;
            eventCampaign.Type = 'CVMA Event';
            eventCampaign.Status = 'Planned';
            eventCampaign.IsActive = true;
            eventCampaign.CVMA_Event_RSVP_Mapping__c = true;

            // Convert DateTime to Date for Campaign fields
            eventCampaign.StartDate = startDateTime.date();
            if (endDateTime != null) {
                eventCampaign.EndDate = endDateTime.date();
            }

            insert eventCampaign;

            // Automatically sync to Event object
            syncCampaignsToEvents(new List<Id>{ eventCampaign.Id });

            return eventCampaign.Id;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACalendarHelper', 'createCVMAEvent',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to create CVMA event: ' + e.getMessage());
        }
    }

    /**
     * @description Get event details including RSVP summary
     * @param eventId Campaign ID for the event
     * @return EventDetail Event details with RSVP information
     */
    @AuraEnabled(cacheable=true)
    public static EventDetail getEventDetails(Id eventId) {
        try {
            // Validate parameter
            if (eventId == null) {
                throw new AuraHandledException('Event ID is required');
            }

            // Get Campaign details
            Campaign campaign = [
                SELECT Id, Name, Description, StartDate, EndDate, Type, Status, IsActive,
                       CVMA_Event_RSVP_Mapping__c
                FROM Campaign
                WHERE Id = :eventId
                AND Type = 'CVMA Event'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Get RSVP summary using Campaign Members
            List<AggregateResult> rsvpCounts = [
                SELECT Status, COUNT(Id) memberCount
                FROM CampaignMember
                WHERE CampaignId = :eventId
                WITH SECURITY_ENFORCED
                GROUP BY Status
            ];

            // Build event detail response
            EventDetail detail = new EventDetail();
            detail.campaignId = campaign.Id;
            detail.eventName = campaign.Name;
            detail.eventDescription = campaign.Description;
            detail.startDate = campaign.StartDate;
            detail.endDate = campaign.EndDate;
            detail.status = campaign.Status;

            // Process RSVP counts
            detail.yesCount = 0;
            detail.noCount = 0;
            detail.maybeCount = 0;
            detail.totalAttending = 0;

            for (AggregateResult result : rsvpCounts) {
                String status = (String) result.get('Status');
                Integer count = (Integer) result.get('memberCount');

                if (status == 'Responded - Yes') {
                    detail.yesCount = count;
                    detail.totalAttending += count;
                } else if (status == 'Responded - No') {
                    detail.noCount = count;
                } else if (status == 'Responded - Maybe') {
                    detail.maybeCount = count;
                } else if (status == 'Plus One - Yes') {
                    detail.totalAttending += count;
                }
            }

            return detail;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACalendarHelper', 'getEventDetails',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to retrieve event details: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for event details with RSVP information
     */
    public class EventDetail {
        @AuraEnabled public Id campaignId { get; set; }
        @AuraEnabled public String eventName { get; set; }
        @AuraEnabled public String eventDescription { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Integer yesCount { get; set; }
        @AuraEnabled public Integer noCount { get; set; }
        @AuraEnabled public Integer maybeCount { get; set; }
        @AuraEnabled public Integer totalAttending { get; set; }
    }

    /**
     * @description Batch sync all CVMA Campaigns to Events (for initial setup)
     */
    @AuraEnabled
    public static void batchSyncAllCampaigns() {
        try {
            // Get all CVMA Event Campaigns
            List<Campaign> campaigns = [
                SELECT Id
                FROM Campaign
                WHERE Type = 'CVMA Event'
                AND CVMA_Event_RSVP_Mapping__c = true
                WITH SECURITY_ENFORCED
                LIMIT 200
            ];

            List<Id> campaignIds = new List<Id>();
            for (Campaign campaign : campaigns) {
                campaignIds.add(campaign.Id);
            }

            // Sync all campaigns to events
            if (!campaignIds.isEmpty()) {
                syncCampaignsToEvents(campaignIds);
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACalendarHelper', 'batchSyncAllCampaigns',
                                           CVMAErrorHandler.Category.INTEGRATION);
            throw new AuraHandledException('Unable to batch sync campaigns: ' + e.getMessage());
        }
    }
}
