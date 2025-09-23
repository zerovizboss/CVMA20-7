import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Technical Documentation Portal - Optimized for Main Technical Site
 * Purpose: Reference documentation with advanced search and filtering
 * Site: https://cvma20-7-dev-ed.develop.my.site.com (technical section)
 */
export default class CvmaTechnicalDocsPortal extends LightningElement {
    @api displayMode = 'reference'; // reference, development, api-focused
    @api enableAdvancedFiltering = false;
    @api showCodeExamples = false;
    @api enableDocumentPreview = false;

    @track selectedDocType = '';
    @track searchTerm = '';
    @track selectedTags = [];
    @track filteredDocs = [];
    @track isLoading = false;

    // Technical documentation categories
    documentTypes = [
        {
            id: 'epic-docs',
            title: 'Epic Documentation',
            description: 'Complete Epic implementation details and user stories',
            icon: 'standard:record_collection',
            count: 43,
            color: 'brand',
            tags: ['implementation', 'user-stories', 'business-logic']
        },
        {
            id: 'api-docs',
            title: 'API Documentation',
            description: 'Integration guides, endpoints, and API references',
            icon: 'standard:integration',
            count: 15,
            color: 'success',
            tags: ['api', 'integration', 'endpoints', 'authentication']
        },
        {
            id: 'development-guides',
            title: 'Development Guides',
            description: 'Architecture patterns, coding standards, and best practices',
            icon: 'standard:code_playground',
            count: 25,
            color: 'warning',
            tags: ['architecture', 'patterns', 'standards', 'best-practices']
        },
        {
            id: 'deployment-runbooks',
            title: 'Deployment Runbooks',
            description: 'Operations procedures, deployment guides, and troubleshooting',
            icon: 'standard:environment_hub',
            count: 18,
            color: 'error',
            tags: ['deployment', 'operations', 'troubleshooting', 'procedures']
        }
    ];

    // Available filter tags
    availableTags = [
        'implementation', 'user-stories', 'business-logic', 'api', 'integration',
        'endpoints', 'authentication', 'architecture', 'patterns', 'standards',
        'best-practices', 'deployment', 'operations', 'troubleshooting', 'procedures',
        'salesforce', 'lwc', 'apex', 'flows', 'security', 'performance', 'testing'
    ];

    // Recently updated documents
    recentlyUpdated = [
        {
            id: 'epic-10-phase-3',
            title: 'Epic #10 Phase 3 Implementation',
            type: 'epic-docs',
            lastModified: '2025-01-23',
            author: 'Claude WX',
            tags: ['epic-10', 'implementation', 'accessibility']
        },
        {
            id: 'document-sharing-api',
            title: 'Document Sharing API Reference',
            type: 'api-docs',
            lastModified: '2025-01-22',
            author: 'Development Team',
            tags: ['api', 'documents', 'pdf', 'sharing']
        },
        {
            id: 'lwc-patterns',
            title: 'LWC Component Patterns',
            type: 'development-guides',
            lastModified: '2025-01-21',
            author: 'Frontend Team',
            tags: ['lwc', 'patterns', 'components', 'best-practices']
        }
    ];

    // Code examples and snippets
    codeExamples = [
        {
            id: 'apex-with-security',
            title: 'Apex WITH SECURITY_ENFORCED Pattern',
            language: 'apex',
            category: 'security',
            snippet: '@AuraEnabled(cacheable=true)\npublic static List<Contact> getMembers() {\n    return [SELECT Id, Name FROM Contact WITH SECURITY_ENFORCED];\n}'
        },
        {
            id: 'lwc-error-handling',
            title: 'LWC Error Handling Pattern',
            language: 'javascript',
            category: 'patterns',
            snippet: 'try {\n    const result = await apexMethod();\n    this.handleSuccess(result);\n} catch (error) {\n    this.handleError(error);\n}'
        }
    ];

    connectedCallback() {
        this.initializeTechnicalPortal();
    }

    initializeTechnicalPortal() {
        // Initialize with all documents
        this.filteredDocs = this.getAllDocuments();
    }

