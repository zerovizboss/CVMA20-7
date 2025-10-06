/**
 * Controller for CVMA YouTube Carousel Component
 * Manages video metadata retrieval and view tracking
 * Security: without sharing to allow guest user access to custom metadata
 * Note: Custom metadata is org-wide accessible and doesn't require record-level security
 */
public without sharing class CVMAYouTubeCarouselController {

    /**
     * Inner class for video metadata response
     */
    public class VideoMetadata {
        @AuraEnabled public String videoId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public Integer displayOrder { get; set; }
        @AuraEnabled public Boolean isFeatured { get; set; }
        @AuraEnabled public String thumbnailUrl { get; set; }
        @AuraEnabled public Integer viewCount { get; set; }
        @AuraEnabled public String approvalStatus { get; set; }
        @AuraEnabled public String approvedBy { get; set; }
        @AuraEnabled public Date approvalDate { get; set; }
        @AuraEnabled public Date dateAdded { get; set; }
        @AuraEnabled public String metadataName { get; set; }

        public VideoMetadata() {
            this.viewCount = 0;
        }
    }

    /**
     * Get featured videos for carousel display
     * Returns only active and approved videos, sorted by display order
     */
    @AuraEnabled(cacheable=true)
    public static List<VideoMetadata> getFeaturedVideos() {
        try {
            List<VideoMetadata> videoList = new List<VideoMetadata>();

            // Query custom metadata for featured videos
            // Note: Custom metadata queries don't require WITH SECURITY_ENFORCED
            List<CVMA_YouTube_Video__mdt> videos = [
                SELECT
                    DeveloperName,
                    Video_ID__c,
                    Video_Title__c,
                    Video_Description__c,
                    Video_Category__c,
                    Display_Order__c,
                    Is_Featured__c,
                    Thumbnail_URL__c,
                    View_Count__c,
                    Approval_Status__c,
                    Approved_By__c,
                    Approval_Date__c,
                    Date_Added__c
                FROM CVMA_YouTube_Video__mdt
                WHERE Is_Active__c = true
                    AND Is_Featured__c = true
                    AND Approval_Status__c = 'Approved'
                ORDER BY Display_Order__c ASC NULLS LAST, Date_Added__c DESC
                LIMIT 10
            ];

            // Convert to VideoMetadata wrapper
            for (CVMA_YouTube_Video__mdt video : videos) {
                VideoMetadata vm = new VideoMetadata();
                vm.videoId = video.Video_ID__c;
                vm.title = video.Video_Title__c;
                vm.description = video.Video_Description__c;
                vm.category = video.Video_Category__c;
                vm.displayOrder = video.Display_Order__c != null ? Integer.valueOf(video.Display_Order__c) : 999;
                vm.isFeatured = true;
                vm.thumbnailUrl = String.isNotBlank(video.Thumbnail_URL__c)
                    ? video.Thumbnail_URL__c
                    : 'https://img.youtube.com/vi/' + video.Video_ID__c + '/maxresdefault.jpg';
                vm.viewCount = video.View_Count__c != null ? Integer.valueOf(video.View_Count__c) : 0;
                vm.approvalStatus = video.Approval_Status__c;
                vm.approvedBy = video.Approved_By__c;
                vm.approvalDate = video.Approval_Date__c;
                vm.dateAdded = video.Date_Added__c;
                vm.metadataName = video.DeveloperName;

                videoList.add(vm);
            }

            return videoList;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving featured videos: ' + e.getMessage());
        }
    }

    /**
     * Get all active videos filtered by category
     * Used for secondary grid display or category filtering
     */
    @AuraEnabled(cacheable=true)
    public static List<VideoMetadata> getVideosByCategory(String category) {
        try {
            List<VideoMetadata> videoList = new List<VideoMetadata>();

            // Note: Custom metadata queries don't support WITH SECURITY_ENFORCED
            // Category parameter is validated and sanitized before query execution
            List<CVMA_YouTube_Video__mdt> videos;

            if (String.isNotBlank(category)) {
                // Static SOQL with bind variable - no injection risk
                videos = [
                    SELECT DeveloperName, Video_ID__c, Video_Title__c, Video_Description__c,
                        Video_Category__c, Display_Order__c, Is_Featured__c, Thumbnail_URL__c, View_Count__c,
                        Approval_Status__c, Approved_By__c, Approval_Date__c, Date_Added__c
                    FROM CVMA_YouTube_Video__mdt
                    WHERE Is_Active__c = true
                        AND Approval_Status__c = 'Approved'
                        AND Video_Category__c = :category
                    ORDER BY Date_Added__c DESC
                    LIMIT 20
                ];
            } else {
                // No category filter - return all active approved videos
                videos = [
                    SELECT DeveloperName, Video_ID__c, Video_Title__c, Video_Description__c,
                        Video_Category__c, Display_Order__c, Is_Featured__c, Thumbnail_URL__c, View_Count__c,
                        Approval_Status__c, Approved_By__c, Approval_Date__c, Date_Added__c
                    FROM CVMA_YouTube_Video__mdt
                    WHERE Is_Active__c = true
                        AND Approval_Status__c = 'Approved'
                    ORDER BY Date_Added__c DESC
                    LIMIT 20
                ];
            }

            for (CVMA_YouTube_Video__mdt video : videos) {
                VideoMetadata vm = new VideoMetadata();
                vm.videoId = video.Video_ID__c;
                vm.title = video.Video_Title__c;
                vm.description = video.Video_Description__c;
                vm.category = video.Video_Category__c;
                vm.displayOrder = video.Display_Order__c != null ? Integer.valueOf(video.Display_Order__c) : 999;
                vm.isFeatured = video.Is_Featured__c;
                vm.thumbnailUrl = String.isNotBlank(video.Thumbnail_URL__c)
                    ? video.Thumbnail_URL__c
                    : 'https://img.youtube.com/vi/' + video.Video_ID__c + '/maxresdefault.jpg';
                vm.viewCount = video.View_Count__c != null ? Integer.valueOf(video.View_Count__c) : 0;
                vm.approvalStatus = video.Approval_Status__c;
                vm.approvedBy = video.Approved_By__c;
                vm.approvalDate = video.Approval_Date__c;
                vm.dateAdded = video.Date_Added__c;
                vm.metadataName = video.DeveloperName;

                videoList.add(vm);
            }

            return videoList;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving videos by category: ' + e.getMessage());
        }
    }

    /**
     * Get available video categories
     * Returns list of distinct categories for filtering
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getVideoCategories() {
        try {
            Set<String> categorySet = new Set<String>();

            List<CVMA_YouTube_Video__mdt> videos = [
                SELECT Video_Category__c
                FROM CVMA_YouTube_Video__mdt
                WHERE Is_Active__c = true
                    AND Approval_Status__c = 'Approved'
            ];

            for (CVMA_YouTube_Video__mdt video : videos) {
                if (String.isNotBlank(video.Video_Category__c)) {
                    categorySet.add(video.Video_Category__c);
                }
            }

            List<String> categories = new List<String>(categorySet);
            categories.sort();

            return categories;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving video categories: ' + e.getMessage());
        }
    }

    /**
     * Track video view (for analytics)
     * Note: Custom metadata cannot be updated via Apex, so we log to custom object instead
     * Future enhancement: Create CVMA_Video_View__c custom object for analytics
     */
    @AuraEnabled
    public static void trackVideoView(String videoId) {
        try {
            // Future implementation: Log to custom object for analytics
            // For now, just validate input
            if (String.isBlank(videoId)) {
                throw new AuraHandledException('Video ID is required');
            }

            // TODO: Insert into CVMA_Video_View__c custom object
            // This would track: Video ID, View Date, User ID, Session Info

        } catch (Exception e) {
            // Silently fail for analytics tracking (don't disrupt user experience)
            System.debug('Error tracking video view: ' + e.getMessage());
        }
    }
}
