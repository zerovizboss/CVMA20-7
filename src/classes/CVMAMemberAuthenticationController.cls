/**
 * CVMAMemberAuthenticationController
 * Provides Epic #8 access to authenticated CVMA members without consuming org licenses
 *
 * Supports Experience Cloud Community authentication for:
 * - Full Members (FM prefix)
 * - Support Members (SUP prefix)
 * - Auxiliary Members (AUX prefix)
 *
 * @author CVMA Chapter 20-7 Development Team
 * @version 1.0 - Member Portal Implementation
 * @since September 2025
 */
public with sharing class CVMAMemberAuthenticationController {

    /**
     * Authenticate member using Membership ID and basic verification
     * Returns member access token for Epic #8 features
     */
    @AuraEnabled
    public static Map<String, Object> authenticateMember(String membershipId, String lastName, String email) {
        try {
            // Validate input parameters
            if (String.isBlank(membershipId) || String.isBlank(lastName)) {
                throw new AuraHandledException('Membership ID and Last Name are required');
            }

            // Find member with matching credentials
            List<Contact> members = [
                SELECT Id, FirstName, LastName, Email, Membership_Id__c, Level__c,
                       Road_Name__c, Phone, MailingCity, MailingState,
                       npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c
                FROM Contact
                WHERE Membership_Id__c = :membershipId
                AND LastName = :lastName
                AND Level__c != null
                AND Level__c != 'Applicant'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (members.isEmpty()) {
                throw new AuraHandledException('Invalid membership credentials. Please verify your Membership ID and Last Name.');
            }

            Contact member = members[0];

            // Optional email verification (if provided)
            if (String.isNotBlank(email) && !email.equalsIgnoreCase(member.Email)) {
                throw new AuraHandledException('Email address does not match our records.');
            }

            // Check membership status
            if (member.npo02__MembershipEndDate__c != null && member.npo02__MembershipEndDate__c < Date.today()) {
                // Allow access but flag as expired
                return buildMemberResponse(member, 'expired');
            }

            // Generate member access response
            return buildMemberResponse(member, 'active');

        } catch (Exception e) {
            System.debug('Error in member authentication: ' + e.getMessage());
            throw new AuraHandledException('Authentication failed: ' + e.getMessage());
        }
    }

    /**
     * Get Epic #8 features available to authenticated member based on level
     */
    @AuraEnabled
    public static Map<String, Object> getMemberEpic8Access(Id memberId) {
        try {
            Contact member = [
                SELECT Id, FirstName, LastName, Level__c, Membership_Id__c
                FROM Contact
                WHERE Id = :memberId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            Map<String, Object> access = new Map<String, Object>{
                'memberId' => member.Id,
                'memberName' => member.FirstName + ' ' + member.LastName,
                'membershipLevel' => member.Level__c,
                'accessLevel' => determineMemberAccessLevel(member.Level__c),
                'epic8Features' => getAvailableFeatures(member.Level__c)
            };

            return access;

        } catch (Exception e) {
            System.debug('Error getting member Epic #8 access: ' + e.getMessage());
            throw new AuraHandledException('Access determination failed: ' + e.getMessage());
        }
    }

    /**
     * Get member-specific analytics dashboard
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMemberAnalyticsDashboard(Id memberId) {
        try {
            Contact member = [
                SELECT Id, Level__c, Membership_Id__c, npo02__MembershipJoinDate__c
                FROM Contact
                WHERE Id = :memberId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            Map<String, Object> dashboard = new Map<String, Object>{
                'memberProfile' => getMemberProfileSummary(member),
                'accessibleAnalytics' => getMemberAnalyticsAccess(member.Level__c),
                'participationHistory' => getMemberParticipationData(member.Id),
                'chapterEngagement' => getMemberEngagementMetrics(member.Id),
                'availableServices' => getMemberAvailableServices(member.Level__c)
            };

            return dashboard;

        } catch (Exception e) {
            System.debug('Error in member analytics dashboard: ' + e.getMessage());
            throw new AuraHandledException('Dashboard access failed: ' + e.getMessage());
        }
    }

    /**
     * Get cross-chapter features available to member
     */
    @AuraEnabled
    public static Map<String, Object> getMemberCrossChapterAccess(Id memberId) {
        try {
            Contact member = [
                SELECT Id, Level__c, Membership_Id__c, MailingState
                FROM Contact
                WHERE Id = :memberId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            Map<String, Object> crossChapterAccess = new Map<String, Object>{
                'canViewOtherChapters' => canAccessCrossChapterData(member.Level__c),
                'canParticipateInEvents' => canParticipateInCrossChapterEvents(member.Level__c),
                'regionalChapters' => getRegionalChaptersInfo(member.MailingState),
                'availableEvents' => getCrossChapterEventsForMember(member.Level__c),
                'collaborationLevel' => getCrossChapterCollaborationLevel(member.Level__c)
            };

            return crossChapterAccess;

        } catch (Exception e) {
            System.debug('Error in cross-chapter access: ' + e.getMessage());
            throw new AuraHandledException('Cross-chapter access failed: ' + e.getMessage());
        }
    }

    // Private helper methods

    private static Map<String, Object> buildMemberResponse(Contact member, String status) {
        Map<String, Object> response = new Map<String, Object>{
            'success' => true,
            'memberId' => member.Id,
            'memberName' => member.FirstName + ' ' + member.LastName,
            'membershipId' => member.Membership_Id__c,
            'membershipLevel' => member.Level__c,
            'roadName' => member.Road_Name__c,
            'membershipStatus' => status,
            'joinDate' => member.npo02__MembershipJoinDate__c,
            'accessLevel' => determineMemberAccessLevel(member.Level__c),
            'epic8Features' => getAvailableFeatures(member.Level__c)
        };

        return response;
    }

    private static String determineMemberAccessLevel(String memberLevel) {
        switch on memberLevel {
            when 'Full Member' {
                return 'Premium';
            }
            when 'Support Member', 'Auxiliary Member' {
                return 'Basic';
            }
            when else {
                return 'Guest';
            }
        }
    }

    private static Map<String, List<String>> getAvailableFeatures(String memberLevel) {
        Map<String, List<String>> features = new Map<String, List<String>>();

        switch on memberLevel {
            when 'Full Member' {
                features.put('analytics', new List<String>{
                    'Personal Analytics Dashboard',
                    'Chapter Performance Metrics',
                    'Predictive Insights',
                    'Financial Trends',
                    'Event Success Forecasting'
                });
                features.put('external_integration', new List<String>{
                    'VA Benefits Full Access',
                    'Cross-Chapter Coordination',
                    'Advanced Automation Features',
                    'Crisis Support Services',
                    'Leadership Tools'
                });
            }
            when 'Support Member', 'Auxiliary Member' {
                features.put('analytics', new List<String>{
                    'Personal Participation History',
                    'Basic Chapter Statistics'
                });
                features.put('external_integration', new List<String>{
                    'VA Benefits Information',
                    'Crisis Support Services',
                    'Community Resources'
                });
            }
        }

        return features;
    }

    private static Map<String, Object> getMemberProfileSummary(Contact member) {
        return new Map<String, Object>{
            'membershipLevel' => member.Level__c,
            'membershipId' => member.Membership_Id__c,
            'memberSince' => member.npo02__MembershipJoinDate__c,
            'tenureMonths' => calculateMembershipTenure(member.npo02__MembershipJoinDate__c)
        };
    }

    private static Map<String, Object> getMemberAnalyticsAccess(String memberLevel) {
        Map<String, Object> analyticsAccess = new Map<String, Object>{
            'personalDashboard' => true,
            'chapterMetrics' => memberLevel == 'Full Member',
            'predictiveAnalytics' => memberLevel == 'Full Member',
            'financialAnalytics' => memberLevel == 'Full Member',
            'crossChapterComparisons' => memberLevel == 'Full Member'
        };

        return analyticsAccess;
    }

    private static List<Map<String, Object>> getMemberParticipationData(Id memberId) {
        // Simplified participation tracking
        return new List<Map<String, Object>>{
            new Map<String, Object>{
                'eventType' => 'Chapter Meetings',
                'participation' => 'Regular',
                'lastAttended' => Date.today().addDays(-7)
            },
            new Map<String, Object>{
                'eventType' => 'Fundraising Events',
                'participation' => 'Active',
                'lastAttended' => Date.today().addDays(-30)
            }
        };
    }

    private static Map<String, Object> getMemberEngagementMetrics(Id memberId) {
        return new Map<String, Object>{
            'engagementScore' => 85.0,
            'eventAttendanceRate' => 75.0,
            'communityParticipation' => 'High',
            'lastActivity' => Date.today().addDays(-3)
        };
    }

    private static List<String> getMemberAvailableServices(String memberLevel) {
        List<String> services = new List<String>{
            'Crisis Support Access',
            'VA Benefits Information'
        };

        if (memberLevel == 'Full Member') {
            services.addAll(new List<String>{
                'Cross-Chapter Event Registration',
                'Member Directory Access',
                'Advanced Resource Library'
            });
        }

        if (memberLevel == 'Full Member') {
            services.addAll(new List<String>{
                'Leadership Resources',
                'Chapter Analytics Dashboard',
                'Predictive Planning Tools'
            });
        }

        return services;
    }

    private static Boolean canAccessCrossChapterData(String memberLevel) {
        return memberLevel == 'Full Member';
    }

    private static Boolean canParticipateInCrossChapterEvents(String memberLevel) {
        return memberLevel == 'Full Member' || memberLevel == 'Support Member' || memberLevel == 'Auxiliary Member';
    }

    private static List<Map<String, Object>> getRegionalChaptersInfo(String state) {
        // Simplified regional chapter information
        return new List<Map<String, Object>>{
            new Map<String, Object>{
                'chapterName' => 'CVMA ' + state + ' Regional',
                'location' => state,
                'memberCount' => 150,
                'activeEvents' => 3
            }
        };
    }

    private static List<Map<String, Object>> getCrossChapterEventsForMember(String memberLevel) {
        List<Map<String, Object>> events = new List<Map<String, Object>>();

        if (memberLevel == 'Full Member' || memberLevel == 'Support Member' || memberLevel == 'Auxiliary Member') {
            events.add(new Map<String, Object>{
                'eventName' => 'Regional Ride for Veterans',
                'date' => Date.today().addDays(30),
                'participatingChapters' => 5,
                'registrationOpen' => true
            });
        }

        if (memberLevel == 'Full Member') {
            events.add(new Map<String, Object>{
                'eventName' => 'National Leadership Summit',
                'date' => Date.today().addDays(60),
                'participatingChapters' => 25,
                'registrationOpen' => true
            });
        }

        return events;
    }

    private static String getCrossChapterCollaborationLevel(String memberLevel) {
        switch on memberLevel {
            when 'Full Member' {
                return 'Leadership';
            }
            when 'Support Member', 'Auxiliary Member' {
                return 'Observer';
            }
            when else {
                return 'Limited';
            }
        }
    }

    private static Integer calculateMembershipTenure(Date joinDate) {
        if (joinDate == null) return 0;
        return joinDate.monthsBetween(Date.today());
    }
}
