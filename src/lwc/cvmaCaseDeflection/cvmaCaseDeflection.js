import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * CVMA Case Deflection Component
 * Bridges Knowledge Base articles with Case Management for self-service support
 * Designed for Experience Cloud guest users and community members
 */
export default class CvmaCaseDeflection extends LightningElement {
    @api showSuggestedArticles = false;
    @api maxSuggestions = 5;
    @api headerTitle = 'Need Help? Try These Resources First';
    @api enableCaseCreation = false;

    @track searchTerm = '';
    @track suggestedArticles = [];
    @track showCaseForm = false;
    @track isLoading = false;

    // Mock knowledge articles - in production, these would come from Knowledge__kav
    knowledgeArticles = [
        {
            id: 'ka001',
            title: 'How to Reset Your Password',
            summary: 'Step-by-step guide to reset your CVMA portal password',
            category: 'Account Access',
            helpfulness: 95,
            keywords: 'password reset login access account'
        },
        {
            id: 'ka002',
            title: 'Updating Your Member Profile',
            summary: 'Learn how to update your contact information and preferences',
            category: 'Profile Management',
            helpfulness: 88,
            keywords: 'profile update contact information email phone'
        },
        {
            id: 'ka003',
            title: 'Event Registration Process',
            summary: 'How to register for CVMA events and rides',
            category: 'Events',
            helpfulness: 92,
            keywords: 'event registration ride signup RSVP'
        },
        {
            id: 'ka004',
            title: 'Crisis Support Resources',
            summary: 'Emergency mental health and crisis support for veterans',
            category: 'Crisis Support',
            helpfulness: 98,
            urgent: true,
            keywords: 'crisis emergency mental health support 988'
        },
        {
            id: 'ka005',
            title: 'Membership Dues Payment',
            summary: 'How to pay your annual chapter dues online',
            category: 'Financial',
            helpfulness: 85,
            keywords: 'dues payment financial pay membership'
        }
    ];

    connectedCallback() {
        // Set default values for boolean properties (LWC requirement)
        if (this.showSuggestedArticles === false && this.enableCaseCreation === false) {
            this.showSuggestedArticles = true;
            this.enableCaseCreation = true;
        }
        this.loadDefaultSuggestions();
    }

    loadDefaultSuggestions() {
        // Show top helpful articles by default
        this.suggestedArticles = this.knowledgeArticles
            .sort((a, b) => b.helpfulness - a.helpfulness)
            .slice(0, this.maxSuggestions);
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value.toLowerCase();

        if (this.searchTerm.length >= 2) {
            this.performSearch();
        } else if (this.searchTerm.length === 0) {
            this.loadDefaultSuggestions();
        }
    }

    performSearch() {
        // Filter articles based on search term
        this.suggestedArticles = this.knowledgeArticles
            .filter(article =>
                article.title.toLowerCase().includes(this.searchTerm) ||
                article.summary.toLowerCase().includes(this.searchTerm) ||
                article.keywords.toLowerCase().includes(this.searchTerm) ||
                article.category.toLowerCase().includes(this.searchTerm)
            )
            .sort((a, b) => {
                // Prioritize urgent articles, then by helpfulness
                if (a.urgent && !b.urgent) return -1;
                if (!a.urgent && b.urgent) return 1;
                return b.helpfulness - a.helpfulness;
            })
            .slice(0, this.maxSuggestions);
    }

    handleArticleClick(event) {
        const articleId = event.currentTarget.dataset.articleId;
        const article = this.knowledgeArticles.find(a => a.id === articleId);

        if (article) {
            // In production, this would navigate to the Knowledge Article
            this.showToast(
                'Article Selected',
                `Opening: ${article.title}`,
                'info'
            );

            // Dispatch custom event for parent components
            this.dispatchEvent(new CustomEvent('articleselected', {
                detail: { articleId: articleId, article: article }
            }));
        }
    }

    handleCreateCase() {
        if (!this.enableCaseCreation) {
            this.showToast(
                'Case Creation Disabled',
                'Please contact support directly for assistance',
                'info'
            );
            return;
        }

        this.showCaseForm = true;
    }

    handleCaseFormCancel() {
        this.showCaseForm = false;
    }

    handleCaseFormSubmit() {
        // In production, this would create a Case record
        this.isLoading = true;

        setTimeout(() => {
            this.isLoading = false;
            this.showCaseForm = false;
            this.showToast(
                'Case Created',
                'Your support request has been submitted. Case #12345',
                'success'
            );
        }, 1500);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Getters
    get hasSearchResults() {
        return this.suggestedArticles.length > 0;
    }

    get showNoResults() {
        return this.searchTerm.length >= 2 && this.suggestedArticles.length === 0;
    }

    get searchPlaceholder() {
        return 'Search help articles...';
    }

    get createCaseButtonLabel() {
        return this.hasSearchResults ? "Still need help? Create a case" : "Create a support case";
    }
}
