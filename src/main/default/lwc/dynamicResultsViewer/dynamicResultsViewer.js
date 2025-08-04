import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';

export default class DynamicResultsViewer extends LightningElement {
    @api results;

    @track dashboardSections = [];
    @track showRawData = false;
    @track charts = new Map(); // Store Chart.js instances
    @track chartJsLoaded = false;

    // ===========================================
    // LIFECYCLE & BASIC PROPERTIES
    // ===========================================

    connectedCallback() {
        // Load Chart.js first, then analyze data
        this.loadChartLibrary();
    }

    async loadChartLibrary() {
        try {
            // Load Chart.js from static resource
            await loadScript(this, ChartJS);
            this.chartJsLoaded = true;
            console.log('Chart.js loaded successfully from static resource');
            // Attach Chart to global if needed
            if (!window.Chart && typeof Chart !== 'undefined') {
                window.Chart = ChartJS;
            } else if (!window.Chart && typeof ChartJS !== 'undefined') {
                window.Chart = ChartJS;
            }
            // Now analyze dashboard data after Chart.js is loaded
            this.analyzeDashboardData();
        } catch (error) {
            console.error('Failed to load Chart.js from static resource:', error);
            this.chartJsLoaded = false;
            // Still analyze data even if Chart.js fails to load
            this.analyzeDashboardData();
        }
    }

    renderedCallback() {
        // Initialize any charts after DOM is ready and Chart.js is loaded
        if (this.chartJsLoaded && this.dashboardSections.length > 0) {
            // Use setTimeout to ensure DOM is fully rendered
            setTimeout(() => {
                this.initializeCharts();
            }, 100);
        }
    }

    get hasResults() {
        return this.results !== null && this.results !== undefined;
    }

    get hasProcessedData() {
        return this.hasResults &&
            this.results.processedData &&
            typeof this.results.processedData === 'object';
    }

    get formattedTimestamp() {
        return new Date().toLocaleString();
    }

    get rawDataToggleLabel() {
        return this.showRawData ? 'Hide Raw Data' : 'Show Raw Data';
    }

    get rawDataCount() {
        if (!this.hasResults || !this.results.rawData) return 0;
        if (Array.isArray(this.results.rawData) && this.results.rawData.length > 0 && Array.isArray(this.results.rawData[0])) {
            return this.results.rawData.reduce((total, queryResults) => total + queryResults.length, 0);
        }
        return Array.isArray(this.results.rawData) ? this.results.rawData.length : 0;
    }

    get formattedRawData() {
        if (!this.hasResults || !this.results.rawData) return '';
        if (Array.isArray(this.results.rawData) && this.results.rawData.length > 0 && Array.isArray(this.results.rawData[0])) {
            return this.results.rawData
                .map((queryResults, index) => `Query ${index + 1} Results (${queryResults.length} records):\n${JSON.stringify(queryResults, null, 2)}`)
                .join('\n\n' + '='.repeat(50) + '\n\n');
        }
        return JSON.stringify(this.results.rawData, null, 2);
    }

    get executedQuery() {
        if (!this.hasResults) return '';
        if (this.results.queries && Array.isArray(this.results.queries)) {
            return this.results.queries
                .map((query, index) => {
                    const queryNum = index + 1;
                    const queryText = query && query.trim() ? query.trim() : '-- No query provided --';
                    return `Query ${queryNum}:\n${queryText}`;
                })
                .join('\n\n' + '='.repeat(50) + '\n\n');
        }
        return this.results.query || 'No query available';
    }

    get executedScript() {
        return this.hasResults ? (this.results.script || 'No script available') : '';
    }

    // ===========================================
    // DYNAMIC DATA ANALYSIS
    // ===========================================

    analyzeDashboardData() {
        if (!this.hasProcessedData) {
            this.dashboardSections = [];
            return;
        }

        const sections = [];
        const data = this.results.processedData;

        Object.entries(data).forEach(([key, value]) => {
            const section = this.analyzeDataStructure(key, value);
            if (section) {
                // Add computed properties for template rendering
                this.enhanceSectionForDisplay(section);
                sections.push(section);
            }
        });

        this.dashboardSections = sections;

        console.log('Dashboard sections created:', this.dashboardSections.length);
        console.log('Chart sections:', this.dashboardSections.filter(s => s.type === 'chart').length);

        // Initialize charts if Chart.js is loaded and DOM is ready
        if (this.chartJsLoaded) {
            // Use setTimeout to ensure DOM is updated
            setTimeout(() => {
                this.initializeCharts();
            }, 200);
        }
    }

