/**
 * @description Lightning Web Component for Officer Review of Guest Requests
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * Provides officers with the ability to:
 * - View pending guest requests
 * - Approve or deny requests
 * - Add response notes
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPendingGuestRequests from '@salesforce/apex/CVMAGuestEventController.getPendingGuestRequests';
import processGuestRequest from '@salesforce/apex/CVMAGuestEventController.processGuestRequest';

export default class CvmaGuestRequestReview extends LightningElement {
    @track pendingRequests = [];
    @track showReviewModal = false;
    @track selectedRequest = null;
    @track isLoading = false;
    @track isProcessing = false;
    @track responseNotes = '';

    // Wire to get pending requests
    @wire(getPendingGuestRequests)
    wiredRequests(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.pendingRequests = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load guest requests: ' + this.getErrorMessage(result.error), 'error');
        }
    }

    get hasRequests() {
        return this.pendingRequests && this.pendingRequests.length > 0;
    }

    get formattedRequests() {
        return this.pendingRequests.map(request => ({
            ...request,
            formattedRequestDate: this.formatDateTime(request.requestDate),
            formattedEventDate: this.formatDate(request.eventDate),
            veteranStatusLabel: request.veteranStatus ? 'Yes' : 'No'
        }));
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    formatDateTime(dateTimeString) {
        if (!dateTimeString) return '';
        const date = new Date(dateTimeString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    handleReviewRequest(event) {
        const requestId = event.target.dataset.requestId;
        this.selectedRequest = this.pendingRequests.find(r => r.requestId === requestId);
        if (this.selectedRequest) {
            this.responseNotes = '';
            this.showReviewModal = true;
        }
    }

    handleNotesChange(event) {
        this.responseNotes = event.target.value;
    }

    async handleApproveRequest() {
        await this.processRequest(true);
    }

    async handleDenyRequest() {
        await this.processRequest(false);
    }

    async processRequest(approved) {
        this.isProcessing = true;

        try {
            await processGuestRequest({
                requestId: this.selectedRequest.requestId,
                approved: approved,
                responseNotes: this.responseNotes
            });

            this.showToast('Success',
                `Guest request has been ${approved ? 'approved' : 'denied'} successfully. The guest will be notified via email.`,
                'success');

            this.showReviewModal = false;
            this.selectedRequest = null;
            this.responseNotes = '';

            // Refresh the list
            await refreshApex(this.wiredRequestsResult);

        } catch (error) {
            this.showToast('Error',
                `Failed to ${approved ? 'approve' : 'deny'} request: ` + this.getErrorMessage(error),
                'error');
        } finally {
            this.isProcessing = false;
        }
    }

    handleCloseModal() {
        this.showReviewModal = false;
        this.selectedRequest = null;
        this.responseNotes = '';
    }

    async handleRefreshRequests() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredRequestsResult);
        } catch (error) {
            this.showToast('Error', 'Failed to refresh requests: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    getErrorMessage(error) {
        if (error && error.body) {
            if (error.body.message) {
                return error.body.message;
            } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors[0].message;
            }
        }
        return error.message || 'Unknown error occurred';
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get requestCountLabel() {
        const count = this.pendingRequests.length;
        return count === 1 ? '1 Pending Request' : `${count} Pending Requests`;
    }
}
