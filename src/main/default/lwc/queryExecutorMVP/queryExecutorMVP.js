import { LightningElement, track, api } from 'lwc';
import executeMultipleQueries from '@salesforce/apex/QueryControllerMVP.executeMultipleQueries';

export default class QueryExecutorMVP extends LightningElement {

    // Configuration
    @track queryInputCount = 2; // 2 for trial, 4 for full version

    // Single source of truth for query inputs
    @track queryInputs = [];
    @track processingScript = '';

    // Execution State
    @track isExecuting = false;
    @track progressMessage = '';
    @track progressPercent = 0;
    @track executionError = '';

    // Validation State
    @track scriptValidation = { isValid: true, errors: [], hasErrors: false };

    // UI State
    @track showQueryHelp = false;
    @track showScriptHelp = false;

    // Validation timeouts
    queryValidationTimeouts = {};
    scriptValidationTimeout = null;

    @track showUpgradeNotice = false;

    // ===========================================
    // LIFECYCLE HOOKS
    // ===========================================

    connectedCallback() {
        this.initializeQueryInputs();
    }

    // ===========================================
    // INITIALIZATION
    // ===========================================

    initializeQueryInputs() {
        const placeholders = [
            'Enter your first SOQL query here...\nExample:\nSELECT Id, Name, Industry FROM Account LIMIT 100',
            'Enter your second SOQL query here...\nExample:\nSELECT Id, Name, AccountId FROM Contact LIMIT 200',
            'Enter your third SOQL query here...\nExample:\nSELECT Id, Name, Amount FROM Opportunity LIMIT 150',
            'Enter your fourth SOQL query here...\nExample:\nSELECT Id, Subject, CreatedDate FROM Task LIMIT 50'
        ];

        this.queryInputs = [];
        for (let i = 0; i < this.queryInputCount; i++) {
            this.queryInputs.push({
                id: `query${i + 1}`,
                title: `SOQL Query ${i + 1}`,
                query: '',
                placeholder: placeholders[i] || `Enter SOQL query ${i + 1} here...`,
                validation: { isValid: true, errors: [], hasErrors: false },
                estimatedRecords: null,
                charCount: 0,
                summaryClass: 'summary-empty',
                summaryText: 'No query provided'
            });
        }

        if (this.queryInputCount !== 4) {
            this.showUpgradeNotice = true;
        }
    }

    @api
    setQueryMode(count) {
        if (count !== 2 && count !== 4) {
            console.error('Query count must be 2 or 4');
            return;
        }

        this.queryInputCount = count;
        this.initializeQueryInputs();
        this.processingScript = '';
        this.scriptValidation = { isValid: true, errors: [], hasErrors: false };
    }

    // ===========================================
    // PUBLIC API METHODS
    // ===========================================

    @api
    applyTemplate(queries, processorScript) {
        try {
            console.log('🔥 APPLY TEMPLATE CALLED in Query Executor');
            console.log('📊 Queries received:', queries?.length || 0);
            console.log('🔧 Processor script length:', processorScript?.length || 0);

            // Validate input parameters
            if (!queries || !Array.isArray(queries)) {
                throw new Error('Queries parameter must be an array');
            }

            if (!processorScript || typeof processorScript !== 'string') {
                throw new Error('Processor script parameter must be a string');
            }

            console.log('✅ Input validation passed');

            // Clear existing data first
            this.handleClearAll();
            console.log('🧹 Cleared existing query data');

            // Force UI update with setTimeout to ensure DOM is ready
            setTimeout(() => {
                this.updateUIWithTemplateData(queries, processorScript);
            }, 50);

        } catch (error) {
            console.error('❌ Failed to apply template in Query Executor:', error);
            this.dispatchEvent(new CustomEvent('templateerror', {
                detail: {
                    message: 'Failed to apply template: ' + error.message,
                    error: error
                },
                bubbles: true,
                composed: true
            }));
        }
    }