    enhanceSectionForDisplay(section) {
        // Add boolean properties for template rendering
        section.isMetrics = section.type === 'metrics';
        section.isMetric = section.type === 'metric';
        section.isTable = section.type === 'table';
        section.isChart = section.type === 'chart';
        section.isList = section.type === 'list';

        // Add icon based on type
        section.icon = this.getSectionIcon(section.type);

        // Process metrics data for display
        if (section.isMetrics) {
            section.dataEntries = Object.entries(section.data).map(([key, value]) => ({
                key: key,
                label: this.formatTitle(key),
                value: value,
                formattedValue: this.formatValue(value, { isMetric: true })
            }));
        }

        // Process table data for display with pagination
        if (section.isTable) {
            // Initialize pagination
            section.currentPage = 1;
            section.pageSize = 10; // Default page size
            section.totalRecords = section.data.length;
            section.totalPages = Math.ceil(section.totalRecords / section.pageSize);

            // Process all data first
            const processedData = section.data.map((row, index) => {
                const processedRow = { ...row };

                // Add unique key for LWC template rendering
                processedRow.uniqueKey = row.Id || `${section.id}_row_${index}`;

                // Create cell objects for each column to avoid computed property access in template
                processedRow.cells = section.columns.map(column => {
                    const fieldValue = row[column.field];
                    const formattedValue = this.formatValue(fieldValue, {
                        column: column.field,
                        type: column.type
                    });

                    return {
                        field: column.field,
                        value: formattedValue,
                        isEmail: column.type === 'email',
                        isNotEmail: column.type !== 'email',
                        emailLink: column.type === 'email' && fieldValue ? `mailto:${fieldValue}` : null,
                        cellClass: `table-cell ${this.getCellClass(column.type)}`,
                        valueClass: this.getValueClass(column.type),
                        uniqueKey: `${processedRow.uniqueKey}_${column.field}`
                    };
                });

                return processedRow;
            });

            // Store all data and set current page data
            section.allData = processedData;
            section.data = this.getPaginatedData(processedData, section.currentPage, section.pageSize);

            // Add pagination info
            section.showPagination = section.totalRecords > section.pageSize;
            section.paginationInfo = this.getPaginationInfo(section);

            // Add CSS classes and computed properties for columns (still needed for headers)
            section.columns.forEach((column, columnIndex) => {
                column.cellClass = `table-cell ${this.getCellClass(column.type)}`;
                column.valueClass = this.getValueClass(column.type);
                column.isEmail = column.type === 'email';
                column.isNotEmail = column.type !== 'email';
                column.fieldKey = `field_${columnIndex}`; // For template iteration
            });
        }

        // Process list data for display
        if (section.isList) {
            section.isInsightsList = section.listType === 'insights';
            section.isRecommendationsList = section.listType === 'recommendations';
            section.isGenericList = section.listType === 'list';

            // Convert strings to objects with unique keys for LWC
            section.listItems = section.data.map((item, index) => ({
                content: item,
                uniqueKey: `${section.id}_item_${index}`,
                isInsight: section.isInsightsList,
                isRecommendation: section.isRecommendationsList,
                isGeneric: section.isGenericList
            }));
        }
    }

    getSectionIcon(type) {
        const iconMap = {
            'metrics': 'utility:analytics',
            'metric': 'utility:number_input',
            'table': 'utility:table',
            'chart': 'utility:chart',
            'list': 'utility:list'
        };
        return iconMap[type] || 'utility:info';
    }

    getCellClass(type) {
        const classMap = {
            'number': 'cell-number',
            'currency': 'cell-currency',
            'percentage': 'cell-percentage',
            'email': 'cell-email',
            'date': 'cell-date'
        };
        return classMap[type] || 'cell-text';
    }

    getValueClass(type) {
        const classMap = {
            'number': 'value-number',
            'currency': 'value-currency',
            'percentage': 'value-percentage',
            'email': 'value-email',
            'date': 'value-date'
        };
        return classMap[type] || 'value-text';
    }

