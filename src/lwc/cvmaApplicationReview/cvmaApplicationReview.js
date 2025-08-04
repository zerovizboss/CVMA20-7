import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPendingApplications from '@salesforce/apex/CVMAMembershipApplicationController.getPendingApplications';
import updateApplicationStatus from '@salesforce/apex/CVMAMembershipApplicationController.updateApplicationStatus';

export default class CvmaApplicationReview extends LightningElement {
    @track applications = [];
    @track isLoading = true;
    @track isProcessing = false;
    @track showApplicationModal = false;
    @track showStatusModal = false;
    @track selectedApplication;
    @track reviewNotes = '';
    @track pendingAction = '';
    
    // Summary counts
    @track pendingCount = 0;
    @track approvedCount = 0;
    @track rejectedCount = 0;
    
    wiredApplicationsResult;

    @wire(getPendingApplications)
    wiredApplications(result) {
        this.wiredApplicationsResult = result;
        if (result.data) {
            this.applications = this.processApplicationData(result.data);
            this.pendingCount = this.applications.length;
            this.isLoading = false;
        } else if (result.error) {
            this.handleError('Error loading applications', result.error);
            this.isLoading = false;
        }
    }

    connectedCallback() {
        // Load summary statistics
        this.loadSummaryStats();
    }

    get hasApplications() {
        return this.applications && this.applications.length > 0;
    }

    get statusModalTitle() {
        if (this.pendingAction === 'Approved') {
            return 'Approve Application';
        } else if (this.pendingAction === 'Rejected') {
            return 'Reject Application';
        } else if (this.pendingAction === 'More Information Needed') {
            return 'Request More Information';
        }
        return 'Update Application';
    }

    get confirmDisabled() {
        return !this.reviewNotes || this.reviewNotes.trim().length === 0;
    }

    processApplicationData(applications) {
        return applications.map(app => ({
            ...app,
            applicantName: `${app.firstName} ${app.lastName}`,
            formattedSubmissionDate: this.formatDate(app.submissionDate)
        }));
    }

    formatDate(dateTime) {
        if (!dateTime) return '';
        const date = new Date(dateTime);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    }

    loadSummaryStats() {
        // This would typically be another Apex method to get monthly statistics
        // For now, using placeholder values
        this.approvedCount = 5;
        this.rejectedCount = 2;
    }

    handleViewApplication(event) {
        const applicationId = event.target.dataset.id;
        this.selectedApplication = this.applications.find(app => app.applicationId === applicationId);
        this.showApplicationModal = true;
    }

    handleApprove(event) {
        const applicationId = event.target.dataset.id;
        this.selectedApplication = this.applications.find(app => app.applicationId === applicationId);
        this.pendingAction = 'Approved';
        this.reviewNotes = '';
        this.showStatusModal = true;
    }

    handleReject(event) {
        const applicationId = event.target.dataset.id;
        this.selectedApplication = this.applications.find(app => app.applicationId === applicationId);
        this.pendingAction = 'Rejected';
        this.reviewNotes = '';
        this.showStatusModal = true;
    }

    handleMoreInfo(event) {
        const applicationId = event.target.dataset.id;
        this.selectedApplication = this.applications.find(app => app.applicationId === applicationId);
        this.pendingAction = 'More Information Needed';
        this.reviewNotes = '';
        this.showStatusModal = true;
    }

    handleNotesChange(event) {
        this.reviewNotes = event.target.value;
    }

    async confirmStatusUpdate() {
        if (!this.selectedApplication || !this.reviewNotes.trim()) {
            return;
        }

        this.isProcessing = true;

        try {
            const result = await updateApplicationStatus({
                applicationId: this.selectedApplication.applicationId,
                newStatus: this.pendingAction,
                reviewNotes: this.reviewNotes
            });

            this.showToast('Success', result, 'success');
            this.closeStatusModal();
            
            // Refresh the applications list
            await refreshApex(this.wiredApplicationsResult);
            
            // Update counts
            if (this.pendingAction === 'Approved') {
                this.approvedCount += 1;
            } else if (this.pendingAction === 'Rejected') {
                this.rejectedCount += 1;
            }
            this.pendingCount = Math.max(0, this.pendingCount - 1);

        } catch (error) {
            this.handleError('Error updating application status', error);
        } finally {
            this.isProcessing = false;
        }
    }

    closeApplicationModal() {
        this.showApplicationModal = false;
        this.selectedApplication = null;
    }

    closeStatusModal() {
        this.showStatusModal = false;
        this.selectedApplication = null;
        this.reviewNotes = '';
        this.pendingAction = '';
    }

    handleError(title, error) {
        console.error(title + ':', error);
        let message = 'An unknown error occurred';
        
        if (error?.body?.message) {
            message = error.body.message;
        } else if (error?.message) {
            message = error.message;
        } else if (typeof error === 'string') {
            message = error;
        }
        
        this.showToast(title, message, 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Refresh applications manually
    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredApplicationsResult);
        } catch (error) {
            this.handleError('Error refreshing applications', error);
        } finally {
            this.isLoading = false;
        }
    }
}