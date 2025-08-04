import { LightningElement, track } from 'lwc';

export default class ReportingAppMVP extends LightningElement {
    // Tab Management
    @track activeTab = 'query'; // Start with Query Builder tab (which includes template sidebar)

    // Results State
    @track executionResults = null;
    @track resultCount = 0;

    // Toast Notifications
    @track showToast = false;
    @track toastMessage = '';
    @track toastType = 'info'; // success, error, warning, info

    // Template Integration State
    @track lastAppliedTemplate = null;

    // Private properties
    toastTimeout = null;

    // ===========================================
    // COMPUTED PROPERTIES
    // ===========================================

    // Tab Visibility
    get showQueryTab() {
        return this.activeTab === 'query';
    }

    get showResultsTab() {
        return this.activeTab === 'results';
    }

    // Tab Styling
    get queryTabClass() {
        return this.activeTab === 'query' ? 'tab tab-active' : 'tab';
    }

    get resultsTabClass() {
        return this.activeTab === 'results' ? 'tab tab-active' : 'tab';
    }

    // Results State
    get hasResults() {
        return this.executionResults !== null;
    }

    get hasNoResults() {
        return !this.hasResults;
    }

    // Toast Styling
    get toastClass() {
        return `toast toast-${this.toastType}`;
    }

    get toastIcon() {
        const iconMap = {
            success: 'utility:success',
            error: 'utility:error',
            warning: 'utility:warning',
            info: 'utility:info'
        };
        return iconMap[this.toastType] || 'utility:info';
    }

    // ===========================================
    // LIFECYCLE HOOKS
    // ===========================================

    connectedCallback() {
        console.log('🚀 Advanced Reporting MVP initialized - starting with Query Builder tab (with template sidebar)');

        // Set up event listeners for child component events
        this.addEventListener('templateloaded', this.handleTemplateLoaded.bind(this));
        this.addEventListener('templateerror', this.handleTemplateError.bind(this));

        // Simple event listeners for toast notifications
        this.addEventListener('success', this.handleChildSuccess.bind(this));
        this.addEventListener('warning', this.handleChildWarning.bind(this));
        this.addEventListener('error', this.handleChildError.bind(this));

        console.log('✅ Event listeners registered for template integration');
    }

    disconnectedCallback() {
        // Cleanup timers and event listeners to prevent memory leaks
        if (this.toastTimeout) {
            clearTimeout(this.toastTimeout);
            this.toastTimeout = null;
        }

        // Remove event listeners
        this.removeEventListener('templateloaded', this.handleTemplateLoaded);
        this.removeEventListener('templateerror', this.handleTemplateError);
        this.removeEventListener('success', this.handleChildSuccess);
        this.removeEventListener('warning', this.handleChildWarning);
        this.removeEventListener('error', this.handleChildError);

        console.log('🔄 Advanced Reporting MVP disconnected - cleanup completed');
    }

    // ===========================================
    // EVENT HANDLERS
    // ===========================================

    /**
     * Handle tab navigation
     */
    handleQueryTab() {
        this.activeTab = 'query';
        console.log('Switched to Query Builder tab');
    }

    handleResultsTab() {
        this.activeTab = 'results';
        console.log('Switched to Results tab');
    }

    /**
     * Handle query execution events
     */
    handleExecutionStarted(event) {
        console.log('Query execution started:', event.detail);
        this.showInfoToast('Query execution started...');

        // Clear previous results when starting new execution
        this.executionResults = null;
        this.resultCount = 0;
    }

    handleResults(event) {
        console.log('Execution completed:', event.detail);

        this.executionResults = event.detail;
        this.resultCount = event.detail.recordCount || 0;

        // Auto-switch to results tab
        this.activeTab = 'results';

        // Show success message with template context if available
        let successMessage = `Query completed successfully! Processed ${this.resultCount} records.`;
        if (this.lastAppliedTemplate) {
            successMessage = `Template "${this.lastAppliedTemplate.name}" executed successfully! Processed ${this.resultCount} records.`;
        }

        this.showSuccessToast(successMessage);
    }

    handleExecutionError(event) {
        console.error('Execution error:', event.detail);
        this.showErrorToast(event.detail.message || 'Query execution failed');
    }