    deepClone(obj) {
        if (obj === null || typeof obj !== 'object') return obj;

        if (Array.isArray(obj)) {
            return obj.map(item => this.deepClone(item));
        }

        const plain = {};
        for (const key in obj) {
            if (Object.prototype.hasOwnProperty.call(obj, key)) {
                try {
                    plain[key] = this.deepClone(obj[key]);
                } catch (e) {
                    console.warn(`Skipping property ${key} during deepUnwrap due to error:`, e);
                }
            }
        }
        return plain;
    }

    analyzeDataStructure(key, value) {
        const sectionId = `section_${key.replace(/[^a-zA-Z0-9]/g, '_')}`;

        if (Array.isArray(value)) {
            if (value.length === 0) return null;

            if (typeof value[0] === 'object' && value[0] !== null) {
                // Array of objects = Table
                return {
                    id: sectionId,
                    type: 'table',
                    title: this.formatTitle(key),
                    data: value,
                    columns: this.analyzeTableColumns(value),
                    sortable: true,
                    exportable: true
                };
            } else {
                // Array of strings = List
                return {
                    id: sectionId,
                    type: 'list',
                    title: this.formatTitle(key),
                    data: value,
                    listType: this.detectListType(key)
                };
            }
        } else if (typeof value === 'object' && value !== null) {
            // Check if this looks like chart data
            if (this.isChartData(value)) {
                return {
                    id: sectionId,
                    type: 'chart',
                    title: this.formatTitle(key),
                    data: this.deepClone(value),
                    chartType: this.detectChartType(value),
                    chartId: `chart_${sectionId}`
                };
            } else {
                // Object with key-value pairs = Metrics
                return {
                    id: sectionId,
                    type: 'metrics',
                    title: this.formatTitle(key),
                    data: value,
                    layout: Object.keys(value).length > 6 ? 'grid' : 'cards'
                };
            }
        } else {
            // Single value = Single metric
            return {
                id: sectionId,
                type: 'metric',
                title: this.formatTitle(key),
                value: value,
                formattedValue: this.formatValue(value, { isSingleMetric: true })
            };
        }
    }

    analyzeTableColumns(data) {
        if (!data || data.length === 0) return [];

        const sampleSize = Math.min(data.length, 10);
        const sample = data.slice(0, sampleSize);
        const columns = Object.keys(data[0]);

        return columns.map(col => ({
            field: col,
            label: this.formatColumnLabel(col),
            type: this.detectColumnType(sample, col),
            sortable: true,
            filterable: this.isFilterableType(this.detectColumnType(sample, col))
        }));
    }

    detectColumnType(sample, column) {
        const values = sample.map(row => row[column]).filter(val => val != null);
        if (values.length === 0) return 'text';

        // Check for numbers
        if (values.every(val => typeof val === 'number' || !isNaN(parseFloat(val)))) {
            return 'number';
        }

        // Check for percentages
        if (values.every(val => typeof val === 'string' && val.includes('%'))) {
            return 'percentage';
        }

        // Check for currency
        if (values.every(val => typeof val === 'string' && (val.includes('$') || val.includes('USD')))) {
            return 'currency';
        }

        // Check for emails
        if (values.every(val => typeof val === 'string' && val.includes('@'))) {
            return 'email';
        }

        // Check for dates
        if (values.every(val => !isNaN(Date.parse(val)))) {
            return 'date';
        }

        return 'text';
    }

    isChartData(obj) {
        // Check if object has properties that suggest chart data
        const keys = Object.keys(obj);

        // Common chart data patterns
        if (keys.includes('labels') && keys.includes('datasets')) return true;
        if (keys.includes('x') && keys.includes('y')) return true;
        if (keys.includes('categories') && keys.includes('series')) return true;

        // Check if all values are numbers (simple bar chart data)
        const values = Object.values(obj);
        if (values.every(val => typeof val === 'number')) return true;

        return false;
    }