    updateUIWithTemplateData(queries, processorScript) {
        try {
            console.log('🎯 Updating UI with template data...');

            // Update query data
            for (let i = 0; i < this.queryInputCount; i++) {
                if (i < queries.length && queries[i] && queries[i].soql) {
                    const query = queries[i];
                    console.log(`📝 Updating query ${i + 1} data:`, {
                        id: query.id,
                        soqlLength: query.soql?.length || 0
                    });

                    this.queryInputs[i].query = query.soql || '';
                    this.queryInputs[i].charCount = this.queryInputs[i].query.length;
                    this.validateQuery(i);
                    this.updateQuerySummary(i);

                    console.log(`✅ Query ${i + 1} data updated`);
                } else {
                    // Clear unused query slots
                    this.queryInputs[i].query = '';
                    this.queryInputs[i].charCount = 0;
                    this.queryInputs[i].validation = { isValid: true, errors: [], hasErrors: false };
                    this.queryInputs[i].estimatedRecords = null;
                    this.queryInputs[i].summaryClass = 'summary-empty';
                    this.queryInputs[i].summaryText = 'No query provided';
                }
            }

            // Update processor script
            this.processingScript = processorScript;
            this.validateScript();

            // Force reactivity
            this.queryInputs = [...this.queryInputs];
            console.log('🔄 Data reactivity triggered');

            // Force DOM update as fallback
            setTimeout(() => {
                this.forceUIUpdate(queries, processorScript);
            }, 100);

        } catch (error) {
            console.error('❌ Error updating UI with template data:', error);
            throw error;
        }
    }

