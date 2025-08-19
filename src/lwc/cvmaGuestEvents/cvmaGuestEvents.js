/**
 * @description Lightning Web Component for Guest Event Access and Registration
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 * 
 * Provides guest users with the ability to:
 * - View public CVMA events
 * - Submit attendance requests
 * - Track request status
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPublicEvents from '@salesforce/apex/CVMAGuestEventController.getPublicEvents';
import submitGuestRequest from '@salesforce/apex/CVMAGuestEventController.submitGuestRequest';
import getGuestRequestStatus from '@salesforce/apex/CVMAGuestEventController.getGuestRequestStatus';

export default class CvmaGuestEvents extends LightningElement {
    @track publicEvents = [];
    @track showRequestModal = false;
    @track showStatusModal = false;
    @track selectedEvent = null;
    @track guestRequestId = null;
    @track guestRequestStatus = null;
    @track isLoading = false;
    @track isSubmitting = false;

    // Form fields
    @track guestInfo = {
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        veteranStatus: false,
        emergencyContact: '',
        additionalInfo: ''
    };

    // Wire to get public events
    @wire(getPublicEvents)
    wiredEvents(result) {
        this.wiredEventsResult = result;
        if (result.data) {
            this.publicEvents = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load public events: ' + this.getErrorMessage(result.error), 'error');
        }
    }

    get hasEvents() {
        return this.publicEvents && this.publicEvents.length > 0;
    }

    get formattedEvents() {
        return this.publicEvents.map(event => ({
            ...event,
            formattedStartDate: this.formatDate(event.startDate),
            formattedEndDate: event.endDate ? this.formatDate(event.endDate) : null,
            canRequest: event.allowsGuests
        }));
    }

    get isRequestFormValid() {
        return this.guestInfo.firstName && 
               this.guestInfo.lastName && 
               this.guestInfo.email && 
               this.guestInfo.phone;
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

    handleRequestAttendance(event) {
        const eventId = event.target.dataset.eventId;
        this.selectedEvent = this.publicEvents.find(e => e.eventId === eventId);
        if (this.selectedEvent) {
            this.showRequestModal = true;
        }
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.guestInfo = { ...this.guestInfo, [field]: value };
    }

    async handleSubmitRequest() {
        if (!this.isRequestFormValid) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        this.isSubmitting = true;

        try {
            const requestId = await submitGuestRequest({
                eventId: this.selectedEvent.eventId,
                guestInfo: this.guestInfo
            });

            this.guestRequestId = requestId;
            this.showRequestModal = false;
            this.resetForm();
            
            this.showToast('Success', 
                'Your attendance request has been submitted successfully. You will receive an email notification once it has been reviewed.', 
                'success');

            // Optionally show status immediately
            this.handleCheckStatus();

        } catch (error) {
            this.showToast('Error', 'Failed to submit request: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    async handleCheckStatus() {
        if (!this.guestRequestId) {
            this.showToast('Error', 'No request ID available', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const status = await getGuestRequestStatus({ requestId: this.guestRequestId });
            this.guestRequestStatus = status;
            this.showStatusModal = true;
        } catch (error) {
            this.showToast('Error', 'Failed to retrieve status: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCloseModal() {
        this.showRequestModal = false;
        this.showStatusModal = false;
        this.selectedEvent = null;
        this.resetForm();
    }

    resetForm() {
        this.guestInfo = {
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
            veteranStatus: false,
            emergencyContact: '',
            additionalInfo: ''
        };
    }

    async handleRefreshEvents() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredEventsResult);
        } catch (error) {
            this.showToast('Error', 'Failed to refresh events: ' + this.getErrorMessage(error), 'error');
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

    get statusBadgeClass() {
        if (!this.guestRequestStatus) return 'slds-badge';
        
        switch (this.guestRequestStatus.status) {
            case 'Pending':
                return 'slds-badge slds-badge_lightest';
            case 'Approved':
                return 'slds-badge slds-theme_success';
            case 'Denied':
                return 'slds-badge slds-theme_error';
            case 'Attended':
                return 'slds-badge slds-theme_info';
            default:
                return 'slds-badge';
        }
    }

    get formattedRequestDate() {
        if (!this.guestRequestStatus || !this.guestRequestStatus.requestDate) return '';
        return new Date(this.guestRequestStatus.requestDate).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    get formattedResponseDate() {
        if (!this.guestRequestStatus || !this.guestRequestStatus.responseDate) return '';
        return new Date(this.guestRequestStatus.responseDate).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
}