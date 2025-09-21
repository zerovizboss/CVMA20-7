import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_LEVEL_FIELD from '@salesforce/schema/Contact.Level__c';
import CONTACT_SERVICE_BRANCH_FIELD from '@salesforce/schema/Contact.Military_Service_Branch__c';

import getVeteranResourceCategories from '@salesforce/apex/CVMAVeteranResourcesController.getVeteranResourceCategories';
import searchVeteranResources from '@salesforce/apex/CVMAVeteranResourcesController.searchVeteranResources';
import getPersonalizedRecommendations from '@salesforce/apex/CVMAVeteranResourcesController.getPersonalizedRecommendations';

export default class CvmaVeteranResourcesPortal extends LightningElement {
    @api portalMode = 'landing'; // landing, search, detail
    @api showCategories = true;
    @api enableSearch = true;
    @api recordId; // Current user's contact ID

    @track isLoading = true;
    @track resourceCategories = [];
    @track searchResults = [];
    @track personalizedRecommendations = [];
    @track searchTerm = '';
    @track selectedCategory = '';
    @track activeView = 'overview';
    @track error = null;

    // User profile information
    @track userProfile = {};
    @track memberLevel = '';
    @track serviceBranch = '';

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
        fields: [CONTACT_NAME_FIELD, CONTACT_LEVEL_FIELD, CONTACT_SERVICE_BRANCH_FIELD]
    })
    wiredContact({ data, error }) {
        if (data) {
            this.userProfile = {
                name: data.fields.Name.value,
                level: data.fields.Level__c.value || 'Basic',
                serviceBranch: data.fields.Military_Service_Branch__c.value || ''
            };
            this.memberLevel = this.userProfile.level;
            this.serviceBranch = this.userProfile.serviceBranch;
        } else if (error) {
            console.error('Error loading user profile:', error);
        }
    }

    connectedCallback() {
        this.loadResourceData();
    }

    async loadResourceData() {
        this.isLoading = true;
        this.error = null;

        try {
            // Load resource categories
            await this.loadResourceCategories();

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
            const categoryData = await getVeteranResourceCategories();

            // Merge API data with local configuration
            this.resourceCategories = this.resourceCategoryConfig.map(category => {
                const apiCategory = categoryData.find(item => item.categoryId === category.id);
                return {
                    ...category,
                    resourceCount: apiCategory ? apiCategory.resourceCount : 0,
                    featuredResources: apiCategory ? apiCategory.featuredResources : [],
                    lastUpdated: apiCategory ? apiCategory.lastUpdated : new Date().toISOString()
                };
            });

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
            const recommendations = await getPersonalizedRecommendations({
                contactId: this.recordId,
                memberLevel: this.memberLevel,
                serviceBranch: this.serviceBranch
            });

            this.personalizedRecommendations = recommendations || [];

        } catch (error) {
            console.error('Error loading personalized recommendations:', error);
            this.personalizedRecommendations = this.getDefaultRecommendations();
        }
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
            const results = await searchVeteranResources({
                searchTerm: this.searchTerm,
                category: this.selectedCategory,
                memberLevel: this.memberLevel
            });

            this.searchResults = results || [];
            this.activeView = 'search';

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
            const results = await searchVeteranResources({
                searchTerm: '',
                category: categoryId,
                memberLevel: this.memberLevel
            });

            this.searchResults = results || [];
            this.activeView = 'category';

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

    // Refresh data
    handleRefresh() {
        this.loadResourceData();
        this.showToast('Refresh', 'Veteran resources updated', 'success');
    }
}
