import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import generateTrainingPDF from '@salesforce/apex/CVMADocumentSharingController.generateTrainingPDF';

/**
 * CVMA Veteran Knowledge Base Component
 * 508-Compliant knowledge article system for Default Help Center
 * Designed for veteran self-help with accessibility focus
 */
export default class CvmaVeteranKnowledgeBase extends LightningElement {
    @api displayMode = 'search'; // search, article, category
    @api enableSearch = false;
    @api showCategories = false;
    @api showFeaturedArticles = false;
    @api maxSearchResults = 10;

    @track searchTerm = '';
    @track selectedCategory = '';
    @track selectedArticle = null;
    @track searchResults = [];
    @track isLoading = false;
    @track error = null;

    // Accessibility settings
    @track accessibilitySettings = {
        screenReaderMode: false,
        highContrast: false,
        largeText: false,
        reducedMotion: false,
        keyboardNavigation: true
    };

    // Enhanced knowledge categories for CVMA training system
    knowledgeCategories = [
        {
            id: 'ceb-training',
            title: 'CEB Officer Training',
            description: 'Leadership training for Chapter Executive Board members',
            icon: 'utility:knowledge_base',
            color: 'slds-icon-standard-calibration',
            articleCount: 12,
            priority: 1,
            audience: 'CEB_Officers',
            articles: [
                'officer-dashboard-guide',
                'member-management-procedures',
                'financial-oversight-training',
                'emergency-response-protocols'
            ]
        },
        {
            id: 'member-training',
            title: 'Member Training',
            description: 'Self-service training for CVMA members',
            icon: 'utility:groups',
            color: 'slds-icon-standard-opportunity',
            articleCount: 15,
            priority: 2,
            audience: 'Members',
            articles: [
                'getting-started-guide',
                'platform-navigation',
                'member-benefits-overview',
                'event-participation-guide'
            ]
        },
        {
            id: 'technical-docs',
            title: 'Technical Documentation',
            description: 'Developer and technical reference materials',
            icon: 'utility:setup',
            color: 'slds-icon-standard-code_playground',
            articleCount: 25,
            priority: 3,
            audience: 'Technical_Staff',
            articles: [
                'api-documentation',
                'development-guidelines',
                'deployment-procedures',
                'troubleshooting-guide'
            ]
        },
        {
            id: 'getting-started',
            title: 'Getting Started',
            description: 'Simple steps to access veteran resources',
            icon: 'utility:new',
            color: 'slds-icon-standard-opportunity',
            articleCount: 8,
            priority: 4,
            audience: 'All',
            articles: [
                'veteran-benefits-overview',
                'first-time-va-application',
                'required-documents-checklist',
                'contact-information-update'
            ]
        },
        {
            id: 'va-benefits',
            title: 'VA Benefits',
            description: 'Complete guide to VA benefits and services',
            icon: 'standard:opportunity',
            color: 'slds-icon-standard-opportunity',
            articleCount: 15,
            priority: 2,
            articles: [
                'disability-compensation-guide',
                'healthcare-enrollment',
                'education-benefits-gi-bill',
                'home-loan-program',
                'vocational-rehabilitation'
            ]
        },
        {
            id: 'mental-health',
            title: 'Mental Health Support',
            description: 'PTSD counseling and mental health resources',
            icon: 'standard:person_account',
            color: 'slds-icon-standard-person-account',
            articleCount: 12,
            priority: 3,
            articles: [
                'crisis-support-resources',
                'ptsd-treatment-options',
                'mental-health-appointments',
                'family-support-programs',
                'peer-support-groups'
            ]
        },
        {
            id: 'housing-assistance',
            title: 'Housing & Financial Aid',
            description: 'Emergency housing and financial assistance',
            icon: 'standard:home',
            color: 'slds-icon-standard-home',
            articleCount: 10,
            priority: 4,
            articles: [
                'emergency-housing-assistance',
                'va-home-loans',
                'financial-aid-programs',
                'utility-assistance',
                'homeless-veteran-services'
            ]
        },
        {
            id: 'accessibility',
            title: 'Accessibility Help',
            description: 'Using this site with assistive technology',
            icon: 'utility:accessibility',
            color: 'slds-icon-utility-accessibility',
            articleCount: 6,
            priority: 5,
            articles: [
                'screen-reader-guide',
                'keyboard-navigation',
                'voice-commands',
                'accessibility-settings',
                'mobile-accessibility'
            ]
        }
    ];