    /**
     * Handle template events from Template Manager (now in sidebar)
     */
    handleTemplateApplied(event) {
        console.log('🔥 TEMPLATE APPLICATION START - Full event detail:', JSON.stringify(event.detail, null, 2));

        const { template, queries, processor } = event.detail;

        // Validate the received data
        if (!template) {
            console.error('❌ No template in event detail');
            this.showErrorToast('Template application failed: No template data received');
            return;
        }

        if (!queries || !Array.isArray(queries)) {
            console.error('❌ No queries array in event detail:', queries);
            this.showErrorToast('Template application failed: No query data received');
            return;
        }

        if (!processor) {
            console.error('❌ No processor in event detail');
            this.showErrorToast('Template application failed: No processor data received');
            return;
        }

        console.log('✅ Template data validation passed');
        console.log(`📋 Template: ${template.name} (${template.id})`);
        console.log(`📊 Queries: ${queries.length} provided`);
        console.log(`🔧 Processor: ${processor.length} characters`);

        // Store reference to applied template for context
        this.lastAppliedTemplate = template;

        // Get the query executor component with retry logic
        let queryExecutor = this.template.querySelector('c-query-executor-m-v-p');

        if (!queryExecutor) {
            console.warn('⚠️ Query executor not found on first attempt, waiting...');
            // Sometimes the component isn't ready immediately, try again after a short delay
            setTimeout(() => {
                queryExecutor = this.template.querySelector('c-query-executor-m-v-p');
                if (queryExecutor) {
                    console.log('✅ Query executor found on retry');
                    this.applyTemplateToExecutor(queryExecutor, template, queries, processor);
                } else {
                    console.error('❌ Query executor still not found after retry');
                    this.showErrorToast('Query Builder component not ready. Please try again.');
                }
            }, 100);
            return;
        }

        console.log('✅ Query executor component found immediately');
        this.applyTemplateToExecutor(queryExecutor, template, queries, processor);
    }

    /**
     * Apply template to executor with detailed logging
     */
    applyTemplateToExecutor(queryExecutor, template, queries, processor) {
        try {
            console.log('🚀 Applying template to query executor...');
            console.log('📋 Template object:', template);
            console.log('📊 Queries structure:', queries.map(q => ({
                id: q.id,
                index: q.index,
                hasSOQL: !!q.soql,
                soqlLength: q.soql ? q.soql.length : 0
            })));
            console.log('🔧 Processor length:', processor.length);

            // Apply the template to the query executor
            queryExecutor.applyTemplate(queries, processor);

            // Clear any existing results since we're applying a new template
            this.executionResults = null;
            this.resultCount = 0;

            console.log('✅ Template applied successfully to query executor');
            this.showSuccessToast(`Template "${template.name}" applied successfully! Ready to execute.`);

            // Log template application for analytics
            console.log('📊 Template application analytics:', {
                templateId: template.id,
                templateName: template.name,
                templateCategory: template.category,
                queryCount: queries ? queries.length : 0,
                hasProcessor: !!processor,
                timestamp: new Date().toISOString()
            });

        } catch (error) {
            console.error('❌ Error applying template to executor:', error);
            console.error('Error stack:', error.stack);
            this.showErrorToast(`Failed to apply template "${template.name}": ${error.message}`);
        }
    }

    handleTemplateSuccess(event) {
        console.log('Template success:', event.detail);
        this.showInfoToast(event.detail.message || 'Template operation completed successfully');
    }

    handleTemplateRefresh(event) {
        console.log('Template refresh:', event.detail);
        this.showInfoToast(event.detail.message || 'Templates refreshed');
    }

    /**
     * Handle template-related events from Query Executor
     */
    handleTemplateLoaded(event) {
        console.log('Template loaded in Query Builder:', event.detail);

        const { message, queryCount, hasProcessor } = event.detail;

        // Show detailed success message
        let detailedMessage = message;
        if (queryCount && hasProcessor) {
            detailedMessage += ` (${queryCount} queries + JavaScript processor)`;
        } else if (queryCount) {
            detailedMessage += ` (${queryCount} queries)`;
        }

        this.showSuccessToast(detailedMessage);
    }

    handleTemplateError(event) {
        console.error('Template error in Query Builder:', event.detail);
        this.showErrorToast(event.detail.message || 'Template application failed');
    }