    detectChartType(data) {
        const keys = Object.keys(data);
        const values = Object.values(data);

        // Chart.js format detection
        if (data.labels && data.datasets) {
            return 'bar'; // Default for Chart.js format, can be overridden
        }

        // Time series data (look for date-like keys)
        if (keys.some(k => {
            const lower = k.toLowerCase();
            return lower.includes('time') || lower.includes('date') ||
                lower.includes('month') || lower.includes('day') ||
                /^\d{4}-\d{2}/.test(k) || // YYYY-MM format
                /^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i.test(k); // Month names
        })) {
            return 'line';
        }

        // If we have more than 8 categories, use horizontal bar for better readability
        if (keys.length > 8) {
            return 'horizontalBar';
        }

        // If all values are percentages or small numbers, use pie chart
        if (values.every(val => typeof val === 'number' && val <= 100) && keys.length <= 6) {
            return 'pie';
        }

        // Default to bar chart for categorical data
        return 'bar';
    }

    detectListType(key) {
        const lowerKey = key.toLowerCase();
        if (lowerKey.includes('insight') || lowerKey.includes('finding')) {
            return 'insights';
        }
        if (lowerKey.includes('recommendation') || lowerKey.includes('action')) {
            return 'recommendations';
        }
        return 'list';
    }

    // ===========================================
    // PAGINATION HELPERS
    // ===========================================

    getPaginatedData(data, currentPage, pageSize) {
        const startIndex = (currentPage - 1) * pageSize;
        const endIndex = startIndex + pageSize;
        return data.slice(startIndex, endIndex);
    }

    getPaginationInfo(section) {
        const startRecord = (section.currentPage - 1) * section.pageSize + 1;
        const endRecord = Math.min(section.currentPage * section.pageSize, section.totalRecords);
        const canGoPrevious = section.currentPage > 1;
        const canGoNext = section.currentPage < section.totalPages;

        return {
            startRecord,
            endRecord,
            totalRecords: section.totalRecords,
            currentPage: section.currentPage,
            totalPages: section.totalPages,
            hasPrevious: canGoPrevious,
            hasNext: canGoNext,
            disablePrevious: !canGoPrevious,  // For easier template binding
            disableNext: !canGoNext,          // For easier template binding
            pageOptions: this.getPageSizeOptions(section.pageSize)
        };
    }

    getPageSizeOptions(currentPageSize = 10) {
        const options = [
            { label: '5', value: 5 },
            { label: '10', value: 10 },
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '100', value: 100 }
        ];

