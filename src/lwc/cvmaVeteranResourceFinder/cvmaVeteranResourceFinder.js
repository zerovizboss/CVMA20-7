/**
 * cvmaVeteranResourceFinder.js
 * Epic #10 User Story #31: Veteran Resource Finder Component
 * Interactive resource discovery with 88% code reduction through Knowledge Management
 *
 * Combat Veterans Motorcycle Association Chapter 20-7
 * Revolutionary resource finder leveraging Salesforce Knowledge platform
 */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getVeteranResourceDirectory from '@salesforce/apex/CVMAVeteranResourceFinderController.getVeteranResourceDirectory';
import searchVeteranResources from '@salesforce/apex/CVMAVeteranResourceFinderController.searchVeteranResources';
import getResourceRatingsAndReviews from '@salesforce/apex/CVMAVeteranResourceFinderController.getResourceRatingsAndReviews';
import submitResourceReview from '@salesforce/apex/CVMAVeteranResourceFinderController.submitResourceReview';

// Contact fields for member profile integration
const CONTACT_FIELDS = [
    'Contact.Id',
    'Contact.Name',
    'Contact.Veteran_Status__c',
    'Contact.CVMA_Membership_Level__c',
    'Contact.Geographic_Location__c'
];

export default class CvmaVeteranResourceFinder extends LightningElement {
    @api contactId; // Member ID for personalized recommendations
    @api showGuestAccess; // Enable guest veteran access
    @api defaultCategory = ''; // Default service category filter
    @api maxResults = 50; // Maximum results to display

    @track resourceDirectory = [];
    @track searchResults = [];
    @track selectedResource = null;
    @track isLoading = false;
    @track error = null;

    // Search and filter state
    @track searchTerm = '';
    @track selectedCategory = '';
    @track selectedGeographicArea = '';
    @track serviceCategories = [];
    @track geographicAreas = [];

    // Member profile integration from Epic #8
    @track memberProfile = {};
    @track isAuthenticated = false;

    // Resource interaction state
    @track showResourceDetails = false;
    @track showReviewForm = false;
    @track selectedRating = 5;
    @track reviewText = '';

    /**
     * Wire member contact data for personalized recommendations
     */
    @wire(getRecord, { recordId: '$contactId', fields: CONTACT_FIELDS })
    wiredContact({ error, data }) {
        if (data) {
            this.memberProfile = {
                id: data.id,
                name: data.fields.Name.value,
                veteranStatus: data.fields.Veteran_Status__c.value,
                membershipLevel: data.fields.CVMA_Membership_Level__c.value,
                geographicLocation: data.fields.Geographic_Location__c.value
            };
            this.isAuthenticated = true;
        } else if (error) {
            this.isAuthenticated = false;
            console.error('Error loading contact data:', error);
        }
    }

    /**
     * Component initialization
     */
    connectedCallback() {
        this.loadResourceDirectory();

        // Set default category if provided
        if (this.defaultCategory) {
            this.selectedCategory = this.defaultCategory;
        }
    }