    // Get all documents across categories
    getAllDocuments() {
        // Mock document list - in real implementation, this would come from Apex
        return [
            ...this.recentlyUpdated,
            // Add more mock documents as needed
        ];
    }

    // Handle document type selection
    handleDocTypeSelect(event) {
        const docType = event.currentTarget.dataset.docType;
        this.selectedDocType = docType;
        this.applyFilters();

        // Track document type selection
        this.trackDocumentTypeSelection(docType);
    }

    // Handle search input
    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.applyFilters();
    }

    // Handle tag selection
    handleTagSelect(event) {
        const tag = event.currentTarget.dataset.tag;

        if (this.selectedTags.includes(tag)) {
            // Remove tag if already selected
            this.selectedTags = this.selectedTags.filter(t => t !== tag);
        } else {
            // Add tag to selection
            this.selectedTags = [...this.selectedTags, tag];
        }

        this.applyFilters();
    }

    // Apply current filters
    applyFilters() {
        let filtered = this.getAllDocuments();

        // Filter by document type
        if (this.selectedDocType) {
            filtered = filtered.filter(doc => doc.type === this.selectedDocType);
        }

        // Filter by search term
        if (this.searchTerm) {
            const searchLower = this.searchTerm.toLowerCase();
            filtered = filtered.filter(doc =>
                doc.title.toLowerCase().includes(searchLower) ||
                (doc.tags && doc.tags.some(tag => tag.toLowerCase().includes(searchLower)))
            );
        }

        // Filter by selected tags
        if (this.selectedTags.length > 0) {
            filtered = filtered.filter(doc =>
                doc.tags && this.selectedTags.some(tag => doc.tags.includes(tag))
            );
        }

        this.filteredDocs = filtered;
    }

    // Clear all filters
    handleClearFilters() {
        this.selectedDocType = '';
        this.searchTerm = '';
        this.selectedTags = [];
        this.filteredDocs = this.getAllDocuments();

        // Clear search input
        const searchInput = this.template.querySelector('lightning-input[data-id="search"]');
        if (searchInput) {
            searchInput.value = '';
        }
    }

    // Handle document selection
    handleDocumentSelect(event) {
        const docId = event.currentTarget.dataset.docId;

        // Open document or navigate to detail view
        this.dispatchEvent(new CustomEvent('documentselected', {
            detail: {
                documentId: docId,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));
    }

    // Handle code example copy
    handleCopyCode(event) {
        const snippet = event.currentTarget.dataset.snippet;

        navigator.clipboard.writeText(snippet).then(() => {
            this.showToast('Success', 'Code copied to clipboard', 'success');
        }).catch(() => {
            this.showToast('Error', 'Failed to copy code', 'error');
        });
    }

    // Analytics tracking
    trackDocumentTypeSelection(docType) {
        this.dispatchEvent(new CustomEvent('doctypetracking', {
            detail: {
                documentType: docType,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));
    }

    // Computed properties
    get hasFilters() {
        return this.selectedDocType || this.searchTerm || this.selectedTags.length > 0;
    }

    get selectedDocTypeData() {
        return this.documentTypes.find(type => type.id === this.selectedDocType);
    }

    get filteredTagsForCurrentType() {
        if (!this.selectedDocType) {
            return this.availableTags;
        }

        const docTypeData = this.selectedDocTypeData;
        return docTypeData ? docTypeData.tags : this.availableTags;
    }

    get hasFilteredDocs() {
        return this.filteredDocs.length > 0;
    }

    get filterSummary() {
        let summary = `${this.filteredDocs.length} documents`;

        if (this.selectedDocType) {
            const typeData = this.selectedDocTypeData;
            summary += ` in ${typeData ? typeData.title : 'selected category'}`;
        }

        if (this.selectedTags.length > 0) {
            summary += ` with tags: ${this.selectedTags.join(', ')}`;
        }

        return summary;
    }

    // Check if tag is selected
    isTagSelected(tag) {
        return this.selectedTags.includes(tag);
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
