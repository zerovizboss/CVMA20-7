/**
 * @description Lightning Web Component for CVMA Chapter Announcements System
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAnnouncements from '@salesforce/apex/CVMAAnnouncementController.getAnnouncements';
import createAnnouncement from '@salesforce/apex/CVMAAnnouncementController.createAnnouncement';
import updateAnnouncement from '@salesforce/apex/CVMAAnnouncementController.updateAnnouncement';
import archiveAnnouncement from '@salesforce/apex/CVMAAnnouncementController.archiveAnnouncement';
import incrementViewCount from '@salesforce/apex/CVMAAnnouncementController.incrementViewCount';
import getCategoryOptions from '@salesforce/apex/CVMAAnnouncementController.getCategoryOptions';
import getPriorityOptions from '@salesforce/apex/CVMAAnnouncementController.getPriorityOptions';
import getTargetAudienceOptions from '@salesforce/apex/CVMAAnnouncementController.getTargetAudienceOptions';

const COLUMNS = [
    {
        label: 'Title',
        fieldName: 'Title__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'titleClass' } }
    },
    {
        label: 'Category',
        fieldName: 'Category__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'categoryClass' } }
    },
    {
        label: 'Priority',
        fieldName: 'Priority__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'priorityClass' } }
    },
    {
        label: 'Author',
        fieldName: 'authorName',
        type: 'text'
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'statusClass' } }
    },
    {
        label: 'Published',
        fieldName: 'Publish_Date__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    {
        label: 'Views',
        fieldName: 'View_Count__c',
        type: 'number'
    },
    {
        type: 'action',
        typeAttributes: { rowActions: [] }
    }
];

export default class CvmaAnnouncements extends LightningElement {
    // Public properties
    columns = COLUMNS;

    // Tracked properties
    @track announcements = [];
    @track selectedAnnouncement = null;
    @track isLoading = false;
    @track error = null;
    @track currentView = 'published';
    @track pageNumber = 0;
    @track pageSize = 10;
    @track totalCount = 0;
    @track hasMore = false;

    // Create/Edit announcement properties
    @track showAnnouncementModal = false;
    @track showViewModal = false;
    @track editMode = false;
    @track announcement = {
        id: null,
        title: '',
        content: '',
        priority: 'Normal',
        category: 'General',
        targetAudience: 'All Members',
        status: 'Draft',
        publishDate: null,
        expirationDate: null,
        isEmergency: false,
        sendEmailNotification: false,
        bannerImageUrl: ''
    };

    // Options
    @track categoryOptions = [];
    @track priorityOptions = [];
    @track targetAudienceOptions = [];
    @track isComposing = false;

    // Wired methods
    wiredAnnouncementsResult;

    @wire(getAnnouncements, { 
        pageSize: '$pageSize', 
        pageNumber: '$pageNumber', 
        announcementType: '$currentView' 
    })
    wiredAnnouncements(result) {
        this.wiredAnnouncementsResult = result;
        if (result.data) {
            this.handleAnnouncementsSuccess(result.data);
        } else if (result.error) {
            this.handleError('Failed to load announcements', result.error);
        }
    }

    @wire(getCategoryOptions)
    wiredCategoryOptions({ error, data }) {
        if (data) {
            this.categoryOptions = data;
        } else if (error) {
            console.error('Error loading category options:', error);
        }
    }

    @wire(getPriorityOptions)
    wiredPriorityOptions({ error, data }) {
        if (data) {
            this.priorityOptions = data;
        } else if (error) {
            console.error('Error loading priority options:', error);
        }
    }

    @wire(getTargetAudienceOptions)
    wiredTargetAudienceOptions({ error, data }) {
        if (data) {
            this.targetAudienceOptions = data;
        } else if (error) {
            console.error('Error loading target audience options:', error);
        }
    }

    // Getters
    get publishedActive() {
        return this.currentView === 'published' ? 'slds-is-active' : '';
    }

    get draftActive() {
        return this.currentView === 'draft' ? 'slds-is-active' : '';
    }

    get archivedActive() {
        return this.currentView === 'archived' ? 'slds-is-active' : '';
    }

    get allActive() {
        return this.currentView === 'all' ? 'slds-is-active' : '';
    }

    get hasAnnouncements() {
        return this.announcements && this.announcements.length > 0;
    }

    get pageInfo() {
        if (this.totalCount === 0) return '0 announcements';
        const start = (this.pageNumber * this.pageSize) + 1;
        const end = Math.min(start + this.pageSize - 1, this.totalCount);
        return `${start}-${end} of ${this.totalCount} announcements`;
    }

    get isFirstPage() {
        return this.pageNumber === 0;
    }

    get isLastPage() {
        return !this.hasMore;
    }

    get modalTitle() {
        return this.editMode ? 'Edit Announcement' : 'Create Announcement';
    }

    get publishDateMin() {
        return new Date().toISOString().slice(0, 16);
    }

    get statusOptions() {
        return [
            { label: 'Draft', value: 'Draft' },
            { label: 'Published', value: 'Published' },
            { label: 'Archived', value: 'Archived' }
        ];
    }

    get selectedAnnouncementFormatted() {
        if (!this.selectedAnnouncement) return null;
        
        return {
            ...this.selectedAnnouncement,
            formattedPublishDate: this.selectedAnnouncement.Publish_Date__c ? 
                new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }).format(new Date(this.selectedAnnouncement.Publish_Date__c)) : 'Not scheduled',
            formattedExpirationDate: this.selectedAnnouncement.Expiration_Date__c ?
                new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                }).format(new Date(this.selectedAnnouncement.Expiration_Date__c)) : 'No expiration'
        };
    }

    // Event handlers
    handleViewChange(event) {
        this.currentView = event.target.dataset.view;
        this.pageNumber = 0;
        this.refreshAnnouncements();
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.viewAnnouncement(selectedRows[0]);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view':
                this.viewAnnouncement(row);
                break;
            case 'edit':
                this.editAnnouncement(row);
                break;
            case 'archive':
                this.archiveSelectedAnnouncement(row.Id);
                break;
        }
    }

    handleCreateClick() {
        this.resetAnnouncementForm();
        this.editMode = false;
        this.showAnnouncementModal = true;
    }

    handleModalCancel() {
        this.showAnnouncementModal = false;
        this.resetAnnouncementForm();
    }

    handleViewModalClose() {
        this.showViewModal = false;
        this.selectedAnnouncement = null;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        if (field) {
            if (event.target.type === 'checkbox') {
                this.announcement[field] = event.target.checked;
            } else {
                this.announcement[field] = event.target.value;
            }
        }
    }

    async handleSaveAnnouncement() {
        if (!this.validateAnnouncement()) {
            return;
        }

        this.isComposing = true;

        try {
            let result;
            
            if (this.editMode) {
                result = await updateAnnouncement({
                    announcementId: this.announcement.id,
                    title: this.announcement.title,
                    content: this.announcement.content,
                    priority: this.announcement.priority,
                    category: this.announcement.category,
                    targetAudience: this.announcement.targetAudience,
                    status: this.announcement.status,
                    publishDate: this.announcement.publishDate,
                    expirationDate: this.announcement.expirationDate,
                    isEmergency: this.announcement.isEmergency,
                    sendEmailNotification: this.announcement.sendEmailNotification,
                    bannerImageUrl: this.announcement.bannerImageUrl
                });
            } else {
                result = await createAnnouncement({
                    title: this.announcement.title,
                    content: this.announcement.content,
                    priority: this.announcement.priority,
                    category: this.announcement.category,
                    targetAudience: this.announcement.targetAudience,
                    publishDate: this.announcement.publishDate,
                    expirationDate: this.announcement.expirationDate,
                    isEmergency: this.announcement.isEmergency,
                    sendEmailNotification: this.announcement.sendEmailNotification,
                    bannerImageUrl: this.announcement.bannerImageUrl
                });
            }

            if (result.success) {
                this.showToast('Success', result.successMessage, 'success');
                this.showAnnouncementModal = false;
                this.resetAnnouncementForm();
                this.refreshAnnouncements();
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.handleError('Failed to save announcement', error);
        } finally {
            this.isComposing = false;
        }
    }

    handlePreviousPage() {
        if (this.pageNumber > 0) {
            this.pageNumber--;
        }
    }

    handleNextPage() {
        if (this.hasMore) {
            this.pageNumber++;
        }
    }

    handleRefresh() {
        this.refreshAnnouncements();
    }

    // Private methods
    async viewAnnouncement(announcement) {
        this.selectedAnnouncement = { ...announcement };
        this.showViewModal = true;

        // Increment view count
        try {
            await incrementViewCount({ announcementId: announcement.Id });
            // Refresh to update view count
            this.refreshAnnouncements();
        } catch (error) {
            // Don't show error for view count failures
            console.warn('View count increment failed:', error);
        }
    }

    editAnnouncement(announcement) {
        this.announcement = {
            id: announcement.Id,
            title: announcement.Title__c || '',
            content: announcement.Content__c || '',
            priority: announcement.Priority__c || 'Normal',
            category: announcement.Category__c || 'General',
            targetAudience: announcement.Target_Audience__c || 'All Members',
            status: announcement.Status__c || 'Draft',
            publishDate: announcement.Publish_Date__c || null,
            expirationDate: announcement.Expiration_Date__c || null,
            isEmergency: announcement.Is_Emergency__c || false,
            sendEmailNotification: announcement.Send_Email_Notification__c || false,
            bannerImageUrl: announcement.Banner_Image_URL__c || ''
        };
        this.editMode = true;
        this.showAnnouncementModal = true;
    }

    async archiveSelectedAnnouncement(announcementId) {
        this.isLoading = true;

        try {
            const result = await archiveAnnouncement({ announcementId });

            if (result.success) {
                this.showToast('Success', result.successMessage, 'success');
                this.refreshAnnouncements();
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.handleError('Failed to archive announcement', error);
        } finally {
            this.isLoading = false;
        }
    }

    validateAnnouncement() {
        if (!this.announcement.title || this.announcement.title.trim().length === 0) {
            this.showToast('Validation Error', 'Title is required', 'error');
            return false;
        }

        if (!this.announcement.content || this.announcement.content.trim().length === 0) {
            this.showToast('Validation Error', 'Content is required', 'error');
            return false;
        }

        if (this.announcement.title.length > 255) {
            this.showToast('Validation Error', 'Title cannot exceed 255 characters', 'error');
            return false;
        }

        if (this.announcement.content.length > 32768) {
            this.showToast('Validation Error', 'Content cannot exceed 32,768 characters', 'error');
            return false;
        }

        if (this.announcement.expirationDate && this.announcement.publishDate) {
            const publishDate = new Date(this.announcement.publishDate);
            const expirationDate = new Date(this.announcement.expirationDate);
            if (expirationDate <= publishDate) {
                this.showToast('Validation Error', 'Expiration date must be after publish date', 'error');
                return false;
            }
        }

        return true;
    }

    resetAnnouncementForm() {
        this.announcement = {
            id: null,
            title: '',
            content: '',
            priority: 'Normal',
            category: 'General',
            targetAudience: 'All Members',
            status: 'Draft',
            publishDate: null,
            expirationDate: null,
            isEmergency: false,
            sendEmailNotification: false,
            bannerImageUrl: ''
        };
    }

    refreshAnnouncements() {
        return refreshApex(this.wiredAnnouncementsResult);
    }

    handleAnnouncementsSuccess(data) {
        if (data.success) {
            this.announcements = this.processAnnouncements(data.announcements);
            this.totalCount = data.totalCount;
            this.hasMore = data.hasMore;
            this.error = null;

            // Set row actions based on current view
            this.updateRowActions();
        } else {
            this.handleError('Failed to load announcements', data.errorMessage);
        }
        this.isLoading = false;
    }

    processAnnouncements(announcements) {
        return announcements.map(announcement => {
            const processed = { ...announcement };

            // Set author name
            processed.authorName = announcement.Author__r ? announcement.Author__r.Name : 'Unknown';

            // Add CSS classes for styling
            processed.titleClass = announcement.Is_Emergency__c ? 'slds-text-color_error slds-text-title_caps' : '';
            processed.categoryClass = this.getCategoryClass(announcement.Category__c);
            processed.priorityClass = this.getPriorityClass(announcement.Priority__c);
            processed.statusClass = this.getStatusClass(announcement.Status__c);

            return processed;
        });
    }

    getCategoryClass(category) {
        switch (category) {
            case 'Safety':
                return 'slds-text-color_error';
            case 'Emergency':
                return 'slds-text-color_error slds-text-title_caps';
            case 'Events':
                return 'slds-text-color_success';
            default:
                return '';
        }
    }

    getPriorityClass(priority) {
        switch (priority) {
            case 'High':
                return 'slds-text-color_warning';
            case 'Urgent':
                return 'slds-text-color_error slds-text-title_caps';
            default:
                return '';
        }
    }

    getStatusClass(status) {
        switch (status) {
            case 'Draft':
                return 'slds-badge slds-badge_lightest';
            case 'Published':
                return 'slds-badge slds-theme_success';
            case 'Archived':
                return 'slds-badge slds-theme_offline';
            default:
                return 'slds-badge';
        }
    }

    updateRowActions() {
        const actions = [];

        actions.push({ label: 'View', name: 'view' });

        if (this.currentView !== 'archived') {
            actions.push({ label: 'Edit', name: 'edit' });
            actions.push({ label: 'Archive', name: 'archive' });
        }

        // Update columns with new actions
        this.columns = [...COLUMNS];
        this.columns[this.columns.length - 1].typeAttributes.rowActions = actions;
    }

    handleError(title, error) {
        console.error(title, error);
        let message = 'An unexpected error occurred';

        if (typeof error === 'string') {
            message = error;
        } else if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }

        this.error = message;
        this.showToast('Error', `${title}: ${message}`, 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}