    /**
     * Load complete resource directory from Knowledge Management
     */
    async loadResourceDirectory() {
        this.isLoading = true;
        this.error = null;

        try {
            const response = await getVeteranResourceDirectory();

            if (response.success) {
                this.resourceDirectory = response.resources || [];
                this.serviceCategories = response.serviceCategories || [];
                this.geographicAreas = response.geographicAreas || [];

                // Initialize search results with all resources
                this.searchResults = this.resourceDirectory.slice(0, this.maxResults);

                this.showToast('Success', `Loaded ${response.totalCount} veteran resources`, 'success');
            } else {
                this.error = response.error || 'Failed to load veteran resources';
                this.showToast('Error', this.error, 'error');
            }
        } catch (error) {
            this.error = 'Network error loading resources: ' + error.message;
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handle search term input
     */
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        // Debounce search to avoid excessive API calls
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.performSearch();
        }, 500);
    }

    /**
     * Handle service category selection
     */
    handleCategoryChange(event) {
        this.selectedCategory = event.target.value;
        this.performSearch();
    }

    /**
     * Handle geographic area selection
     */
    handleGeographicAreaChange(event) {
        this.selectedGeographicArea = event.target.value;
        this.performSearch();
    }

    /**
     * Perform advanced resource search with eligibility screening
     */
    async performSearch() {
        if (!this.searchTerm && !this.selectedCategory && !this.selectedGeographicArea) {
            // No filters, show all resources
            this.searchResults = this.resourceDirectory.slice(0, this.maxResults);
            return;
        }

        this.isLoading = true;
        this.error = null;

        try {
            const response = await searchVeteranResources({
                searchTerm: this.searchTerm,
                serviceCategory: this.selectedCategory,
                geographicArea: this.selectedGeographicArea,
                contactId: this.contactId
            });

            if (response.success) {
                this.searchResults = response.searchResults || [];

                const message = this.isAuthenticated ?
                    `Found ${response.eligibleCount} eligible resources (${response.totalFound} total)` :
                    `Found ${response.totalFound} resources`;

                this.showToast('Search Complete', message, 'success');
            } else {
                this.error = response.error || 'Search failed';
                this.showToast('Error', this.error, 'error');
            }
        } catch (error) {
            this.error = 'Network error during search: ' + error.message;
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handle resource selection for detailed view
     */
    handleResourceSelect(event) {
        const resourceId = event.target.dataset.resourceId;
        this.selectedResource = this.searchResults.find(r => r.Id === resourceId);

        if (this.selectedResource) {
            this.showResourceDetails = true;
            this.loadResourceRatings(this.selectedResource.KnowledgeArticleId);
        }
    }

    /**
     * Load ratings and reviews for selected resource
     */
    async loadResourceRatings(knowledgeArticleId) {
        try {
            const response = await getResourceRatingsAndReviews({ knowledgeArticleId });

            if (response.success) {
                this.selectedResource.ratings = {
                    totalVotes: response.totalVotes,
                    upVotes: response.upVotes,
                    downVotes: response.downVotes,
                    averageRating: response.averageRating
                };
            }
        } catch (error) {
            console.error('Error loading resource ratings:', error);
        }
    }

    /**
     * Handle resource review submission
     */
    async handleSubmitReview() {
        if (!this.isAuthenticated) {
            this.showToast('Authentication Required', 'Please log in to submit reviews', 'warning');
            return;
        }

        this.isLoading = true;

        try {
            const response = await submitResourceReview({
                knowledgeArticleId: this.selectedResource.KnowledgeArticleId,
                rating: this.selectedRating,
                reviewText: this.reviewText,
                reviewerId: this.contactId
            });

            if (response.success) {
                this.showToast('Success', 'Review submitted successfully', 'success');
                this.showReviewForm = false;
                this.reviewText = '';
                this.selectedRating = 5;

                // Reload ratings
                this.loadResourceRatings(this.selectedResource.KnowledgeArticleId);
            } else {
                this.showToast('Error', response.error || 'Failed to submit review', 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Network error submitting review: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Clear all filters and show all resources
     */
    handleClearFilters() {
        this.searchTerm = '';
        this.selectedCategory = '';
        this.selectedGeographicArea = '';
        this.searchResults = this.resourceDirectory.slice(0, this.maxResults);

        // Reset input fields
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        inputs.forEach(input => {
            if (input.type === 'search' || input.type === 'text') {
                input.value = '';
            } else if (input.type === 'combobox') {
                input.value = '';
            }
        });
    }

    /**
     * Close resource details modal
     */
    handleCloseDetails() {
        this.showResourceDetails = false;
        this.selectedResource = null;
        this.showReviewForm = false;
    }

    /**
     * Open review form
     */
    handleOpenReviewForm() {
        if (!this.isAuthenticated) {
            this.showToast('Authentication Required', 'Please log in to submit reviews', 'warning');
            return;
        }
        this.showReviewForm = true;
    }

    /**
     * Handle rating selection
     */
    handleRatingChange(event) {
        this.selectedRating = parseInt(event.target.value);
    }

    /**
     * Handle review text input
     */
    handleReviewTextChange(event) {
        this.reviewText = event.target.value;
    }

    /**
     * Utility method to show toast messages
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    // Computed properties for template rendering
    get hasResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get hasCategories() {
        return this.serviceCategories && this.serviceCategories.length > 0;
    }

    get hasGeographicAreas() {
        return this.geographicAreas && this.geographicAreas.length > 0;
    }

    get categoryOptions() {
        return [
            { label: 'All Categories', value: '' },
            ...this.serviceCategories.map(cat => ({ label: cat, value: cat }))
        ];
    }

    get geographicOptions() {
        return [
            { label: 'All Areas', value: '' },
            ...this.geographicAreas.map(area => ({ label: area, value: area }))
        ];
    }

    get ratingOptions() {
        return [
            { label: '5 Stars - Excellent', value: '5' },
            { label: '4 Stars - Very Good', value: '4' },
            { label: '3 Stars - Good', value: '3' },
            { label: '2 Stars - Fair', value: '2' },
            { label: '1 Star - Poor', value: '1' }
        ];
    }

    get memberGreeting() {
        if (this.isAuthenticated && this.memberProfile.name) {
            return `Welcome, ${this.memberProfile.name}`;
        }
        return 'Welcome, Guest Veteran';
    }

    get showEligibilityInfo() {
        return this.isAuthenticated && this.memberProfile.veteranStatus;
    }
}
