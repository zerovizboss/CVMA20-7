import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_LEVEL_FIELD from '@salesforce/schema/Contact.Level__c';
// Remove non-existent field import
// import CONTACT_SERVICE_BRANCH_FIELD from '@salesforce/schema/Contact.Military_Service_Branch__c';

import getVeteranResourceDirectory from '@salesforce/apex/CVMAVeteranResourceFinderController.getVeteranResourceDirectory';
import searchVeteranResources from '@salesforce/apex/CVMAVeteranResourceFinderController.searchVeteranResources';
import getVAServicesIntegration from '@salesforce/apex/CVMAVAServicesIntegrationController.getVAServicesIntegration';
import getAvailableMemberDocumentation from '@salesforce/apex/CVMAMemberDocumentationController.getAvailableMemberDocumentation';
import requestMemberDocumentation from '@salesforce/apex/CVMAMemberDocumentationController.requestMemberDocumentation';
import validateUserAccess from '@salesforce/apex/CVMAMemberAccessController.validateUserAccess';
import getAccessibilityConfiguration from '@salesforce/apex/CVMAAccessibilityController.getAccessibilityConfiguration';

export default class CvmaVeteranResourcesPortal extends LightningElement {
    @api portalMode = 'landing'; // landing, search, detail
    @api showCategories = false;
    @api enableSearch = false;
    @api recordId; // Current user's contact ID

    // Initialize component with proper defaults
    connectedCallback() {
        if (this.showCategories === undefined) {
            this.showCategories = true;
        }
        if (this.enableSearch === undefined) {
            this.enableSearch = true;
        }
        this.loadResourceData();
    }

    @track isLoading = true;
    @track resourceCategories = [];
    @track searchResults = [];
    @track personalizedRecommendations = [];
    @track searchTerm = '';
    @track selectedCategory = '';
    @track activeView = 'overview';
    @track error = null;

    // Documentation system properties
    @track memberDocumentationCategories = [];
    @track showDocumentationSection = true;
    @track documentationRequestStatus = '';

    // User profile information
    @track userProfile = {};
    @track memberLevel = '';
    @track serviceBranch = '';

    // User Story #34: Enhanced access control properties
    @track userAccessData = {};
    @track userPermissions = {};
    @track featureAccess = {};
    @track contentAccess = {};
    @track isAccessValidated = false;

    // User Story #35: Accessibility configuration
    @track accessibilityConfig = {};
    @track accessibilityEnabled = false;

    // Resource categories configuration
    resourceCategoryConfig = [
        {
            id: 'va-benefits',
            name: 'VA Benefits & Services',
            icon: 'standard:opportunity',
            description: 'Complete VA benefits information and application assistance',
            color: 'slds-icon-standard-opportunity',
            priority: 1,
            subcategories: ['Disability Compensation', 'Healthcare', 'Education Benefits', 'Home Loans']
        },
        {
            id: 'service-dogs',
            name: 'Service Dog Resources',
            icon: 'custom:custom47',
            description: 'K9 for Warriors and other service dog organizations',
            color: 'slds-icon-custom-custom47',
            priority: 2,
            subcategories: ['K9 for Warriors', 'Canine Companions', 'Warrior Canine Connection']
        },
        {
            id: 'wounded-warrior',
            name: 'Wounded Warrior Support',
            icon: 'standard:person_account',
            description: 'Wounded Warrior Project and similar support programs',
            color: 'slds-icon-standard-person-account',
            priority: 3,
            subcategories: ['Wounded Warrior Project', 'Team Red White & Blue', 'Veterans Community Living Centers']
        },
        {
            id: 'housing',
            name: 'Housing Programs',
            icon: 'standard:home',
            description: 'Homes for Heroes, Tunnel to Towers, and housing assistance',
            color: 'slds-icon-standard-home',
            priority: 4,
            subcategories: ['Homes for Heroes', 'Tunnel to Towers', 'VASH Program', 'HUD-VASH']
        },
        {
            id: 'emergency-response',
            name: 'Emergency Response Volunteering',
            icon: 'standard:groups',
            description: 'Team Rubicon and disaster response opportunities',
            color: 'slds-icon-standard-groups',
            priority: 5,
            subcategories: ['Team Rubicon', 'The Mission Continues', 'Veterans Disaster Relief']
        },
        {
            id: 'local-services',
            name: 'Local Veteran Services',
            icon: 'standard:location',
            description: 'Regional resources and local veteran support organizations',
            color: 'slds-icon-standard-location',
            priority: 6,
            subcategories: ['VFW Posts', 'American Legion', 'DAV Chapters', 'Local Vet Centers']
        },
        {
            id: 'financial-assistance',
            name: 'Financial Assistance Programs',
            icon: 'standard:currency',
            description: 'Emergency financial aid and support funds',
            color: 'slds-icon-standard-currency',
            priority: 7,
            subcategories: ['Veterans Aid', 'Operation Homefront', 'Armed Forces Relief Trust', 'Hope For The Warriors']
        },
        {
            id: 'crisis-support',
            name: 'Crisis Support & Mental Health',
            icon: 'standard:endorsement',
            description: '24/7 crisis support and mental health resources',
            color: 'slds-icon-standard-endorsement',
            priority: 8,
            subcategories: ['Veterans Crisis Line', 'Vet Centers', 'Give an Hour', 'Veterans Path']
        }
    ];

