/**
 * CVMA Google Drive Manager Component (CEB Admin)
 * Epic #12, User Story #89
 *
 * Comprehensive metadata management interface for CEB officers:
 * - View all Google Drive files with advanced filtering
 * - Statistics dashboard
 * - Google Drive ID validation
 * - CSV export for bulk operations
 * - Documentation for metadata updates
 *
 * @author Claude Code
 * @date October 2025
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllFiles from '@salesforce/apex/CVMAGoogleDriveManagementController.getAllFiles';
import getFileStatistics from '@salesforce/apex/CVMAGoogleDriveManagementController.getFileStatistics';
import validateGoogleDriveId from '@salesforce/apex/CVMAGoogleDriveManagementController.validateGoogleDriveId';
import getCategories from '@salesforce/apex/CVMAGoogleDriveManagementController.getCategories';
import exportToCSV from '@salesforce/apex/CVMAGoogleDriveManagementController.exportToCSV';
import isCEBOfficer from '@salesforce/apex/CVMAGoogleDriveManagementController.isCEBOfficer';

// Datatable columns configuration
const COLUMNS = [
    {
        label: 'File Name',
        fieldName: 'publicLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'fileName' },
            target: '_blank'
        },
        sortable: true,
        initialWidth: 300
    },
    {
        label: 'Category',
        fieldName: 'category',
        type: 'text',
        sortable: true
    },
    {
        label: 'Type',
        fieldName: 'fileType',
        type: 'text',
        sortable: true
    },
    {
        label: 'Size',
        fieldName: 'fileSizeDisplay',
        type: 'text',
        sortable: true,
        initialWidth: 100
    },
    {
        label: 'CEB Only',
        fieldName: 'cebOnly',
        type: 'boolean',
        sortable: true,
        initialWidth: 100
    },
    {
        label: 'Status',
        fieldName: 'statusBadge',
        type: 'text',
        sortable: true,
        initialWidth: 100
    },
    {
        label: 'Uploaded',
        fieldName: 'uploadedDate',
        type: 'date',
        sortable: true
    },
    {
        label: 'Display Order',
        fieldName: 'displayOrder',
        type: 'number',
        sortable: true,
        initialWidth: 120
    },
    {
        label: 'Google Drive ID',
        fieldName: 'driveId',
        type: 'text',
        wrapText: false,
        initialWidth: 200
    }
];

export default class CvmaGoogleDriveManager extends LightningElement {
    // Datatable
    columns = COLUMNS;
    @track files = [];
    @track filteredFiles = [];
    @track error;
    @track isLoading = true;
    @track isCEB = false;

    // Filters
    @track selectedCategory = 'All';
    @track includeInactive = false;
    @track searchTerm = '';
    @track categoryOptions = [{ label: 'All Categories', value: 'All' }];

    // Statistics
    @track stats = {};
    @track showStatistics = true;

    // Google Drive ID Validator
    @track showValidator = false;
    @track driveIdInput = '';
    @track validationResult = null;
    @track isValidating = false;

    // View mode
    @track viewMode = 'grid'; // 'grid' or 'table'

    /**
     * Component initialization
     */
    connectedCallback() {
        this.checkCEBAccess();
        this.loadCategories();
        this.loadStatistics();
        this.loadFiles();
    }

    /**
     * Check if user is CEB officer
     */
    checkCEBAccess() {
        isCEBOfficer()
            .then(result => {
                this.isCEB = result;
                if (!result) {
                    this.showErrorToast('Access Denied: CEB Officers Only');
                }
            })
            .catch(error => {
                console.error('Error checking CEB access:', error);
                this.isCEB = false;
            });
    }

    /**
     * Load available categories
     */
    loadCategories() {
        getCategories()
            .then(result => {
                const options = [{ label: 'All Categories', value: 'All' }];
                result.forEach(category => {
                    options.push({ label: category, value: category });
                });
                this.categoryOptions = options;
            })
            .catch(error => {
                console.error('Error loading categories:', error);
            });
    }

    /**
     * Load file statistics
     */
    loadStatistics() {
        getFileStatistics()
            .then(result => {
                this.stats = result;
            })
            .catch(error => {
                console.error('Error loading statistics:', error);
            });
    }

    /**
     * Load files from Apex
     */
    loadFiles() {
        this.isLoading = true;
        this.error = undefined;

        const category = this.selectedCategory === 'All' ? null : this.selectedCategory;

        getAllFiles({
            includeInactive: this.includeInactive,
            category: category,
            searchTerm: this.searchTerm || null
        })
            .then(result => {
                this.files = result;
                this.filteredFiles = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = this.reduceErrors(error)[0];
                this.files = [];
                this.filteredFiles = [];
                this.showErrorToast(this.error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle category filter change
     */
    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.loadFiles();
    }

    /**
     * Handle include inactive toggle
     */
    handleIncludeInactiveChange(event) {
        this.includeInactive = event.target.checked;
        this.loadFiles();
    }

    /**
     * Handle search input change (with debounce)
     */
    handleSearchChange(event) {
        this.searchTerm = event.detail.value;

        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }

        this.searchTimeout = setTimeout(() => {
            this.loadFiles();
        }, 500);
    }

    /**
     * Handle refresh button click
     */
    handleRefresh() {
        this.loadStatistics();
        this.loadFiles();
        this.showSuccessToast('Data refreshed successfully');
    }

    /**
     * Handle export to CSV
     */
    handleExportCSV() {
        this.isLoading = true;

        exportToCSV({ includeInactive: this.includeInactive })
            .then(csvData => {
                // Create download link
                const blob = new Blob([csvData], { type: 'text/csv' });
                const url = window.URL.createObjectURL(blob);
                const link = document.createElement('a');
                link.href = url;
                link.download = `cvma-google-drive-files-${new Date().toISOString().split('T')[0]}.csv`;
                link.click();
                window.URL.revokeObjectURL(url);

                this.showSuccessToast('CSV export successful');
            })
            .catch(error => {
                this.showErrorToast('Export failed: ' + this.reduceErrors(error)[0]);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Toggle statistics panel
     */
    handleToggleStatistics() {
        this.showStatistics = !this.showStatistics;
    }

    /**
     * Toggle Google Drive ID validator
     */
    handleToggleValidator() {
        this.showValidator = !this.showValidator;
        this.validationResult = null;
        this.driveIdInput = '';
    }

    /**
     * Handle Drive ID input change
     */
    handleDriveIdInput(event) {
        this.driveIdInput = event.target.value;
        this.validationResult = null;
    }

    /**
     * Validate Google Drive ID
     */
    handleValidateDriveId() {
        if (!this.driveIdInput) {
            this.showErrorToast('Please enter a Google Drive ID');
            return;
        }

        this.isValidating = true;
        this.validationResult = null;

        validateGoogleDriveId({ driveId: this.driveIdInput })
            .then(result => {
                this.validationResult = result;
                if (result.valid) {
                    this.showSuccessToast('Valid Google Drive ID');
                } else {
                    this.showWarningToast(result.message);
                }
            })
            .catch(error => {
                this.showErrorToast('Validation error: ' + this.reduceErrors(error)[0]);
            })
            .finally(() => {
                this.isValidating = false;
            });
    }

    /**
     * Toggle view mode
     */
    handleToggleViewMode() {
        this.viewMode = this.viewMode === 'grid' ? 'table' : 'grid';
    }

    /**
     * Computed properties
     */
    get hasFiles() {
        return this.filteredFiles && this.filteredFiles.length > 0;
    }

    get filesCount() {
        return this.filteredFiles ? this.filteredFiles.length : 0;
    }

    get totalFiles() {
        return this.stats.totalFiles || 0;
    }

    get activeFiles() {
        return this.stats.activeFiles || 0;
    }

    get inactiveFiles() {
        return this.stats.inactiveFiles || 0;
    }

    get cebOnlyFiles() {
        return this.stats.cebOnlyFiles || 0;
    }

    get totalSizeMB() {
        return this.stats.totalSizeMB || 0;
    }

    get isGridView() {
        return this.viewMode === 'grid';
    }

    get isTableView() {
        return this.viewMode === 'table';
    }

    get validationSuccess() {
        return this.validationResult && this.validationResult.valid;
    }

    get validationFailed() {
        return this.validationResult && !this.validationResult.valid;
    }

    /**
     * Show success toast
     */
    showSuccessToast(message) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(event);
    }

    /**
     * Show warning toast
     */
    showWarningToast(message) {
        const event = new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning',
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    /**
     * Show error toast
     */
    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    /**
     * Reduce errors to user-friendly messages
     */
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }

        return errors
            .filter(error => !!error)
            .map(error => {
                if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                } else if (typeof error.message === 'string') {
                    return error.message;
                }
                return 'Unknown error occurred';
            });
    }
}