    // Featured knowledge articles with full accessibility content
    featuredArticles = [
        {
            id: 'veteran-benefits-overview',
            title: 'Veteran Benefits Overview - Simple 3-Step Guide',
            category: 'getting-started',
            description: 'Easy-to-follow guide to understanding your veteran benefits',
            readTime: '5 minutes',
            difficulty: 'Easy',
            lastUpdated: '2024-01-15',
            accessibilityCompliant: true,
            content: {
                summary: 'A comprehensive overview of veteran benefits available to all service members.',
                steps: [
                    {
                        title: 'Step 1: Verify Your Eligibility',
                        description: 'Check if you qualify for veteran benefits',
                        details: 'You may be eligible if you served in the active military, naval, or air service and were discharged under conditions other than dishonorable.',
                        actionItems: [
                            'Locate your DD-214 discharge papers',
                            'Visit VA.gov to check eligibility',
                            'Call 1-800-827-1000 for assistance'
                        ],
                        estimatedTime: '10-15 minutes'
                    },
                    {
                        title: 'Step 2: Gather Required Documents',
                        description: 'Collect necessary paperwork for your application',
                        details: 'Having the right documents ready will speed up your application process.',
                        actionItems: [
                            'DD-214 or other discharge documents',
                            'Social Security card',
                            'Marriage certificate (if applicable)',
                            'Birth certificates for dependents'
                        ],
                        estimatedTime: '20-30 minutes'
                    },
                    {
                        title: 'Step 3: Apply for Benefits',
                        description: 'Submit your application for veteran benefits',
                        details: 'You can apply online, by phone, mail, or in person at a VA facility.',
                        actionItems: [
                            'Apply online at VA.gov (recommended)',
                            'Call 1-800-827-1000 for phone application',
                            'Visit your nearest VA facility',
                            'Mail completed forms to regional office'
                        ],
                        estimatedTime: '30-45 minutes'
                    }
                ],
                resources: [
                    {
                        title: 'VA.gov Official Site',
                        url: 'https://va.gov',
                        description: 'Official VA website with all benefits information'
                    },
                    {
                        title: 'VA Help Line',
                        url: 'tel:1-800-827-1000',
                        description: 'Speak with a VA representative'
                    }
                ],
                accessibility: {
                    screenReaderNotes: 'This article is fully compatible with screen readers. All images have alt text.',
                    keyboardNavigation: 'Use Tab to navigate between sections, Enter to activate links.',
                    voiceCommands: 'Say "next step" or "previous step" to navigate between sections.'
                }
            }
        },
        {
            id: 'crisis-support-resources',
            title: 'Crisis Support - Immediate Help Available 24/7',
            category: 'mental-health',
            description: 'Emergency mental health resources for veterans in crisis',
            readTime: '2 minutes',
            difficulty: 'Easy',
            lastUpdated: '2024-01-15',
            accessibilityCompliant: true,
            urgent: true,
            content: {
                summary: 'If you\'re in crisis, immediate help is available 24 hours a day, 7 days a week.',
                emergencyContacts: [
                    {
                        name: 'Crisis Lifeline',
                        number: '988',
                        description: 'National Suicide Prevention Lifeline',
                        type: 'phone',
                        availability: '24/7'
                    },
                    {
                        name: 'Veterans Crisis Line',
                        number: '1-800-273-8255',
                        description: 'Press 1 for Veterans Crisis Line',
                        type: 'phone',
                        availability: '24/7'
                    },
                    {
                        name: 'Crisis Text Line',
                        number: '838255',
                        description: 'Text HOME to 838255',
                        type: 'text',
                        availability: '24/7'
                    },
                    {
                        name: 'Online Chat',
                        url: 'https://www.veteranscrisisline.net/get-help/chat',
                        description: 'Start confidential online chat',
                        type: 'web',
                        availability: '24/7'
                    }
                ],
                immediateSteps: [
                    'If you\'re in immediate danger, call 911',
                    'Remove access to means of self-harm',
                    'Contact one of the crisis resources above',
                    'Reach out to a trusted friend or family member',
                    'Go to your nearest emergency room if needed'
                ],
                followUpResources: [
                    'VA Mental Health Services',
                    'Vet Centers for readjustment counseling',
                    'CVMA Chapter peer support',
                    'Local mental health providers'
                ]
            }
        }
    ];

    // Search functionality
    searchArticles = [
        { id: 'va-benefits', title: 'VA Benefits Application Process', category: 'va-benefits', keywords: 'benefits application disability healthcare education' },
        { id: 'ptsd-help', title: 'PTSD Treatment and Support', category: 'mental-health', keywords: 'ptsd treatment counseling therapy' },
        { id: 'housing-emergency', title: 'Emergency Housing Assistance', category: 'housing-assistance', keywords: 'housing emergency homeless shelter' },
        { id: 'screen-reader', title: 'Using Screen Readers on This Site', category: 'accessibility', keywords: 'screen reader nvda jaws accessibility' },
        { id: 'keyboard-nav', title: 'Keyboard Navigation Guide', category: 'accessibility', keywords: 'keyboard navigation tab accessibility' }
    ];