    // Wire to get current user's contact record
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CONTACT_NAME_FIELD, CONTACT_LEVEL_FIELD]
    })
    wiredContact({ data, error }) {
        if (data) {
            this.userProfile = {
                name: data.fields.Name.value,
                level: data.fields.Level__c?.value || 'Basic',
                serviceBranch: data.fields.Title?.value || '' // Use Title field as fallback
            };
            this.memberLevel = this.userProfile.level;
            this.serviceBranch = this.userProfile.serviceBranch;
        } else if (error) {
            console.error('Error loading user profile:', error);
        }
    }


    async loadResourceData() {
        this.isLoading = true;
        this.error = null;

        try {
            // User Story #34: Validate user access first
            if (this.recordId) {
                await this.validateUserAccess();
                await this.loadAccessibilityConfiguration();
            }

            // Load resource categories
            await this.loadResourceCategories();

            // Load member documentation categories (with access control)
            await this.loadMemberDocumentation();

            // Load personalized recommendations if user profile available
            if (this.recordId) {
                await this.loadPersonalizedRecommendations();
            }

        } catch (error) {
            this.error = error;
            console.error('Error loading resource data:', error);
            this.showToast('Error', 'Failed to load veteran resources', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadResourceCategories() {
        try {
            const result = await getVeteranResourceDirectory();

            if (result.success) {
                // Use the service categories from our controller
                const serviceCategories = result.serviceCategories || [];
                const resources = result.resources || [];

                // Merge API data with local configuration
                this.resourceCategories = this.resourceCategoryConfig.map(category => {
                    const resourceCount = resources.filter(r =>
                        r.Industry && category.subcategories.some(sub =>
                            r.Industry.includes(sub) || r.Name.includes(sub)
                        )
                    ).length;

                    return {
                        ...category,
                        resourceCount: resourceCount,
                        featuredResources: resources.filter(r =>
                            r.Industry && category.subcategories.some(sub =>
                                r.Industry.includes(sub) || r.Name.includes(sub)
                            )
                        ).slice(0, 3),
                        lastUpdated: new Date().toISOString()
                    };
                });
            } else {
                this.resourceCategories = this.resourceCategoryConfig;
            }

            // Sort by priority
            this.resourceCategories.sort((a, b) => a.priority - b.priority);

        } catch (error) {
            console.error('Error loading resource categories:', error);
            // Use static configuration as fallback
            this.resourceCategories = this.resourceCategoryConfig;
        }
    }

    async loadPersonalizedRecommendations() {
        try {
            if (this.recordId) {
                const result = await getVAServicesIntegration({ contactId: this.recordId });

                if (result.success) {
                    // Generate recommendations based on VA services analysis
                    const recommendations = this.generateRecommendationsFromVAServices(result);
                    this.personalizedRecommendations = recommendations;
                } else {
                    this.personalizedRecommendations = this.getDefaultRecommendations();
                }
            } else {
                this.personalizedRecommendations = this.getDefaultRecommendations();
            }

        } catch (error) {
            console.error('Error loading personalized recommendations:', error);
            this.personalizedRecommendations = this.getDefaultRecommendations();
        }
    }

    generateRecommendationsFromVAServices(vaServicesResult) {
        const recommendations = [];

        // Analyze service gaps for recommendations
        if (vaServicesResult.serviceAnalysis && vaServicesResult.serviceAnalysis.identifiedGaps) {
            const gaps = vaServicesResult.serviceAnalysis.identifiedGaps;

            gaps.forEach(gap => {
                if (gap.includes('healthcare')) {
                    recommendations.push({
                        id: 'healthcare-gap',
                        title: 'Healthcare Services Gap Identified',
                        description: 'We found potential gaps in your healthcare services. Explore additional healthcare resources.',
                        category: 'va-benefits',
                        urgency: 'high',
                        actionUrl: '/va-services',
                        iconName: 'standard:opportunity'
                    });
                }

                if (gap.includes('Multiple open')) {
                    recommendations.push({
                        id: 'case-consolidation',
                        title: 'Service Request Optimization',
                        description: 'You have multiple open service requests. Consider consolidating for better coordination.',
                        category: 'service-coordination',
                        urgency: 'medium',
                        actionUrl: '/my-cases',
                        iconName: 'standard:case'
                    });
                }
            });
        }

        // Add member-specific recommendations
        if (this.memberLevel === 'Premium' || this.memberLevel === 'Full Member') {
            recommendations.push({
                id: 'premium-resources',
                title: 'Premium Member Resources',
                description: 'Access exclusive resources available to premium CVMA members.',
                category: 'member-benefits',
                urgency: 'medium',
                actionUrl: '/premium-resources',
                iconName: 'standard:custom'
            });
        }

        return recommendations.length > 0 ? recommendations : this.getDefaultRecommendations();
    }

    getDefaultRecommendations() {
        // Fallback recommendations based on service branch
        const defaultRecommendations = [
            {
                id: 'va-benefits-check',
                title: 'Check Your VA Benefits Eligibility',
                description: 'Ensure you\'re receiving all benefits you\'ve earned through your service.',
                category: 'va-benefits',
                urgency: 'high',
                actionUrl: '/va-services',
                iconName: 'standard:opportunity'
            },
            {
                id: 'local-resources',
                title: 'Connect with Local Veteran Organizations',
                description: 'Find VFW posts, American Legion chapters, and other veteran groups in your area.',
                category: 'local-services',
                urgency: 'medium',
                actionUrl: '/veteran-organizations',
                iconName: 'standard:location'
            }
        ];

        // Add service-specific recommendations
        if (this.serviceBranch === 'Army' || this.serviceBranch === 'Marines') {
            defaultRecommendations.push({
                id: 'combat-support',
                title: 'Combat Veteran Support Resources',
                description: 'Specialized support for combat veterans including PTSD resources and peer support.',
                category: 'crisis-support',
                urgency: 'medium',
                actionUrl: '/crisis-support',
                iconName: 'standard:endorsement'
            });
        }

        return defaultRecommendations;
    }

    // Search functionality
    handleSearchChange(event) {
        this.searchTerm = event.target.value;

        // Debounce search to avoid excessive API calls
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }

        this.searchTimeout = setTimeout(() => {
            if (this.searchTerm.length >= 3) {
                this.performSearch();
            } else {
                this.searchResults = [];
            }
        }, 500);
    }

    async performSearch() {
        if (!this.searchTerm || this.searchTerm.length < 3) {
            return;
        }

        this.isLoading = true;

        try {
            const result = await searchVeteranResources({
                searchTerm: this.searchTerm,
                serviceCategory: this.selectedCategory,
                geographicArea: '',
                contactId: this.recordId
            });

            if (result.success) {
                this.searchResults = result.searchResults || [];
                this.activeView = 'search';
            } else {
                this.showToast('Search Error', result.error || 'Failed to search veteran resources', 'error');
                this.searchResults = [];
            }

        } catch (error) {
            console.error('Error performing search:', error);
            this.showToast('Search Error', 'Failed to search veteran resources', 'error');
            this.searchResults = [];
        } finally {
            this.isLoading = false;
        }
    }

    // Category selection
    handleCategoryClick(event) {
        const categoryId = event.currentTarget.dataset.categoryId;
        this.selectedCategory = categoryId;

        // Navigate to category-specific view
        this.navigateToCategory(categoryId);
    }

    navigateToCategory(categoryId) {
        const category = this.resourceCategories.find(cat => cat.id === categoryId);

        if (category) {
            // Dispatch custom event to parent components or navigate to category page
            this.dispatchEvent(new CustomEvent('categoryselect', {
                detail: {
                    categoryId: categoryId,
                    categoryName: category.name,
                    categoryData: category
                }
            }));

            // Update search to show category resources
            this.selectedCategory = categoryId;
            this.searchTerm = '';
            this.performCategorySearch(categoryId);
        }
    }

    async performCategorySearch(categoryId) {
        this.isLoading = true;

        try {
            // Map category ID to industry filter
            const categoryMapping = {
                'va-benefits': 'Government',
                'service-dogs': 'Nonprofit',
                'wounded-warrior': 'Nonprofit',
                'housing': 'Real Estate',
                'emergency-response': 'Nonprofit',
                'local-services': 'Nonprofit',
                'financial-assistance': 'Financial Services',
                'crisis-support': 'Healthcare'
            };

            const serviceCategory = categoryMapping[categoryId] || '';

            const result = await searchVeteranResources({
                searchTerm: '',
                serviceCategory: serviceCategory,
                geographicArea: '',
                contactId: this.recordId
            });

            if (result.success) {
                this.searchResults = result.searchResults || [];
                this.activeView = 'category';
            } else {
                this.showToast('Error', result.error || 'Failed to load category resources', 'error');
            }

        } catch (error) {
            console.error('Error loading category resources:', error);
            this.showToast('Error', 'Failed to load category resources', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Recommendation actions
    handleRecommendationClick(event) {
        const recommendationId = event.currentTarget.dataset.recommendationId;
        const recommendation = this.personalizedRecommendations.find(rec => rec.id === recommendationId);

        if (recommendation && recommendation.actionUrl) {
            // Navigate to recommended resource
            this.navigateToResource(recommendation.actionUrl);
        }
    }

    navigateToResource(resourceUrl) {
        // Dispatch navigation event or use Lightning Navigation
        this.dispatchEvent(new CustomEvent('navigate', {
            detail: {
                url: resourceUrl
            }
        }));
    }

    // View management
    handleViewChange(event) {
        this.activeView = event.target.dataset.view;
    }

    handleBackToOverview() {
        this.activeView = 'overview';
        this.selectedCategory = '';
        this.searchTerm = '';
        this.searchResults = [];
    }

    // Getters for template rendering
    get showOverview() {
        return this.activeView === 'overview';
    }

    get showSearch() {
        return this.activeView === 'search';
    }

    get showCategory() {
        return this.activeView === 'category';
    }

    get hasSearchResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get hasPersonalizedRecommendations() {
        return this.personalizedRecommendations && this.personalizedRecommendations.length > 0;
    }

    get searchPlaceholder() {
        return 'Search veteran resources, organizations, or services...';
    }

    get welcomeMessage() {
        if (this.userProfile.name) {
            return `Welcome ${this.userProfile.name} - Explore veteran resources tailored for you`;
        }
        return 'Welcome to the CVMA Veterans Resources Portal';
    }

    get memberLevelBadge() {
        const levelClasses = {
            'Premium': 'slds-badge slds-badge_success',
            'Full Member': 'slds-badge slds-badge_info',
            'Associate': 'slds-badge slds-badge_warning',
            'Basic': 'slds-badge'
        };
        return levelClasses[this.memberLevel] || 'slds-badge';
    }

    get serviceBranchBadge() {
        if (!this.serviceBranch) return '';

        const branchClasses = {
            'Army': 'slds-badge slds-theme_success',
            'Navy': 'slds-badge slds-theme_info',
            'Air Force': 'slds-badge slds-theme_alt-inverse',
            'Marines': 'slds-badge slds-theme_error',
            'Coast Guard': 'slds-badge slds-theme_warning'
        };
        return branchClasses[this.serviceBranch] || 'slds-badge slds-theme_default';
    }

    // Priority resource categories for quick access
    get priorityCategories() {
        return this.resourceCategories.filter(category => category.priority <= 4);
    }

    get additionalCategories() {
        return this.resourceCategories.filter(category => category.priority > 4);
    }

    // Utility methods
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        }));
    }

    formatDate(dateString) {
        if (!dateString) return '';
        return new Date(dateString).toLocaleDateString();
    }

    // Help and support
    handleGetHelp() {
        this.showToast('Help', 'Connecting you with CVMA support resources...', 'info');

        // Dispatch event to show help modal or navigate to support
        this.dispatchEvent(new CustomEvent('requesthelp', {
            detail: {
                source: 'veterans-resources-portal',
                userLevel: this.memberLevel
            }
        }));
    }

    handleEmergencySupport() {
        this.showToast('Emergency Support', 'Redirecting to crisis support resources...', 'info');

        // Navigate to crisis support immediately
        this.navigateToCategory('crisis-support');
    }

    // Documentation system methods
    async loadMemberDocumentation() {
        try {
            const result = await getAvailableMemberDocumentation();
            this.memberDocumentationCategories = result || [];
        } catch (error) {
            console.error('Error loading member documentation:', error);
            this.memberDocumentationCategories = [];
        }
    }

    async handleRequestDocumentation(event) {
        const docCategory = event.target.dataset.category;
        const docTitle = event.target.dataset.title;

        if (!docCategory) {
            this.showToast('Error', 'Invalid documentation request', 'error');
            return;
        }

        this.documentationRequestStatus = 'Sending documentation...';

        try {
            // Get user email from profile or prompt
            const userEmail = this.getUserEmailForDocumentation();
            const userName = this.userProfile.name || 'CVMA Member';

            const result = await requestMemberDocumentation({
                category: docCategory,
                memberEmail: userEmail,
                memberName: userName
            });

            this.documentationRequestStatus = '';
            this.showToast('Documentation Request', result, 'success');

        } catch (error) {
            this.documentationRequestStatus = '';
            console.error('Error requesting documentation:', error);
            this.showToast('Documentation Error', 'Failed to request documentation. Please try again.', 'error');
        }
    }

    getUserEmailForDocumentation() {
        // For Experience Cloud, try to get user email from context
        // This would need to be enhanced based on your community user setup
        return 'member@cvma.org'; // Placeholder - replace with actual user email logic
    }

    get hasDocumentationCategories() {
        return this.memberDocumentationCategories && this.memberDocumentationCategories.length > 0;
    }

    get documentationSectionTitle() {
        return 'CVMA Member Documentation';
    }

    // User Story #34: Access control validation
    async validateUserAccess() {
        try {
            // Get current user ID - in Experience Cloud, this should be the current user
            const userId = this.recordId; // Assuming recordId is the user's Contact ID

            const result = await validateUserAccess({ userId: userId });

            if (result.success) {
                this.userAccessData = result;
                this.userPermissions = result.permissions || {};
                this.featureAccess = result.featureAccess || {};
                this.contentAccess = result.contentAccess || {};
                this.isAccessValidated = true;

                // Update UI based on access level
                this.updateUIForAccessLevel(result.accessLevel);
            } else {
                console.error('Access validation failed:', result.error);
                this.showToast('Access Error', 'Unable to validate user access', 'warning');
            }
        } catch (error) {
            console.error('Error validating user access:', error);
            this.isAccessValidated = false;
        }
    }

    updateUIForAccessLevel(accessLevel) {
        const level = accessLevel?.level || 'guest';

        // Update component behavior based on access level
        if (level === 'guest') {
            this.showDocumentationSection = false;
            this.enableSearch = this.contentAccess.publicContentOnly !== false;
        } else if (level === 'member') {
            this.showDocumentationSection = this.userPermissions.canSubmitReviews || false;
            this.enableSearch = true;
        } else if (level === 'admin') {
            this.showDocumentationSection = true;
            this.enableSearch = true;
        }
    }

    // User Story #35: Accessibility configuration
    async loadAccessibilityConfiguration() {
        try {
            const userId = this.recordId;
            const result = await getAccessibilityConfiguration({ userId: userId });

            if (result.success) {
                this.accessibilityConfig = result;
                this.accessibilityEnabled = true;

                // Apply accessibility settings to component
                this.applyAccessibilitySettings(result.accessibilitySettings);
            } else {
                console.error('Accessibility configuration failed:', result.error);
            }
        } catch (error) {
            console.error('Error loading accessibility configuration:', error);
            this.accessibilityEnabled = false;
        }
    }

    applyAccessibilitySettings(settings) {
        if (!settings) return;

        // Apply theme settings
        if (settings.theme === 'high-contrast') {
            this.template.host.classList.add('high-contrast-theme');
        }

        // Apply font size settings
        if (settings.fontSize === 'large') {
            this.template.host.classList.add('large-text');
        }

        // Apply motion preferences
        if (settings.animation === 'reduced') {
            this.template.host.classList.add('reduced-motion');
        }

        // Apply screen reader optimizations
        if (settings.screenReaderMode) {
            this.template.host.classList.add('screen-reader-optimized');
        }
    }

    // Enhanced getters with access control
    get canAccessVeteransPortal() {
        return this.featureAccess.canAccessVeteransPortal !== false;
    }

    get canViewMemberDirectory() {
        return this.featureAccess.canViewMemberDirectory || false;
    }

    get canAccessEventCalendar() {
        return this.featureAccess.canAccessEventCalendar !== false;
    }

    get canAccessMemberOnlyResources() {
        return this.featureAccess.canAccessMemberOnlyResources || false;
    }

    get canAccessVAServices() {
        return this.userPermissions.canAccessVAServices || false;
    }

    get canCreateCases() {
        return this.userPermissions.canCreateCases || false;
    }

    get canViewMemberContent() {
        return this.contentAccess.canViewMemberContent !== false;
    }

    get maxDownloads() {
        return this.contentAccess.maxDownloads || 3;
    }

    get allowedContentTypes() {
        return this.contentAccess.allowedContentTypes || ['Public Events', 'Community Resources'];
    }

    get accessLevelBadge() {
        const level = this.userAccessData.accessLevel?.level || 'guest';
        const levelClasses = {
            'admin': 'slds-badge slds-badge_error',
            'member': 'slds-badge slds-badge_success',
            'user': 'slds-badge slds-badge_info',
            'guest': 'slds-badge slds-badge_light'
        };
        return levelClasses[level] || 'slds-badge slds-badge_light';
    }

    get accessLevelDescription() {
        return this.userAccessData.accessLevel?.description || 'Guest Access';
    }

    get membershipRequired() {
        return this.contentAccess.membershipRequired || false;
    }

    // Enhanced welcome message with access level
    get enhancedWelcomeMessage() {
        const level = this.userAccessData.accessLevel?.level || 'guest';
        const userName = this.userProfile.name || 'Visitor';

        if (level === 'admin') {
            return `Welcome ${userName} - Administrator Access to CVMA Veterans Resources`;
        } else if (level === 'member') {
            return `Welcome ${userName} - Full Member Access to CVMA Veterans Resources`;
        } else if (level === 'user') {
            return `Welcome ${userName} - User Access to CVMA Veterans Resources`;
        } else {
            return `Welcome ${userName} - Guest Access to Public Veterans Resources`;
        }
    }

    // Accessibility helper methods
    get hasAccessibilitySupport() {
        return this.accessibilityEnabled && this.accessibilityConfig.success;
    }

    get screenReaderInstructions() {
        if (!this.hasAccessibilitySupport) return '';

        return 'Navigate using tab key. Use arrow keys within component sections. Press enter to activate buttons and links.';
    }

    get skipToMainContent() {
        return this.accessibilityConfig.screenReaderConfig?.skipLinks || false;
    }

    // Refresh data
    handleRefresh() {
        this.loadResourceData();
        this.showToast('Refresh', 'Veteran resources updated', 'success');
    }
}