    /**
     * Handle simplified toast events from child components
     */
    handleChildSuccess(event) {
        this.showSuccessToast(event.detail.message);
    }

    handleChildWarning(event) {
        this.showWarningToast(event.detail.message);
    }

    handleChildError(event) {
        this.showErrorToast(event.detail.message);
    }

    // ===========================================
    // TOAST MANAGEMENT
    // ===========================================

    showSuccessToast(message) {
        this.displayToast(message, 'success');
    }

    showErrorToast(message) {
        this.displayToast(message, 'error');
    }

    showWarningToast(message) {
        this.displayToast(message, 'warning');
    }

    showInfoToast(message) {
        this.displayToast(message, 'info');
    }

    displayToast(message, type) {
        this.toastMessage = message;
        this.toastType = type;
        this.showToast = true;

        // Auto-hide after different durations based on type
        // Errors and warnings stay longer for user to read
        const hideDelay = (type === 'error' || type === 'warning') ? 7000 : 5000;

        // Clear any existing timeout to prevent overlapping timers
        if (this.toastTimeout) {
            clearTimeout(this.toastTimeout);
        }

        this.toastTimeout = setTimeout(() => {
            this.hideToast();
        }, hideDelay);
    }

    hideToast() {
        this.showToast = false;
        this.toastMessage = '';
        this.toastType = 'info';

        if (this.toastTimeout) {
            clearTimeout(this.toastTimeout);
            this.toastTimeout = null;
        }
    }

    // ===========================================
    // PUBLIC API METHODS
    // ===========================================

    /**
     * Programmatically switch to a specific tab
     * @param {String} tabName - 'query' or 'results'
     */
    switchToTab(tabName) {
        const validTabs = ['query', 'results'];
        if (validTabs.includes(tabName)) {
            this.activeTab = tabName;
            const tabDisplayName = tabName.charAt(0).toUpperCase() + tabName.slice(1);
            this.showInfoToast(`Switched to ${tabDisplayName} tab`);
            console.log(`Programmatically switched to ${tabName} tab`);
        } else {
            console.warn('Invalid tab name:', tabName, 'Valid options:', validTabs);
            this.showWarningToast(`Invalid tab name. Valid options: ${validTabs.join(', ')}`);
        }
    }

    /**
     * Get query executor component reference
     * @returns {Object|null} Query executor component or null if not found
     */
    getQueryExecutor() {
        const queryExecutor = this.template.querySelector('c-query-executor-m-v-p');
        if (!queryExecutor) {
            console.warn('Query Executor component not found');
        }
        return queryExecutor;
    }

    /**
     * Get template manager component reference (now in sidebar)
     * @returns {Object|null} Template manager component or null if not found
     */
    getTemplateManager() {
        const templateManager = this.template.querySelector('c-template-manager');
        if (!templateManager) {
            console.warn('Template Manager component not found');
        }
        return templateManager;
    }

    /**
     * Reset application to initial state
     * Useful for testing, demos, or user-requested reset
     */
    resetApplication() {
        console.log('Resetting application to initial state...');

        // Reset application state
        this.executionResults = null;
        this.resultCount = 0;
        this.lastAppliedTemplate = null;
        this.activeTab = 'query'; // Reset to Query Builder with sidebar
        this.hideToast();

        // Reset child components
        const queryExecutor = this.getQueryExecutor();
        if (queryExecutor) {
            queryExecutor.clearQueryBuilder();
        }

        console.log('Application state reset completed');
        this.showInfoToast('Application reset to initial state');
    }

    /**
     * Get current application state for debugging and monitoring
     * @returns {Object} Complete application state
     */
    getApplicationState() {
        const queryExecutor = this.getQueryExecutor();
        const templateManager = this.getTemplateManager();

        return {
            // Tab state
            activeTab: this.activeTab,

            // Results state
            hasResults: this.hasResults,
            resultCount: this.resultCount,

            // Template state
            lastAppliedTemplate: this.lastAppliedTemplate ? {
                id: this.lastAppliedTemplate.id,
                name: this.lastAppliedTemplate.name,
                category: this.lastAppliedTemplate.category
            } : null,

            // UI state
            toastVisible: this.showToast,
            toastType: this.toastType,
            toastMessage: this.toastMessage,

            // Child component states
            queryExecutorState: queryExecutor?.getQueryBuilderState() || null,
            templateManagerAvailable: !!templateManager,

            // Component availability
            componentsLoaded: {
                templateManager: !!templateManager,
                queryExecutor: !!queryExecutor,
                resultsViewer: !!this.template.querySelector('c-dynamic-results-viewer')
            },

            // Layout information
            layoutType: 'sidebar', // Now using sidebar layout

            // Timestamp for debugging
            stateTimestamp: new Date().toISOString()
        };
    }