        // Mark the current page size as selected
        return options.map(option => ({
            ...option,
            selected: option.value === currentPageSize
        }));
    }

    handlePageChange(event) {
        const sectionId = event.target.dataset.sectionId;
        const action = event.target.dataset.action;
        const section = this.dashboardSections.find(s => s.id === sectionId);

        if (!section) return;

        if (action === 'previous' && section.currentPage > 1) {
            section.currentPage--;
        } else if (action === 'next' && section.currentPage < section.totalPages) {
            section.currentPage++;
        } else if (action === 'first') {
            section.currentPage = 1;
        } else if (action === 'last') {
            section.currentPage = section.totalPages;
        }

        // Update the displayed data
        section.data = this.getPaginatedData(section.allData, section.currentPage, section.pageSize);
        section.paginationInfo = this.getPaginationInfo(section);

        // Trigger reactivity
        this.dashboardSections = [...this.dashboardSections];
    }

    handlePageSizeChange(event) {
        const sectionId = event.target.dataset.sectionId;
        const newPageSize = parseInt(event.target.value);
        const section = this.dashboardSections.find(s => s.id === sectionId);

        if (!section) return;

        section.pageSize = newPageSize;
        section.currentPage = 1; // Reset to first page
        section.totalPages = Math.ceil(section.totalRecords / section.pageSize);
        section.showPagination = section.totalRecords > section.pageSize;

        // Update the displayed data
        section.data = this.getPaginatedData(section.allData, section.currentPage, section.pageSize);
        section.paginationInfo = this.getPaginationInfo(section);

        // Trigger reactivity
        this.dashboardSections = [...this.dashboardSections];
    }

    // ===========================================
    // SIMPLIFIED CSV EXPORT FUNCTIONALITY
    // ===========================================
    downloadCSV(csvContent, filename) {
        console.log('📥 Starting LWS-compatible CSV download:', filename);

        if (!csvContent || csvContent.trim() === '') {
            console.error('❌ Empty CSV content');
            this.showErrorToast('No data available for export');
            return;
        }

        try {
            // LWS-compatible MIME types
            const mimeTypes = [
                'text/plain',                    // Most compatible with LWS
                'application/octet-stream',      // Binary stream fallback
                'text/csv'                       // Standard CSV (no charset)
            ];

            let downloadSuccessful = false;

            // Try each MIME type until one works
            for (const mimeType of mimeTypes) {
                try {
                    console.log(`🔄 Attempting download with MIME type: ${mimeType}`);

                    // Create blob with current MIME type
                    const blob = new Blob([csvContent], { type: mimeType });

                    // Create download link
                    const link = document.createElement('a');
                    const url = URL.createObjectURL(blob);

                    // Ensure filename has .csv extension
                    const csvFilename = filename.endsWith('.csv') ? filename : filename + '.csv';

                    link.setAttribute('href', url);
                    link.setAttribute('download', csvFilename);
                    link.style.visibility = 'hidden';
                    link.style.position = 'absolute';
                    link.style.left = '-9999px';

                    // Add to DOM, click, and remove
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);

                    // Clean up
                    URL.revokeObjectURL(url);

                    console.log(`✅ CSV download successful with ${mimeType}:`, csvFilename);
                    this.showSuccessToast(`Downloaded ${csvFilename}`);
                    downloadSuccessful = true;
                    break; // Exit loop on success

                } catch (mimeError) {
                    console.warn(`⚠️ MIME type ${mimeType} failed:`, mimeError);
                    // Continue to next MIME type
                }
            }

            if (!downloadSuccessful) {
                throw new Error('All MIME types failed');
            }

        } catch (error) {
            console.error('❌ All download methods failed:', error);

            // Fallback: try navigator.clipboard if available
            if (navigator.clipboard && navigator.clipboard.writeText) {
                try {
                    navigator.clipboard.writeText(csvContent).then(() => {
                        this.showSuccessToast(`CSV data copied to clipboard! Save as "${filename}"`);
                    }).catch(() => {
                        this.showFinalFallback(csvContent, filename);
                    });
                } catch (clipboardError) {
                    this.showFinalFallback(csvContent, filename);
                }
            } else {
                this.showFinalFallback(csvContent, filename);
            }
        }
    }

    /**
     * Final fallback for extreme cases
     */
    showFinalFallback(csvContent, filename) {
        console.log('📋 Using final fallback method');

        // Create a simple alert with instructions
        const message = `Download blocked by security settings.\n\nOptions:\n1. Copy the data from browser console\n2. Contact your administrator\n3. Use a different browser`;

        // Log the CSV content to console for manual copying
        console.log('📊 CSV Content for manual copy:');
        console.log('=====================================');
        console.log(csvContent);
        console.log('=====================================');
        console.log(`Save the above content as: ${filename}`);

        this.showErrorToast('Download blocked by security settings. Check browser console for data.');
    }

