/**
 * @description Lightning Web Component for CVMA Event RSVP functionality
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 */

import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCurrentUserRSVP from '@salesforce/apex/CVMAEventRSVPController.getCurrentUserRSVP';
import submitRSVP from '@salesforce/apex/CVMAEventRSVPController.submitRSVP';
import getRSVPSummary from '@salesforce/apex/CVMAEventRSVPController.getRSVPSummary';

export default class CvmaEventRSVP extends LightningElement {
    @api eventId;
    @api showSummary = false;
    @api allowNotes = false;
    @api allowPlusOne = false;
    
    @track currentRSVP = null;
    @track rsvpSummary = null;
    @track isLoading = false;
    @track showRSVPForm = false;
    
    // Form fields
    @track selectedResponse = '';
    @track rsvpNotes = '';
    @track bringPlusOne = false;
    @track plusOneName = '';
    
    // Wire current user's RSVP
    @wire(getCurrentUserRSVP, { eventId: '$eventId' })
    wiredCurrentRSVP(result) {
        this.currentRSVPResult = result;
        if (result.data) {
            this.currentRSVP = result.data;
            this.selectedResponse = this.currentRSVP.Response__c;
            this.rsvpNotes = this.currentRSVP.Notes__c || '';
            this.bringPlusOne = this.currentRSVP.Plus_One__c || false;
            this.plusOneName = this.currentRSVP.Plus_One_Name__c || '';
        } else if (result.error) {
            this.handleError('Error loading RSVP status', result.error);
        }
    }
    
    // Wire RSVP summary
    @wire(getRSVPSummary, { eventId: '$eventId' })
    wiredRSVPSummary(result) {
        this.rsvpSummaryResult = result;
        if (result.data) {
            this.rsvpSummary = result.data;
        } else if (result.error) {
            this.handleError('Error loading RSVP summary', result.error);
        }
    }
    
    // Response options for radio buttons
    get responseOptions() {
        return [
            { label: 'Yes - I\'ll be there!', value: 'Yes' },
            { label: 'No - Can\'t make it', value: 'No' },
            { label: 'Maybe - Not sure yet', value: 'Maybe' }
        ];
    }
    
    // Check if user has already responded
    get hasExistingRSVP() {
        return this.currentRSVP != null;
    }
    
    // Get current response display
    get currentResponseDisplay() {
        if (!this.currentRSVP) return 'No response yet';
        
        const responseMap = {
            'Yes': '✅ Yes - I\'ll be there!',
            'No': '❌ No - Can\'t make it',
            'Maybe': '❓ Maybe - Not sure yet'
        };
        
        return responseMap[this.currentRSVP.Response__c] || this.currentRSVP.Response__c;
    }
    
    // Get current response CSS class
    get currentResponseClass() {
        if (!this.currentRSVP) return 'slds-text-color_weak';
        
        const classMap = {
            'Yes': 'slds-text-color_success',
            'No': 'slds-text-color_error',
            'Maybe': 'slds-text-color_default'
        };
        
        return classMap[this.currentRSVP.Response__c] || 'slds-text-color_default';
    }
    
    // Show/hide plus one name field
    get showPlusOneName() {
        return this.allowPlusOne && this.bringPlusOne;
    }
    
    // Check if submit button should be enabled
    get isSubmitDisabled() {
        return this.isLoading || !this.selectedResponse || 
               (this.bringPlusOne && !this.plusOneName);
    }
    
    // Handle RSVP button click
    handleRSVPClick() {
        this.showRSVPForm = true;
        if (this.hasExistingRSVP) {
            // Pre-populate form with existing values
            this.selectedResponse = this.currentRSVP.Response__c;
            this.rsvpNotes = this.currentRSVP.Notes__c || '';
            this.bringPlusOne = this.currentRSVP.Plus_One__c || false;
            this.plusOneName = this.currentRSVP.Plus_One_Name__c || '';
        }
    }
    
    // Handle cancel button click
    handleCancel() {
        this.showRSVPForm = false;
        this.resetForm();
    }
    
    // Handle response selection change
    handleResponseChange(event) {
        this.selectedResponse = event.detail.value;
    }
    
    // Handle notes change
    handleNotesChange(event) {
        this.rsvpNotes = event.target.value;
    }
    
    // Handle plus one checkbox change
    handlePlusOneChange(event) {
        this.bringPlusOne = event.target.checked;
        if (!this.bringPlusOne) {
            this.plusOneName = '';
        }
    }
    
    // Handle plus one name change
    handlePlusOneNameChange(event) {
        this.plusOneName = event.target.value;
    }
    
    // Handle RSVP submission
    async handleSubmit() {
        if (!this.selectedResponse) {
            this.showToast('Error', 'Please select a response', 'error');
            return;
        }
        
        if (this.bringPlusOne && !this.plusOneName) {
            this.showToast('Error', 'Please enter your guest\'s name', 'error');
            return;
        }
        
        this.isLoading = true;
        
        try {
            const result = await submitRSVP({
                eventId: this.eventId,
                response: this.selectedResponse,
                notes: this.rsvpNotes,
                plusOne: this.bringPlusOne,
                plusOneName: this.plusOneName
            });
            
            this.showToast('Success', result, 'success');
            this.showRSVPForm = false;
            
            // Refresh data
            await Promise.all([
                refreshApex(this.currentRSVPResult),
                refreshApex(this.rsvpSummaryResult)
            ]);
            
            // Dispatch custom event for parent components
            this.dispatchEvent(new CustomEvent('rsvpsubmitted', {
                detail: {
                    eventId: this.eventId,
                    response: this.selectedResponse,
                    plusOne: this.bringPlusOne
                }
            }));
            
        } catch (error) {
            this.handleError('Error submitting RSVP', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Handle quick RSVP (Yes/No buttons)
    async handleQuickRSVP(event) {
        const response = event.target.dataset.response;
        this.selectedResponse = response;
        
        // For "Yes" response, check if plus one is allowed
        if (response === 'Yes' && this.allowPlusOne) {
            this.showRSVPForm = true;
            return;
        }
        
        // For "No" or "Maybe", submit immediately
        await this.handleSubmit();
    }
    
    // Reset form to default values
    resetForm() {
        this.selectedResponse = '';
        this.rsvpNotes = '';
        this.bringPlusOne = false;
        this.plusOneName = '';
    }
    
    // Handle errors consistently
    handleError(title, error) {
        console.error(title, error);
        let message = 'An unexpected error occurred. Please try again.';
        
        if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }
        
        this.showToast(title, message, 'error');
    }
    
    // Show toast messages
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: variant === 'error' ? 'sticky' : 'dismissable'
        });
        this.dispatchEvent(event);
    }
}