    /**
     * Apply a template by ID programmatically
     * Useful for automation, testing, or deep linking
     * @param {String} templateId - The ID of the template to apply
     */
    applyTemplateById(templateId) {
        console.log('Attempting to apply template by ID:', templateId);

        const templateManager = this.getTemplateManager();
        if (templateManager) {
            try {
                const template = templateManager.getTemplateById(templateId);
                if (template) {
                    // Simulate the template application event
                    this.handleTemplateApplied({
                        detail: {
                            template: template,
                            queries: template.queries,
                            processor: template.processor.javascript
                        }
                    });
                    console.log('Template applied successfully via API:', templateId);
                } else {
                    const errorMessage = `Template with ID '${templateId}' not found`;
                    console.error(errorMessage);
                    this.showErrorToast(errorMessage);
                }
            } catch (error) {
                const errorMessage = `Failed to apply template '${templateId}': ${error.message}`;
                console.error(errorMessage, error);
                this.showErrorToast(errorMessage);
            }
        } else {
            const warningMessage = 'Template Manager not available. Please ensure you are on the Query Builder tab.';
            console.warn(warningMessage);
            this.showWarningToast(warningMessage);
        }
    }

    /**
     * Get available templates by category
     * @param {String} category - The category to filter by
     * @returns {Array} Array of templates in the specified category
     */
    getTemplatesByCategory(category) {
        const templateManager = this.getTemplateManager();
        if (templateManager) {
            return templateManager.getTemplatesByCategory(category);
        } else {
            console.warn('Template Manager not available');
            return [];
        }
    }

    /**
     * Force refresh of templates
     * Useful for updating template library or reloading after changes
     */
    refreshTemplates() {
        console.log('Refreshing templates...');

        const templateManager = this.getTemplateManager();
        if (templateManager) {
            templateManager.refreshTemplates();
            this.showInfoToast('Templates refreshed successfully');
        } else {
            this.showWarningToast('Template Manager not available for refresh');
        }
    }

    /**
     * Execute current queries if valid
     * Shortcut method for programmatic execution
     */
    executeCurrentQueries() {
        console.log('Attempting to execute current queries...');

        const queryExecutor = this.getQueryExecutor();
        if (queryExecutor) {
            const state = queryExecutor.getQueryBuilderState();
            if (state.isValid && state.hasValidQueries) {
                // Make sure we're on query tab
                if (this.activeTab !== 'query') {
                    this.activeTab = 'query';
                }

                // Trigger execution (this would need to be implemented in queryExecutor)
                // For now, just provide feedback
                this.showInfoToast('Ready to execute queries. Click Execute button in Query Builder.');
                console.log('Query execution ready. State:', state);
            } else {
                this.showWarningToast('Queries are not valid or ready for execution');
                console.warn('Cannot execute - invalid state:', state);
            }
        } else {
            this.showErrorToast('Query Executor not available');
        }
    }

    // ===========================================
    // ERROR HANDLING & DEBUGGING
    // ===========================================

    /**
     * Handle uncaught errors in child components
     */
    handleComponentError(error, componentName) {
        console.error(`Error in ${componentName}:`, error);
        this.showErrorToast(`${componentName} encountered an error. Please try again or contact support.`);

        // You could send this to a logging service
        // this.logErrorToService(error, componentName);
    }

    /**
     * Log application events for debugging and analytics
     */
    logApplicationEvent(eventType, eventData) {
        const logEntry = {
            timestamp: new Date().toISOString(),
            eventType: eventType,
            eventData: eventData,
            applicationState: {
                activeTab: this.activeTab,
                hasResults: this.hasResults,
                lastTemplate: this.lastAppliedTemplate?.name || null
            }
        };

        console.log('Application Event:', logEntry);

        // In production, you might send this to a logging service
        // this.sendToAnalytics(logEntry);
    }
}