// ===========================================
// ALTERNATIVE: EVEN SIMPLER LWS APPROACH
// If the above still fails, use this ultra-simple version
// ===========================================

    downloadCSVSimple(csvContent, filename) {
        try {
            // Ultra-simple approach - just text/plain
            const blob = new Blob([csvContent], { type: 'text/plain' });
            const url = URL.createObjectURL(blob);

            const link = document.createElement('a');
            link.href = url;
            link.download = filename.endsWith('.csv') ? filename : filename + '.csv';

            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

            URL.revokeObjectURL(url);

            this.showSuccessToast(`Downloaded ${filename}`);

        } catch (error) {
            console.error('Simple download failed:', error);

            // Last resort: copy to clipboard
            if (navigator.clipboard) {
                navigator.clipboard.writeText(csvContent).then(() => {
                    this.showSuccessToast('Data copied to clipboard - save as CSV file');
                }).catch(() => {
                    this.showErrorToast('Download failed. Please contact support.');
                });
            } else {
                this.showErrorToast('Download not supported in this environment.');
            }
        }
    }

    handleExport() {
        console.log('🚀 Starting dashboard export...');

        try {
            if (!this.dashboardSections || this.dashboardSections.length === 0) {
                this.showErrorToast('No data available for export');
                return;
            }

            let csvContent = '';
            let sectionsExported = 0;

            // Export all table sections
            const tableSections = this.dashboardSections.filter(section => section.type === 'table');

            if (tableSections.length > 0) {
                tableSections.forEach((section, index) => {
                    if (index > 0) csvContent += '\n\n';
                    csvContent += `"${section.title}"\n`;
                    csvContent += this.convertToCSV(section.allData || section.data);
                    sectionsExported++;
                });
            } else {
                // Export metrics if no tables
                const metricsSections = this.dashboardSections.filter(section => section.type === 'metrics');
                const metricsData = [];

                metricsSections.forEach(section => {
                    if (section.data && typeof section.data === 'object') {
                        Object.entries(section.data).forEach(([key, value]) => {
                            metricsData.push({
                                Section: section.title,
                                Metric: key,
                                Value: value
                            });
                        });
                    }
                });

                if (metricsData.length > 0) {
                    csvContent = this.convertToCSV(metricsData);
                    sectionsExported = metricsSections.length;
                }
            }

            if (!csvContent || sectionsExported === 0) {
                this.showErrorToast('No exportable data found');
                return;
            }

            this.downloadCSV(csvContent, 'dashboard-export.csv');

        } catch (error) {
            console.error('❌ Export failed:', error);
            this.showErrorToast('Export failed: ' + error.message);
        }
    }

    handleSectionExport(event) {
        const sectionId = event.target?.dataset?.sectionId ||
            event.target?.closest('[data-section-id]')?.dataset?.sectionId;

        if (!sectionId) {
            this.showErrorToast('Could not identify section for export');
            return;
        }

        const section = this.dashboardSections.find(s => s.id === sectionId);
        if (!section) {
            this.showErrorToast('Section not found');
            return;
        }

        try {
            let csvContent = '';
            const filename = `${section.title.replace(/[^a-zA-Z0-9]/g, '_')}_export.csv`;

            switch (section.type) {
                case 'table':
                    csvContent = this.convertToCSV(section.allData || section.data);
                    break;
                case 'metrics':
                    const metricsData = Object.entries(section.data || {}).map(([key, value]) => ({
                        Metric: key,
                        Value: value
                    }));
                    csvContent = this.convertToCSV(metricsData);
                    break;
                case 'chart':
                    const chartData = Object.entries(section.data || {}).map(([key, value]) => ({
                        Category: key,
                        Value: value
                    }));
                    csvContent = this.convertToCSV(chartData);
                    break;
                case 'list':
                    const listData = (section.data || []).map((item, index) => ({
                        Index: index + 1,
                        Item: item
                    }));
                    csvContent = this.convertToCSV(listData);
                    break;
                default:
                    this.showErrorToast(`Export not supported for ${section.type} sections`);
                    return;
            }

            if (!csvContent) {
                this.showErrorToast('No data to export from this section');
                return;
            }

            this.downloadCSV(csvContent, filename);

        } catch (error) {
            console.error('❌ Section export failed:', error);
            this.showErrorToast('Section export failed: ' + error.message);
        }
    }

    convertToCSV(data) {
        if (!Array.isArray(data) || data.length === 0) {
            return '';
        }

        // Handle table data with cells
        if (data[0] && data[0].cells) {
            const headers = data[0].cells.map(cell => cell.field);
            const rows = data.map(row =>
                row.cells.map(cell => this.escapeCsvValue(cell.value))
            );

            return [
                headers.map(h => this.escapeCsvValue(h)).join(','),
                ...rows.map(row => row.join(','))
            ].join('\n');
        }

        // Handle regular object data
        const headers = Object.keys(data[0]);
        const rows = data.map(row =>
            headers.map(header => this.escapeCsvValue(row[header]))
        );

        return [
            headers.map(h => this.escapeCsvValue(h)).join(','),
            ...rows.map(row => row.join(','))
        ].join('\n');
    }

    escapeCsvValue(value) {
        if (value === null || value === undefined) return '';

        let stringValue = String(value);

        // Escape quotes and wrap in quotes if necessary
        if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
            stringValue = '"' + stringValue.replace(/"/g, '""') + '"';
        }

        return stringValue;
    }

    // ===========================================
    // SIMPLIFIED TOAST METHODS
    // ===========================================

    showSuccessToast(message) {
        this.dispatchEvent(new CustomEvent('success', {
            detail: { message },
            bubbles: true,
            composed: true
        }));
    }

    showErrorToast(message) {
        this.dispatchEvent(new CustomEvent('error', {
            detail: { message },
            bubbles: true,
            composed: true
        }));
    }

    // ===========================================
    // FORMATTING UTILITIES
    // ===========================================

    formatTitle(key) {
        return key.replace(/([A-Z])/g, ' $1')
            .replace(/^./, str => str.toUpperCase())
            .replace(/_/g, ' ')
            .trim();
    }

    formatColumnLabel(column) {
        return column.replace(/([A-Z])/g, ' $1')
            .replace(/^./, str => str.toUpperCase())
            .replace(/_/g, ' ')
            .trim();
    }

    formatValue(value, context = {}) {
        if (value == null) return '';

        if (typeof value === 'number') {
            if (context.column?.toLowerCase().includes('revenue') ||
                context.column?.toLowerCase().includes('amount') ||
                context.column?.toLowerCase().includes('value')) {
                return this.formatCurrency(value);
            }
            return this.formatNumber(value);
        }

        if (typeof value === 'string') {
            if (value.includes('@')) {
                return `<a href="mailto:${value}" class="email-link">${value}</a>`;
            }
        }

        return value;
    }

    formatNumber(value) {
        if (!value && value !== 0) return '0';
        return value.toLocaleString();
    }

    formatCurrency(value) {
        if (!value && value !== 0) return '$0';

        if (value >= 1000000000) {
            return `$${(value / 1000000000).toFixed(1)}B`;
        } else if (value >= 1000000) {
            return `$${(value / 1000000).toFixed(1)}M`;
        } else if (value >= 1000) {
            return `$${(value / 1000).toFixed(0)}K`;
        } else {
            return `$${value.toLocaleString()}`;
        }
    }

    isFilterableType(type) {
        return ['text', 'number', 'percentage', 'currency'].includes(type);
    }

    // ===========================================
    // CHART.JS INTEGRATION
    // ===========================================

    initializeCharts() {
        // Only proceed if Chart.js is loaded and DOM is ready
        if (!this.chartJsLoaded || typeof Chart === 'undefined') {
            console.warn('Chart.js not loaded yet, skipping chart initialization');
            return;
        }

        // Find all chart sections and initialize them
        this.dashboardSections
            .filter(section => section.type === 'chart')
            .forEach(section => {
                const canvas = this.template.querySelector(`[data-chart-id="${section.chartId}"]`);
                if (canvas && !this.charts.has(section.chartId)) {
                    console.log('Initializing chart:', section.chartId);
                    console.log('Section Data Type:', typeof section.data);
                    console.log('Section Data Proto:', Object.getPrototypeOf(section.data));
                    console.log('Section Data Keys:', Object.keys(section.data));
                    console.log('Section Data:', section.data);

                    this.createChart(canvas, section);
                }
            });
    }

    createChart(canvas, section) {
        try {
            const ctx = canvas.getContext('2d');
            const chartData = this.prepareChartData(this.deepClone(section.data), section.chartType);

            console.log('Creating chart with data:', chartData);

            const chart = new Chart(ctx, {
                type: section.chartType,
                data: chartData,
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: section.title,
                            font: {
                                size: 16,
                                weight: 'bold'
                            }
                        },
                        legend: {
                            display: chartData.datasets && chartData.datasets.length > 1,
                            position: 'bottom'
                        }
                    },
                    scales: this.getScaleConfig(section.chartType),
                    animation: {
                        duration: 1000,
                        easing: 'easeInOutQuart'
                    }
                }
            });

            this.charts.set(section.chartId, chart);
            console.log('Chart created successfully:', section.chartId);
        } catch (error) {
            console.error('Failed to create chart:', section.chartId, error);
        }
    }

    prepareChartData(data, chartType) {
        console.log('Preparing chart data:', data, 'Chart type:', chartType);

        // Handle different data formats
        if (data.labels && data.datasets) {
            // Already in Chart.js format
            console.log('Using Chart.js format data');
            return data;
        }

        if (data.x && data.y) {
            // Coordinate data for scatter plots
            console.log('Using coordinate data format');
            return {
                datasets: [{
                    label: 'Data Points',
                    data: data.x.map((x, i) => ({ x, y: data.y[i] })),
                    backgroundColor: 'rgba(54, 162, 235, 0.6)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 2
                }]
            };
        }

        // Simple key-value object
        const labels = Object.keys(data);
        const values = Object.values(data);

        console.log('Using simple key-value data:', { labels, values });

        // Ensure we have valid data
        if (labels.length === 0 || values.length === 0) {
            console.warn('Empty chart data provided');
            return {
                labels: ['No Data'],
                datasets: [{
                    label: 'No Data Available',
                    data: [0],
                    backgroundColor: 'rgba(200, 200, 200, 0.6)'
                }]
            };
        }

        return {
            labels: labels,
            datasets: [{
                label: 'Values',
                data: values,
                backgroundColor: this.generateColors(labels.length, 0.6),
                borderColor: this.generateColors(labels.length, 1),
                borderWidth: chartType === 'pie' || chartType === 'doughnut' ? 0 : 2,
                tension: chartType === 'line' ? 0.4 : 0
            }]
        };
    }

    generateColors(count, alpha = 0.6) {
        const colors = [
            `rgba(54, 162, 235, ${alpha})`,   // Blue
            `rgba(255, 99, 132, ${alpha})`,   // Red
            `rgba(255, 205, 86, ${alpha})`,   // Yellow
            `rgba(75, 192, 192, ${alpha})`,   // Green
            `rgba(153, 102, 255, ${alpha})`,  // Purple
            `rgba(255, 159, 64, ${alpha})`,   // Orange
            `rgba(199, 199, 199, ${alpha})`,  // Grey
            `rgba(83, 102, 255, ${alpha})`    // Indigo
        ];

        return Array.from({ length: count }, (_, i) => colors[i % colors.length]);
    }

    getScaleConfig(chartType) {
        if (chartType === 'pie' || chartType === 'doughnut') {
            return {}; // No scales for pie charts
        }

        if (chartType === 'horizontalBar') {
            return {
                x: {
                    beginAtZero: true,
                    grid: {
                        display: true
                    }
                },
                y: {
                    grid: {
                        display: false
                    }
                }
            };
        }

        return {
            x: {
                grid: {
                    display: false
                }
            },
            y: {
                beginAtZero: true,
                grid: {
                    display: true
                }
            }
        };
    }

    // Method to refresh charts when data changes
    refreshCharts() {
        if (!this.chartJsLoaded) return;

        // Destroy existing charts
        this.charts.forEach(chart => {
            if (chart && typeof chart.destroy === 'function') {
                chart.destroy();
            }
        });
        this.charts.clear();

        // Re-initialize charts
        this.initializeCharts();
    }

    // ===========================================
    // EVENT HANDLERS
    // ===========================================

    toggleRawData() {
        this.showRawData = !this.showRawData;
    }

    handleSort(event) {
        const sectionId = event.target.dataset.sectionId;
        const field = event.target.dataset.field;
        const section = this.dashboardSections.find(s => s.id === sectionId);

        if (section && section.type === 'table') {
            // Implement sorting logic
            this.sortTableData(section, field);
        }
    }

    sortTableData(section, field) {
        const currentSort = section.sortField === field ? section.sortDirection : null;
        const newDirection = currentSort === 'asc' ? 'desc' : 'asc';

        // Sort the full dataset
        section.allData.sort((a, b) => {
            // Extract the original field value from the row data
            const aVal = a.cells.find(cell => cell.field === field)?.value || '';
            const bVal = b.cells.find(cell => cell.field === field)?.value || '';

            // Try to parse as numbers first
            const aNum = parseFloat(aVal);
            const bNum = parseFloat(bVal);

            if (!isNaN(aNum) && !isNaN(bNum)) {
                return newDirection === 'asc' ? aNum - bNum : bNum - aNum;
            }

            // String comparison
            const aStr = String(aVal).toLowerCase();
            const bStr = String(bVal).toLowerCase();

            if (newDirection === 'asc') {
                return aStr.localeCompare(bStr);
            } else {
                return bStr.localeCompare(aStr);
            }
        });

        section.sortField = field;
        section.sortDirection = newDirection;

        // Update the current page display
        section.data = this.getPaginatedData(section.allData, section.currentPage, section.pageSize);

        // Trigger reactivity
        this.dashboardSections = [...this.dashboardSections];
    }

    // ===========================================
    // CLEANUP & DEBUGGING
    // ===========================================

    disconnectedCallback() {
        // Destroy Chart.js instances to prevent memory leaks
        this.charts.forEach(chart => {
            if (chart && typeof chart.destroy === 'function') {
                chart.destroy();
            }
        });
        this.charts.clear();
        console.log('Charts cleaned up on component disconnect');
    }
}