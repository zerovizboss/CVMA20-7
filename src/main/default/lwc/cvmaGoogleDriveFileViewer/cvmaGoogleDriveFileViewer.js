/**
 * CVMA Google Drive File Viewer Component
 * Epic #12, User Story #88
 *
 * Displays CVMA documents from Google Drive with:
 * - Category filtering
 * - Search functionality
 * - CEB permission enforcement
 * - Responsive design
 *
 * @author Claude Code
 * @date October 2025
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFiles from '@salesforce/apex/CVMAGoogleDriveFileController.getFiles';
import getCategories from '@salesforce/apex/CVMAGoogleDriveFileController.getCategories';
import checkCEBAccess from '@salesforce/apex/CVMAGoogleDriveFileController.checkCEBAccess';

export default class CvmaGoogleDriveFileViewer extends LightningElement {
    // State
    @track files = [];
    @track error;
    @track isLoading = true;
    @track isCEBOfficer = false;

    // Filters
    @track selectedCategory = 'All';
    @track searchTerm = '';

    // Category options for combobox
    @track categoryOptions = [
        { label: 'All Categories', value: 'All' }
    ];

    /**
     * Component initialization
     */
    connectedCallback() {
        this.loadCategories();
        this.checkCEBStatus();
        this.loadFiles();
    }

    /**
     * Check if user is CEB officer
     */
    checkCEBStatus() {
        checkCEBAccess()
            .then(result => {
                this.isCEBOfficer = result;
            })
            .catch(error => {
                console.error('Error checking CEB access:', error);
                this.isCEBOfficer = false;
            });
    }

    /**
     * Load available categories
     */
    loadCategories() {
        getCategories()
            .then(result => {
                // Build category options
                const options = [{ label: 'All Categories', value: 'All' }];

                result.forEach(category => {
                    options.push({
                        label: category,
                        value: category
                    });
                });

                this.categoryOptions = options;
            })
            .catch(error => {
                console.error('Error loading categories:', error);
                this.showErrorToast('Error loading categories');
            });
    }

    /**
     * Load files from Apex
     */
    loadFiles() {
        this.isLoading = true;
        this.error = undefined;

        const category = this.selectedCategory === 'All' ? null : this.selectedCategory;
        const search = this.searchTerm || null;

        getFiles({ category: category, searchTerm: search })
            .then(result => {
                this.files = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = this.reduceErrors(error)[0];
                this.files = [];
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
     * Handle search input change (with debounce)
     */
    handleSearchChange(event) {
        this.searchTerm = event.detail.value;

        // Clear existing timeout
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }

        // Debounce search by 500ms
        this.searchTimeout = setTimeout(() => {
            this.loadFiles();
        }, 500);
    }

    /**
     * Handle open file button click
     */
    handleOpenFile(event) {
        const link = event.currentTarget.dataset.link;
        if (link) {
            window.open(link, '_blank');
        }
    }

    /**
     * Get computed properties
     */
    get hasFiles() {
        return this.files && this.files.length > 0;
    }

    get filesCount() {
        return this.files ? this.files.length : 0;
    }

    /**
     * Show error toast notification
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
                // Apex error
                if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // Generic error
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // Unknown error
                return 'Unknown error occurred';
            });
    }
}