    connectedCallback() {
        this.detectAccessibilitySettings();
        this.setupKeyboardNavigation();
        this.loadFeaturedArticles();
    }

    // Accessibility detection
    detectAccessibilitySettings() {
        // Detect screen reader
        this.accessibilitySettings.screenReaderMode = window.navigator.userAgent.includes('NVDA') ||
                                                    window.navigator.userAgent.includes('JAWS') ||
                                                    window.speechSynthesis !== undefined;

        // Detect user preferences
        if (window.matchMedia) {
            const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
            this.accessibilitySettings.reducedMotion = prefersReducedMotion.matches;

            const prefersHighContrast = window.matchMedia('(prefers-contrast: high)');
            this.accessibilitySettings.highContrast = prefersHighContrast.matches;
        }

        this.applyAccessibilitySettings();
    }

    setupKeyboardNavigation() {
        // Add keyboard event listeners
        this.template.addEventListener('keydown', this.handleKeyboardNavigation.bind(this));
    }

    loadFeaturedArticles() {
        // Load featured articles based on user context
        this.isLoading = true;

        // Simulate loading delay
        setTimeout(() => {
            this.isLoading = false;
        }, 500);
    }

    // Event handlers
    handleSearch(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm.length >= 2) {
            this.performSearch();
        } else {
            this.searchResults = [];
        }
    }

    handleCategorySelection(event) {
        this.selectedCategory = event.currentTarget.dataset.category;
        this.displayMode = 'category';
        this.announceToScreenReader(`Viewing ${this.selectedCategory} articles`);
    }

    handleArticleSelection(event) {
        const articleId = event.currentTarget.dataset.article;
        this.selectedArticle = this.featuredArticles.find(article => article.id === articleId);
        this.displayMode = 'article';
        this.announceToScreenReader(`Viewing article: ${this.selectedArticle.title}`);
        this.focusArticleContent();
    }

    handleBackToSearch() {
        this.displayMode = 'search';
        this.selectedArticle = null;
        this.selectedCategory = '';
        this.announceToScreenReader('Returned to knowledge base search');
    }

    handleAccessibilityToggle(event) {
        const setting = event.currentTarget.dataset.setting;
        this.accessibilitySettings[setting] = !this.accessibilitySettings[setting];
        this.applyAccessibilitySettings();
        this.announceToScreenReader(`${setting} ${this.accessibilitySettings[setting] ? 'enabled' : 'disabled'}`);
    }

    // Search functionality
    performSearch() {
        const term = this.searchTerm.toLowerCase();
        this.searchResults = this.searchArticles.filter(article =>
            article.title.toLowerCase().includes(term) ||
            article.keywords.toLowerCase().includes(term) ||
            article.category.toLowerCase().includes(term)
        ).slice(0, this.maxSearchResults);

        this.announceToScreenReader(`Found ${this.searchResults.length} articles for ${this.searchTerm}`);
    }

    // Keyboard navigation
    handleKeyboardNavigation(event) {
        const focusableElements = this.template.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );

        switch(event.key) {
            case 'Enter':
                if (document.activeElement.tagName === 'BUTTON') {
                    event.preventDefault();
                    document.activeElement.click();
                }
                break;
            case 'Escape':
                if (this.displayMode === 'article') {
                    this.handleBackToSearch();
                }
                break;
            case '/':
                if (event.ctrlKey) {
                    event.preventDefault();
                    const searchInput = this.template.querySelector('.search-input');
                    if (searchInput) {
                        searchInput.focus();
                    }
                }
                break;
        }
    }

    // Accessibility utilities
    applyAccessibilitySettings() {
        const container = this.template.querySelector('.knowledge-base-container');
        if (container) {
            container.classList.toggle('high-contrast', this.accessibilitySettings.highContrast);
            container.classList.toggle('large-text', this.accessibilitySettings.largeText);
            container.classList.toggle('reduced-motion', this.accessibilitySettings.reducedMotion);
            container.classList.toggle('screen-reader-mode', this.accessibilitySettings.screenReaderMode);
        }
    }

    announceToScreenReader(message) {
        if (this.accessibilitySettings.screenReaderMode) {
            const announcement = document.createElement('div');
            announcement.setAttribute('aria-live', 'polite');
            announcement.setAttribute('aria-atomic', 'true');
            announcement.classList.add('sr-only');
            announcement.textContent = message;

            this.template.appendChild(announcement);

            setTimeout(() => {
                if (announcement.parentNode) {
                    announcement.parentNode.removeChild(announcement);
                }
            }, 1000);
        }
    }

    focusArticleContent() {
        setTimeout(() => {
            const articleTitle = this.template.querySelector('.article-title');
            if (articleTitle) {
                articleTitle.focus();
            }
        }, 100);
    }

    // PDF Generation for training materials
    async generateTrainingPDF(articleId) {
        try {
            this.isLoading = true;

            const article = this.featuredArticles.find(art => art.id === articleId);
            if (!article) {
                throw new Error('Article not found');
            }

            // Convert article content to markdown
            const markdownContent = this.convertToMarkdown(article);

            // Determine target audience based on category
            let targetAudience = 'Members';
            const category = this.knowledgeCategories.find(cat => cat.id === article.category);
            if (category && category.audience) {
                targetAudience = category.audience;
            }

            // Generate PDF using existing CVMADocumentSharingController
            const contentDocumentId = await generateTrainingPDF({
                documentName: article.title,
                markdownContent: markdownContent,
                targetAudience: targetAudience
            });

            // Open the generated PDF
            this.openContentDocument(contentDocumentId);

            this.showToast('Success', `${article.title} PDF generated successfully`, 'success');

        } catch (error) {
            console.error('Error generating PDF:', error);
            this.showToast('Error', 'Failed to generate PDF. Please try again.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Convert article content to markdown format
    convertToMarkdown(article) {
        let markdown = `# ${article.title}\n\n`;
        markdown += `**Category:** ${article.category}\n`;
        markdown += `**Read Time:** ${article.readTime}\n`;
        markdown += `**Last Updated:** ${article.lastUpdated}\n\n`;

        if (article.content.summary) {
            markdown += `## Summary\n${article.content.summary}\n\n`;
        }

        if (article.content.steps) {
            markdown += `## Steps\n\n`;
            article.content.steps.forEach((step, index) => {
                markdown += `### ${step.title}\n`;
                markdown += `${step.description}\n\n`;
                markdown += `${step.details}\n\n`;

                if (step.actionItems) {
                    markdown += `**Action Items:**\n`;
                    step.actionItems.forEach(item => {
                        markdown += `- ${item}\n`;
                    });
                    markdown += `\n`;
                }

                if (step.estimatedTime) {
                    markdown += `**Estimated Time:** ${step.estimatedTime}\n\n`;
                }
            });
        }

        if (article.content.resources) {
            markdown += `## Resources\n\n`;
            article.content.resources.forEach(resource => {
                markdown += `- [${resource.title}](${resource.url}): ${resource.description}\n`;
            });
        }

        return markdown;
    }

    // Open content document in new tab
    openContentDocument(contentDocumentId) {
        const baseUrl = window.location.origin;
        const documentUrl = `${baseUrl}/sfc/servlet.shepherd/document/download/${contentDocumentId}`;
        window.open(documentUrl, '_blank');
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

    // Getters for template rendering
    get isSearchMode() {
        return this.displayMode === 'search';
    }

    get isCategoryMode() {
        return this.displayMode === 'category';
    }

    get isArticleMode() {
        return this.displayMode === 'article';
    }

    get selectedCategoryData() {
        return this.knowledgeCategories.find(cat => cat.id === this.selectedCategory);
    }

    get categoryArticles() {
        if (!this.selectedCategoryData) return [];
        return this.featuredArticles.filter(article =>
            article.category === this.selectedCategory
        );
    }

    get hasSearchResults() {
        return this.searchResults.length > 0;
    }

    get searchResultsText() {
        return `${this.searchResults.length} article${this.searchResults.length !== 1 ? 's' : ''} found`;
    }

    get containerClass() {
        let classes = 'knowledge-base-container';
        if (this.accessibilitySettings.highContrast) classes += ' high-contrast';
        if (this.accessibilitySettings.largeText) classes += ' large-text';
        if (this.accessibilitySettings.reducedMotion) classes += ' reduced-motion';
        if (this.accessibilitySettings.screenReaderMode) classes += ' screen-reader-mode';
        return classes;
    }

    get searchPlaceholderText() {
        return 'Search veteran resources... (Press Ctrl+/ to focus)';
    }

    get articleStepsWithNumbers() {
        if (!this.selectedArticle?.content?.steps) return [];
        return this.selectedArticle.content.steps.map((step, index) => ({
            ...step,
            stepNumber: index + 1
        }));
    }
}
