import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Help Center Portal - Optimized for Default Help Center Site
 * Purpose: Search-driven support and accessibility help interface
 * Site: https://cvma20-7-dev-ed.develop.my.site.com/defaulthelpcenter12Jun
 */
export default class CvmaHelpCenterPortal extends LightningElement {
    @api displayMode = 'search-first'; // search-first, category-first, accessibility-first
    @api enableAdvancedSearch = false;
    @api showQuickSolutions = false;
    @api prioritizeAccessibility = false;

    @track searchTerm = '';
    @track selectedCategory = '';
    @track searchResults = [];
    @track isSearching = false;

    // Help categories optimized for self-service support
    helpCategories = [
        {
            id: 'getting-started',
            title: 'Getting Started',
            description: 'Basic platform navigation and first steps',
            icon: 'standard:setup_assistant_guide',
            articles: 12,
            color: 'success'
        },
        {
            id: 'account-profile',
            title: 'Account & Profile',
            description: 'Manage your account settings and profile information',
            icon: 'standard:user',
            articles: 8,
            color: 'brand'
        },
        {
            id: 'troubleshooting',
            title: 'Troubleshooting',
            description: 'Common issues and step-by-step solutions',
            icon: 'standard:problem',
            articles: 15,
            color: 'warning'
        },
        {
            id: 'accessibility',
            title: 'Accessibility Support',
            description: 'Accessibility features and accommodation requests',
            icon: 'standard:connected_apps',
            articles: 6,
            color: 'info'
        }
    ];

    // Quick solutions for immediate help
    quickSolutions = [
        {
            id: 'password-reset',
            title: 'Reset Password',
            description: 'Can\'t access your account?',
            icon: 'standard:password',
            action: 'password-reset'
        },
        {
            id: 'contact-support',
            title: 'Contact Support',
            description: 'Need to speak with someone?',
            icon: 'standard:live_chat',
            action: 'contact-support'
        },
        {
            id: 'accessibility-request',
            title: 'Request Accommodation',
            description: 'Need accessibility assistance?',
            icon: 'standard:connected_apps',
            action: 'accessibility-request'
        },
        {
            id: 'technical-issue',
            title: 'Report Technical Issue',
            description: 'Something not working correctly?',
            icon: 'standard:bug',
            action: 'technical-issue'
        }
    ];

    // Popular help articles
    popularArticles = [
        {
            id: 'login-issues',
            title: 'Solving Login Problems',
            category: 'troubleshooting',
            views: 234,
            rating: 4.8
        },
        {
            id: 'update-profile',
            title: 'How to Update Your Profile',
            category: 'account-profile',
            views: 189,
            rating: 4.9
        },
        {
            id: 'accessibility-features',
            title: 'Available Accessibility Features',
            category: 'accessibility',
            views: 156,
            rating: 4.7
        },
        {
            id: 'mobile-access',
            title: 'Accessing on Mobile Devices',
            category: 'getting-started',
            views: 143,
            rating: 4.6
        }
    ];

    connectedCallback() {
        this.initializeHelpCenter();
    }

    initializeHelpCenter() {
        // Set up initial state based on display mode
        if (this.displayMode === 'accessibility-first') {
            this.selectedCategory = 'accessibility';
        }
    }