    forceUIUpdate(queries, processorScript) {
        try {
            console.log('🔧 Force updating UI elements directly...');

            // Update query textareas
            for (let i = 0; i < this.queryInputCount; i++) {
                const textarea = this.template.querySelector(`textarea[data-query-index="${i}"]`);
                if (textarea) {
                    const queryData = (i < queries.length && queries[i]) ? queries[i].soql || '' : '';
                    if (queryData && textarea.value !== queryData) {
                        textarea.value = queryData;
                        console.log(`🎯 Force updated Query ${i + 1} textarea`);
                        textarea.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                } else {
                    console.warn(`⚠️ Could not find textarea for query ${i + 1}`);
                }
            }

            // Update processor script textarea
            const scriptTextarea = this.template.querySelector('.script-input');
            if (scriptTextarea && processorScript && scriptTextarea.value !== processorScript) {
                scriptTextarea.value = processorScript;
                console.log('🎯 Force updated JavaScript processor textarea');
                scriptTextarea.dispatchEvent(new Event('input', { bubbles: true }));
            }

            this.verifyUIUpdate(queries, processorScript);

        } catch (error) {
            console.error('❌ Error in force UI update:', error);
        }
    }

    verifyUIUpdate(queries, processorScript) {
        console.log('🔍 Verifying UI update...');

        let allUpdated = true;

        // Check query textareas
        for (let i = 0; i < this.queryInputCount; i++) {
            const textarea = this.template.querySelector(`textarea[data-query-index="${i}"]`);
            const expectedValue = (i < queries.length && queries[i]) ? queries[i].soql || '' : '';

            if (textarea && expectedValue && textarea.value !== expectedValue) {
                console.warn(`⚠️ Query ${i + 1} not updated correctly. Expected: ${expectedValue.length} chars, Got: ${textarea.value.length} chars`);
                allUpdated = false;
            } else if (expectedValue) {
                console.log(`✅ Query ${i + 1} verified: ${textarea.value.length} characters`);
            }
        }

        // Check script textarea
        const scriptTextarea = this.template.querySelector('.script-input');
        if (scriptTextarea && processorScript && scriptTextarea.value !== processorScript) {
            console.warn(`⚠️ Script not updated correctly. Expected: ${processorScript.length} chars, Got: ${scriptTextarea.value.length} chars`);
            allUpdated = false;
        } else if (processorScript) {
            console.log(`✅ Script verified: ${scriptTextarea.value.length} characters`);
        }

        if (allUpdated) {
            console.log('🎉 Template application UI update completed successfully!');
            this.dispatchEvent(new CustomEvent('templateloaded', {
                detail: {
                    message: 'Template loaded successfully',
                    queryCount: queries.filter(q => q && q.soql).length,
                    hasProcessor: !!processorScript,
                    templateApplied: true,
                    uiUpdated: true
                },
                bubbles: true,
                composed: true
            }));
        } else {
            console.error('❌ UI update verification failed');
            this.dispatchEvent(new CustomEvent('templateerror', {
                detail: {
                    message: 'Template data updated but UI failed to refresh',
                    uiUpdateFailed: true
                },
                bubbles: true,
                composed: true
            }));
        }
    }

    @api
    getQueryBuilderState() {
        const validQueries = this.queryInputs.filter(qi =>
            qi.query.trim() && !qi.validation.hasErrors
        );

        return {
            queries: this.queryInputs.map(qi => qi.query),
            processingScript: this.processingScript,
            isValid: !this.cannotExecute,
            hasValidQueries: validQueries.length > 0,
            validQueryCount: validQueries.length,
            hasScript: !!this.processingScript.trim(),
            scriptValid: !this.scriptValidation.hasErrors
        };
    }

    @api
    clearQueryBuilder() {
        this.handleClearAll();
    }

    // ===========================================
    // COMPUTED PROPERTIES
    // ===========================================

    get scriptCharCount() {
        return this.processingScript.length;
    }

    get executeButtonLabel() {
        return this.isExecuting ? 'Executing...' : 'Execute All Queries';
    }

    get executeButtonIcon() {
        return this.isExecuting ? 'utility:spinner' : 'utility:play';
    }

    get executeButtonClass() {
        return this.isExecuting ? 'execute-button executing' : 'execute-button';
    }

    get cannotExecute() {
        if (this.isExecuting) return true;
        if (!this.processingScript.trim()) return true;
        if (this.scriptValidation.hasErrors) return true;

        const hasValidQuery = this.queryInputs.some(qi =>
            qi.query.trim() && !qi.validation.hasErrors
        );

        return !hasValidQuery;
    }

    get hasExecutionError() {
        return this.executionError.length > 0;
    }

    get progressStyle() {
        return `width: ${this.progressPercent}%`;
    }

    get scriptSummaryClass() {
        if (!this.processingScript.trim()) return 'summary-empty';
        if (this.scriptValidation.hasErrors) return 'summary-error';
        return 'summary-ready';
    }

    get scriptSummaryText() {
        if (!this.processingScript.trim()) return 'No script provided';
        if (this.scriptValidation.hasErrors) return 'Has validation errors';
        return 'Ready to execute';
    }

    // ===========================================
    // EVENT HANDLERS
    // ===========================================

    handleQueryChange(event) {
        const queryIndex = parseInt(event.target.dataset.queryIndex);
        this.queryInputs[queryIndex].query = event.target.value;
        this.queryInputs[queryIndex].charCount = event.target.value.length;
        this.validateQuery(queryIndex);
        this.updateQuerySummary(queryIndex);

        // Trigger reactivity
        this.queryInputs = [...this.queryInputs];
    }

    handleQueryInput(event) {
        const queryIndex = parseInt(event.target.dataset.queryIndex);
        this.queryInputs[queryIndex].query = event.target.value;
        this.queryInputs[queryIndex].charCount = event.target.value.length;
        this.debounceQueryValidation(queryIndex);

        // Trigger reactivity
        this.queryInputs = [...this.queryInputs];
    }

    handleScriptChange(event) {
        this.processingScript = event.target.value;
        this.validateScript();
    }

    handleScriptInput(event) {
        this.processingScript = event.target.value;
        this.debounceScriptValidation();
    }

    // ===========================================
    // VALIDATION
    // ===========================================

    validateQuery(queryIndex) {
        const errors = [];
        const queryInput = this.queryInputs[queryIndex];
        const query = queryInput.query.trim();

        if (!query) {
            queryInput.validation = { isValid: true, errors: [], hasErrors: false };
            queryInput.estimatedRecords = null;
            return;
        }

        // Basic SOQL validation
        if (!query.toUpperCase().startsWith('SELECT')) {
            errors.push('Query must start with SELECT');
        }

        if (!query.toUpperCase().includes('FROM')) {
            errors.push('Query must include FROM clause');
        }

        // Check for potentially dangerous patterns
        const dangerousPatterns = [
            { pattern: /DELETE/gi, message: 'DELETE operations not allowed' },
            { pattern: /INSERT/gi, message: 'INSERT operations not allowed' },
            { pattern: /UPDATE/gi, message: 'UPDATE operations not allowed' },
            { pattern: /UPSERT/gi, message: 'UPSERT operations not allowed' }
        ];

        dangerousPatterns.forEach(({ pattern, message }) => {
            if (pattern.test(query)) {
                errors.push(message);
            }
        });

        // Estimate record count
        queryInput.estimatedRecords = this.estimateRecordCount(query);

        queryInput.validation = {
            isValid: errors.length === 0,
            errors: errors,
            hasErrors: errors.length > 0
        };
    }

    validateScript() {
        const errors = [];
        const script = this.processingScript.trim();

        if (!script) {
            this.scriptValidation = { isValid: true, errors: [], hasErrors: false };
            return;
        }

        // Check for required processData function
        if (!script.includes('function processData')) {
            errors.push('Script must contain a processData function');
        } else {
            // Check if processData function accepts the right number of parameters
            const funcMatch = script.match(/function\s+processData\s*\(\s*([^)]*)\s*\)/);
            if (funcMatch) {
                const params = funcMatch[1].split(',').map(p => p.trim()).filter(p => p.length > 0);
                const expectedParams = this.queryInputCount === 2 ? 2 : 4;
                if (params.length !== expectedParams) {
                    errors.push(`processData function must accept exactly ${expectedParams} parameters for ${this.queryInputCount}-query mode`);
                }
            }
        }

        // Check for dangerous patterns
        const dangerousPatterns = [
            { pattern: /\beval\s*\(/gi, message: 'eval() is not allowed' },
            { pattern: /\bnew\s+Function\s*\(/gi, message: 'Function constructor is not allowed' },
            { pattern: /\bfetch\s*\(/gi, message: 'fetch() is not allowed - use Salesforce APIs' },
            { pattern: /\bXMLHttpRequest\b/gi, message: 'XMLHttpRequest is not allowed - use Salesforce APIs' },
            { pattern: /\bwindow\./gi, message: 'window access is not allowed' },
            { pattern: /\bdocument\./gi, message: 'document access is not allowed' }
        ];

        dangerousPatterns.forEach(({ pattern, message }) => {
            if (pattern.test(script)) {
                errors.push(message);
            }
        });

        // Basic syntax validation
        try {
            const paramNames = [];
            for (let i = 0; i < this.queryInputCount; i++) {
                paramNames.push(`query${i + 1}Results`);
            }
            new Function(...paramNames, script);
        } catch (syntaxError) {
            errors.push(`Syntax error: ${syntaxError.message}`);
        }

        this.scriptValidation = {
            isValid: errors.length === 0,
            errors: errors,
            hasErrors: errors.length > 0
        };
    }

    estimateRecordCount(query) {
        const limitMatch = query.match(/LIMIT\s+(\d+)/i);
        if (limitMatch) {
            return parseInt(limitMatch[1]);
        }
        return 'Unknown (consider adding LIMIT)';
    }

    updateQuerySummary(queryIndex) {
        const queryInput = this.queryInputs[queryIndex];
        const query = queryInput.query.trim();

        if (!query) {
            queryInput.summaryClass = 'summary-empty';
            queryInput.summaryText = 'No query provided';
        } else if (queryInput.validation.hasErrors) {
            queryInput.summaryClass = 'summary-error';
            queryInput.summaryText = 'Has validation errors';
        } else {
            queryInput.summaryClass = 'summary-ready';
            queryInput.summaryText = `Ready (~${queryInput.estimatedRecords || 'unknown'} records)`;
        }
    }

    // Debounced validation
    debounceQueryValidation(queryIndex) {
        clearTimeout(this.queryValidationTimeouts[queryIndex]);
        this.queryValidationTimeouts[queryIndex] = setTimeout(() => {
            this.validateQuery(queryIndex);
            this.updateQuerySummary(queryIndex);
        }, 500);
    }

    debounceScriptValidation() {
        clearTimeout(this.scriptValidationTimeout);
        this.scriptValidationTimeout = setTimeout(() => {
            this.validateScript();
        }, 500);
    }

    // ===========================================
    // EXECUTION ENGINE
    // ===========================================

    async handleExecute() {
        if (this.cannotExecute) return;

        try {
            this.startExecution();

            // Prepare queries for execution
            const queries = this.queryInputs.map(qi => qi.query.trim()).filter(q => q.length > 0);

            if (queries.length === 0) {
                throw new Error('At least one query must be provided');
            }

            // Execute SOQL queries
            this.updateProgress(20, 'Executing SOQL queries...');
            const queryResult = await executeMultipleQueries({ queries: queries });

            // Parse results
            this.updateProgress(50, 'Parsing query results...');
            let parsedResults;
            try {
                parsedResults = queryResult.results.map(r => JSON.parse(r.data));
            } catch (e) {
                console.error('❌ JSON.parse failed:', e);
                throw new Error('Failed to parse server response');
            }

            // Pad with empty arrays if fewer queries were provided
            while (parsedResults.length < this.queryInputCount) {
                parsedResults.push([]);
            }

            // Execute JavaScript processing
            this.updateProgress(70, 'Processing data with JavaScript...');
            const processedData = await this.executeUserScript(parsedResults, this.processingScript);

            // Complete
            this.updateProgress(100, 'Execution complete!');

            const totalRecordCount = queryResult.results.reduce((sum, result) => sum + result.recordCount, 0);

            this.dispatchExecutionComplete({
                rawData: parsedResults,
                processedData: processedData,
                recordCount: totalRecordCount,
                executionTime: queryResult.totalExecutionTime,
                queries: this.queryInputs.map(qi => qi.query),
                script: this.processingScript,
                queryResults: queryResult.results
            });

        } catch (error) {
            console.error('Execution error:', error);
            this.executionError = error.message || 'Unknown execution error';
            this.dispatchExecutionError({ message: this.executionError });
        } finally {
            this.isExecuting = false;
        }
    }

    async executeUserScript(queryResults, script) {
        return new Promise((resolve, reject) => {
            try {
                const sanitizedScript = this.sanitizeScript(script);

                const paramNames = [];
                for (let i = 0; i < this.queryInputCount; i++) {
                    paramNames.push(`query${i + 1}Results`);
                }

                const wrappedScript = `
                "use strict";
                ${sanitizedScript}
                
                if (typeof processData !== 'function') {
                    throw new Error('processData function is required');
                }
                
                return processData(${paramNames.join(', ')});
                `;

                const timeoutId = setTimeout(() => {
                    reject(new Error('Script execution timeout (30 seconds)'));
                }, 30000);

                const executionFunction = new Function(...paramNames, 'console', wrappedScript);

                const result = executionFunction(
                    ...queryResults.slice(0, this.queryInputCount),
                    this.createSafeConsole()
                );

                clearTimeout(timeoutId);
                resolve(result);

            } catch (error) {
                reject(new Error(`JavaScript processing failed: ${error.message}`));
            }
        });
    }

    sanitizeScript(script) {
        const dangerousPatterns = [
            { pattern: /\beval\s*\(/gi, replacement: '/*eval blocked*/' },
            { pattern: /\bnew\s+Function\s*\(/gi, replacement: '/*Function constructor blocked*/' },
            { pattern: /\bfetch\s*\(/gi, replacement: '/*fetch blocked*/' },
            { pattern: /\bXMLHttpRequest\b/gi, replacement: '/*XMLHttpRequest blocked*/' },
            { pattern: /\bwindow\./gi, replacement: '/*window access blocked*/' },
            { pattern: /\bdocument\./gi, replacement: '/*document access blocked*/' }
        ];

        let sanitized = script;
        dangerousPatterns.forEach(({ pattern, replacement }) => {
            sanitized = sanitized.replace(pattern, replacement);
        });

        return sanitized;
    }

    createSafeConsole() {
        return {
            log: (...args) => console.log('[User Script]:', ...args),
            warn: (...args) => console.warn('[User Script]:', ...args),
            error: (...args) => console.error('[User Script]:', ...args)
        };
    }

    // ===========================================
    // EXECUTION CONTROL
    // ===========================================

    startExecution() {
        this.isExecuting = true;
        this.progressPercent = 0;
        this.progressMessage = 'Starting execution...';
        this.executionError = '';

        this.dispatchEvent(new CustomEvent('executionstarted', {
            detail: {
                queries: this.queryInputs.map(qi => qi.query),
                script: this.processingScript
            }
        }));
    }

    updateProgress(percent, message) {
        this.progressPercent = percent;
        this.progressMessage = message;
    }

    handleCancel() {
        this.isExecuting = false;
        this.progressPercent = 0;
        this.progressMessage = '';
        console.log('Execution cancelled by user');
    }

    handleRetry() {
        this.executionError = '';
        this.handleExecute();
    }

    dispatchExecutionComplete(results) {
        this.dispatchEvent(new CustomEvent('executioncomplete', { detail: results }));
    }

    dispatchExecutionError(error) {
        this.dispatchEvent(new CustomEvent('executionerror', { detail: error }));
    }

    // ===========================================
    // UI ACTIONS
    // ===========================================

    handleClearAll() {
        console.log('🧹 Clearing all query data...');

        this.queryInputs.forEach(qi => {
            qi.query = '';
            qi.charCount = 0;
            qi.validation = { isValid: true, errors: [], hasErrors: false };
            qi.estimatedRecords = null;
            qi.summaryClass = 'summary-empty';
            qi.summaryText = 'No query provided';
        });

        this.processingScript = '';
        this.executionError = '';
        this.scriptValidation = { isValid: true, errors: [], hasErrors: false };

        // Trigger reactivity
        this.queryInputs = [...this.queryInputs];

        console.log('✅ All query data cleared');
    }

    clearSingleQuery(event) {
        const queryIndex = parseInt(event.target.dataset.queryIndex);
        this.queryInputs[queryIndex].query = '';
        this.queryInputs[queryIndex].charCount = 0;
        this.queryInputs[queryIndex].validation = { isValid: true, errors: [], hasErrors: false };
        this.queryInputs[queryIndex].estimatedRecords = null;
        this.queryInputs[queryIndex].summaryClass = 'summary-empty';
        this.queryInputs[queryIndex].summaryText = 'No query provided';

        // Trigger reactivity
        this.queryInputs = [...this.queryInputs];
    }

    loadSampleQuery(event) {
        const queryIndex = parseInt(event.target.dataset.queryIndex);
        const sampleQueries = [
            `SELECT Id, Name, Industry, BillingState, AnnualRevenue, NumberOfEmployees
             FROM Account
             WHERE Industry != null 
LIMIT 100`,
            `SELECT Id, Name, Title, AccountId, Account.Name, Account.Industry
             FROM Contact
             WHERE AccountId != null 
LIMIT 200`,
            `SELECT Id, Name, Amount, StageName, AccountId, Account.Industry
             FROM Opportunity
             WHERE Amount != null 
LIMIT 150`,
            `SELECT Id, Subject, Status, WhoId, WhatId, CreatedDate
             FROM Task
             WHERE CreatedDate = LAST_30_DAYS
                 LIMIT 50`
        ];

        this.queryInputs[queryIndex].query = sampleQueries[queryIndex] || '';
        this.queryInputs[queryIndex].charCount = this.queryInputs[queryIndex].query.length;
        this.validateQuery(queryIndex);
        this.updateQuerySummary(queryIndex);

        // Trigger reactivity
        this.queryInputs = [...this.queryInputs];
    }

    loadSampleScript() {
        if (this.queryInputCount === 2) {
            this.processingScript = `function processData(query1Results, query2Results) {
    // Simple 2-query analysis: Accounts and Contacts
    
    // Create account map for lookups
    const accountMap = new Map();
    query1Results.forEach(account => {
        accountMap.set(account.Id, account);
    });
    
    // Industry analysis from accounts
    const industryStats = {};
    query1Results.forEach(account => {
        const industry = account.Industry || 'Unknown';
        if (!industryStats[industry]) {
            industryStats[industry] = {
                accountCount: 0,
                totalRevenue: 0,
                totalEmployees: 0
            };
        }
        industryStats[industry].accountCount++;
        industryStats[industry].totalRevenue += account.AnnualRevenue || 0;
        industryStats[industry].totalEmployees += account.NumberOfEmployees || 0;
    });
    
    // Contact analysis with account enrichment
    const contactsByIndustry = {};
    query2Results.forEach(contact => {
        const account = accountMap.get(contact.AccountId);
        const industry = account?.Industry || 'Unknown';
        
        if (!contactsByIndustry[industry]) {
            contactsByIndustry[industry] = 0;
        }
        contactsByIndustry[industry]++;
    });
    
    // Final summary
    const industryAnalysis = Object.keys(industryStats).map(industry => ({
        industry: industry,
        accounts: industryStats[industry].accountCount,
        contacts: contactsByIndustry[industry] || 0,
        totalRevenue: industryStats[industry].totalRevenue,
        avgRevenue: industryStats[industry].accountCount > 0 ? 
            industryStats[industry].totalRevenue / industryStats[industry].accountCount : 0,
        totalEmployees: industryStats[industry].totalEmployees
    }));
    
    return {
        summary: {
            totalAccounts: query1Results.length,
            totalContacts: query2Results.length
        },
        industryAnalysis: industryAnalysis,
        executionTimestamp: new Date().toISOString()
    };
}`;
        } else {
            this.processingScript = `function processData(query1Results, query2Results, query3Results, query4Results) {
    // Multi-query analysis: Accounts, Contacts, Opportunities, and Tasks
    
    // Create maps for cross-referencing
    const accountMap = new Map();
    query1Results.forEach(account => {
        accountMap.set(account.Id, account);
    });
    
    // Industry analysis from accounts
    const industryStats = {};
    query1Results.forEach(account => {
        const industry = account.Industry || 'Unknown';
        if (!industryStats[industry]) {
            industryStats[industry] = {
                accountCount: 0,
                totalRevenue: 0,
                totalEmployees: 0
            };
        }
        industryStats[industry].accountCount++;
        industryStats[industry].totalRevenue += account.AnnualRevenue || 0;
        industryStats[industry].totalEmployees += account.NumberOfEmployees || 0;
    });
    
    // Contact analysis with account enrichment
    const contactsByIndustry = {};
    query2Results.forEach(contact => {
        const account = accountMap.get(contact.AccountId);
        const industry = account?.Industry || 'Unknown';
        
        if (!contactsByIndustry[industry]) {
            contactsByIndustry[industry] = 0;
        }
        contactsByIndustry[industry]++;
    });
    
    // Opportunity analysis
    const opportunityStats = {};
    let totalOpportunityValue = 0;
    query3Results.forEach(opp => {
        const account = accountMap.get(opp.AccountId);
        const industry = account?.Industry || 'Unknown';
        
        if (!opportunityStats[industry]) {
            opportunityStats[industry] = {
                count: 0,
                totalValue: 0,
                avgValue: 0
            };
        }
        opportunityStats[industry].count++;
        opportunityStats[industry].totalValue += opp.Amount || 0;
        totalOpportunityValue += opp.Amount || 0;
    });
    
    // Calculate averages
    Object.values(opportunityStats).forEach(stat => {
        stat.avgValue = stat.count > 0 ? stat.totalValue / stat.count : 0;
    });
    
    // Task activity analysis
    const taskActivity = {
        totalTasks: query4Results.length,
        completedTasks: query4Results.filter(task => task.Status === 'Completed').length,
        pendingTasks: query4Results.filter(task => task.Status !== 'Completed').length
    };
    
    // Final summary
    const industryAnalysis = Object.keys(industryStats).map(industry => ({
        industry: industry,
        accounts: industryStats[industry].accountCount,
        contacts: contactsByIndustry[industry] || 0,
        opportunities: opportunityStats[industry]?.count || 0,
        totalRevenue: industryStats[industry].totalRevenue,
        avgRevenue: industryStats[industry].accountCount > 0 ? 
            industryStats[industry].totalRevenue / industryStats[industry].accountCount : 0,
        totalEmployees: industryStats[industry].totalEmployees,
        opportunityValue: opportunityStats[industry]?.totalValue || 0
    }));
    
    return {
        summary: {
            totalAccounts: query1Results.length,
            totalContacts: query2Results.length,
            totalOpportunities: query3Results.length,
            totalTasks: query4Results.length,
            totalOpportunityValue: totalOpportunityValue
        },
        industryAnalysis: industryAnalysis,
        taskActivity: taskActivity,
        executionTimestamp: new Date().toISOString()
    };
}`;
        }
        this.validateScript();
    }

    testScript() {
        // Create appropriate sample data based on query mode
        const sampleData = [
            // Query 1 - Sample Accounts
            [{
                Id: '001XX000003DHF4',
                Name: 'Acme Corp',
                Industry: 'Technology',
                BillingState: 'CA',
                AnnualRevenue: 1000000,
                NumberOfEmployees: 50
            }],
            // Query 2 - Sample Contacts
            [{
                Id: '003XX000004TMH2',
                Name: 'John Doe',
                Title: 'CEO',
                AccountId: '001XX000003DHF4',
                Account: {
                    Name: 'Acme Corp',
                    Industry: 'Technology'
                }
            }]
        ];

        if (this.queryInputCount === 4) {
            sampleData.push(
                // Query 3 - Sample Opportunities
                [{
                    Id: '006XX000005WXY9',
                    Name: 'Big Deal',
                    Amount: 50000,
                    StageName: 'Proposal',
                    AccountId: '001XX000003DHF4'
                }],
                // Query 4 - Sample Tasks
                [{
                    Id: '00TXX000008ABC1',
                    Subject: 'Follow up call',
                    Status: 'Open',
                    CreatedDate: new Date().toISOString()
                }]
            );
        }

        try {
            this.executeUserScript(sampleData, this.processingScript)
                .then(result => {
                    console.log('Test result:', result);
                })
                .catch(error => {
                    console.error('Test failed:', error);
                });
        } catch (error) {
            console.error('Test failed:', error);
        }
    }

    hideUpgradeNotice() {
        this.showUpgradeNotice = false;
        console.log('📢 Upgrade notice dismissed by user');
    }

    // ===========================================
    // MODAL HANDLERS
    // ===========================================

    handleQueryHelp() {
        this.showQueryHelp = true;
    }

    handleScriptHelp() {
        this.showScriptHelp = true;
    }

    closeModals() {
        this.showQueryHelp = false;
        this.showScriptHelp = false;
    }

    stopPropagation(event) {
        event.stopPropagation();
    }
}