    // Handle search input
    handleSearchInput(event) {
        this.searchTerm = event.target.value;

        // Debounce search to avoid excessive API calls
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.performSearch();
        }, 300);
    }

    // Perform search functionality
    async performSearch() {
        if (this.searchTerm.length < 2) {
            this.searchResults = [];
            return;
        }

        this.isSearching = true;

        try {
            // Simulate search delay and results
            await new Promise(resolve => setTimeout(resolve, 500));

            // Mock search results based on search term
            this.searchResults = this.generateSearchResults(this.searchTerm);

            // Track search for analytics
            this.trackSearch(this.searchTerm, this.searchResults.length);

        } catch (error) {
            this.showToast('Error', 'Search failed. Please try again.', 'error');
        } finally {
            this.isSearching = false;
        }
    }

    // Generate mock search results
    generateSearchResults(searchTerm) {
        const term = searchTerm.toLowerCase();
        const mockResults = [];

        // Add relevant results based on search term
        if (term.includes('password') || term.includes('login')) {
            mockResults.push({
                id: 'password-help',
                title: 'Password and Login Help',
                category: 'troubleshooting',
                snippet: 'Step-by-step guide to resolving password and login issues.',
                relevance: 95
            });
        }

        if (term.includes('accessibility') || term.includes('screen reader')) {
            mockResults.push({
                id: 'accessibility-guide',
                title: 'Accessibility Features Guide',
                category: 'accessibility',
                snippet: 'Complete guide to accessibility features and support options.',
                relevance: 90
            });
        }

        if (term.includes('profile') || term.includes('update')) {
            mockResults.push({
                id: 'profile-update',
                title: 'Update Your Profile Information',
                category: 'account-profile',
                snippet: 'How to update and manage your profile information.',
                relevance: 85
            });
        }

        // Add some general results
        mockResults.push({
            id: 'general-help',
            title: 'General Platform Help',
            category: 'getting-started',
            snippet: 'Basic platform navigation and common tasks.',
            relevance: 60
        });

        return mockResults.sort((a, b) => b.relevance - a.relevance);
    }

    // Handle category selection
    handleCategorySelect(event) {
        const categoryId = event.currentTarget.dataset.categoryId;
        this.selectedCategory = categoryId;

        // Clear search when category is selected
        this.searchTerm = '';
        this.searchResults = [];

        // Track category selection
        this.trackCategorySelection(categoryId);
    }

    // Handle quick solution selection
    handleQuickSolution(event) {
        const action = event.currentTarget.dataset.action;

        switch(action) {
            case 'password-reset':
                this.initiatePasswordReset();
                break;
            case 'contact-support':
                this.openContactSupport();
                break;
            case 'accessibility-request':
                this.openAccessibilityRequest();
                break;
            case 'technical-issue':
                this.openTechnicalIssueReport();
                break;
        }
    }

    // Quick solution handlers
    initiatePasswordReset() {
        // Navigate to password reset or open modal
        this.dispatchEvent(new CustomEvent('passwordreset', {
            detail: { action: 'initiate' },
            bubbles: true
        }));
    }

    openContactSupport() {
        // Open live chat or contact form
        this.dispatchEvent(new CustomEvent('contactsupport', {
            detail: { action: 'open' },
            bubbles: true
        }));
    }

    openAccessibilityRequest() {
        // Open accessibility accommodation request form
        this.dispatchEvent(new CustomEvent('accessibilityrequest', {
            detail: { action: 'open' },
            bubbles: true
        }));
    }

    openTechnicalIssueReport() {
        // Open technical issue reporting form
        this.dispatchEvent(new CustomEvent('technicalissue', {
            detail: { action: 'report' },
            bubbles: true
        }));
    }

    // Analytics tracking
    trackSearch(searchTerm, resultCount) {
        this.dispatchEvent(new CustomEvent('searchtracking', {
            detail: {
                searchTerm: searchTerm,
                resultCount: resultCount,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));
    }

    trackCategorySelection(categoryId) {
        this.dispatchEvent(new CustomEvent('categorytracking', {
            detail: {
                categoryId: categoryId,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));
    }

    // Computed properties
    get hasSearchResults() {
        return this.searchResults.length > 0;
    }

    get showCategories() {
        return !this.searchTerm || this.searchResults.length === 0;
    }

    get selectedCategoryData() {
        return this.helpCategories.find(cat => cat.id === this.selectedCategory);
    }

    get searchPlaceholder() {
        return this.displayMode === 'accessibility-first'
            ? 'Search accessibility help...'
            : 'Search help articles...';
    }

    // Show toast notification
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
