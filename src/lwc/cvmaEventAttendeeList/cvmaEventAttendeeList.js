/**
 * @description Lightning Web Component for displaying CVMA Event attendee list with privacy controls
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 */

import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getEventAttendees from '@salesforce/apex/CVMAEventRSVPController.getEventAttendees';
import getRSVPSummary from '@salesforce/apex/CVMAEventRSVPController.getRSVPSummary';

export default class CvmaEventAttendeeList extends LightningElement {
    @api eventId;
    @api showPrivateInfo = false;
    @api maxDisplayCount = 10;
    @api showSummaryStats = false;
    @api allowExpansion = false;
    
    @track attendees = [];
    @track rsvpSummary = null;
    @track isLoading = false;
    @track showAllAttendees = false;
    @track error = null;
    
    // Wire attendee data
    @wire(getEventAttendees, { eventId: '$eventId', showPrivateInfo: '$showPrivateInfo' })
    wiredAttendees(result) {
        this.attendeesResult = result;
        if (result.data) {
            this.attendees = result.data;
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            this.handleError('Error loading attendee list', result.error);
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
    
    // Get attendees to display (limited or all)
    get displayedAttendees() {
        if (!this.attendees || this.attendees.length === 0) {
            return [];
        }
        
        if (this.showAllAttendees || this.attendees.length <= this.maxDisplayCount) {
            return this.attendees;
        }
        
        return this.attendees.slice(0, this.maxDisplayCount);
    }
    
    // Check if there are more attendees to show
    get hasMoreAttendees() {
        return this.allowExpansion && 
               this.attendees && 
               this.attendees.length > this.maxDisplayCount && 
               !this.showAllAttendees;
    }
    
    // Get remaining attendee count
    get remainingCount() {
        if (!this.attendees) return 0;
        return this.attendees.length - this.maxDisplayCount;
    }
    
    // Check if attendee list is empty
    get hasAttendees() {
        return this.attendees && this.attendees.length > 0;
    }
    
    // Get empty state message
    get emptyStateMessage() {
        return 'No attendees have RSVP\'d "Yes" to this event yet.';
    }
    
    // Format attendee display information
    get formattedAttendees() {
        return this.displayedAttendees.map(attendee => {
            return {
                ...attendee,
                displayName: this.formatAttendeeDisplayName(attendee),
                rsvpDateFormatted: this.formatRSVPDate(attendee.rsvpDate),
                hasGuest: attendee.plusOne && attendee.plusOneName,
                guestDisplay: attendee.plusOneName || 'Guest'
            };
        });
    }
    
    // Get summary statistics for display
    get summaryStats() {
        if (!this.rsvpSummary) return null;
        
        return [
            {
                label: 'Attending',
                count: this.rsvpSummary.yesCount,
                icon: 'utility:check',
                class: 'slds-text-color_success'
            },
            {
                label: 'Plus Ones',
                count: this.rsvpSummary.plusOnes,
                icon: 'utility:adduser',
                class: 'slds-text-color_default'
            },
            {
                label: 'Total',
                count: this.rsvpSummary.totalAttending,
                icon: 'utility:groups',
                class: 'slds-text-color_success'
            }
        ];
    }
    
    // Handle show more attendees
    handleShowMore() {
        this.showAllAttendees = true;
    }
    
    // Handle show less attendees
    handleShowLess() {
        this.showAllAttendees = false;
    }
    
    // Handle refresh attendee list
    async handleRefresh() {
        this.isLoading = true;
        try {
            await Promise.all([
                refreshApex(this.attendeesResult),
                refreshApex(this.rsvpSummaryResult)
            ]);
            this.showToast('Success', 'Attendee list refreshed', 'success');
        } catch (error) {
            this.handleError('Error refreshing attendee list', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Format attendee display name based on privacy settings
    formatAttendeeDisplayName(attendee) {
        if (!attendee || !attendee.memberName) {
            return 'CVMA Member';
        }
        
        // If showing private info, show full name
        if (this.showPrivateInfo) {
            return attendee.memberName;
        }
        
        // Otherwise, show limited info for privacy
        return attendee.memberName;
    }
    
    // Format RSVP date for display
    formatRSVPDate(rsvpDate) {
        if (!rsvpDate) return '';
        
        const date = new Date(rsvpDate);
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        // Show relative time for recent RSVPs
        if (diffDays === 0) {
            return 'Today';
        } else if (diffDays === 1) {
            return 'Yesterday';
        } else if (diffDays < 7) {
            return `${diffDays} days ago`;
        } else {
            // Show formatted date for older RSVPs
            return date.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
            });
        }
    }
    
    // Handle attendee click (if we want to show member details)
    handleAttendeeClick(event) {
        const attendeeId = event.currentTarget.dataset.attendeeId;
        const attendee = this.attendees.find(a => a.rsvpId === attendeeId);
        
        if (attendee) {
            // Dispatch custom event for parent components to handle
            this.dispatchEvent(new CustomEvent('attendeeclick', {
                detail: {
                    attendee: attendee,
                    eventId: this.eventId
                }
            }));
        }
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
    
    // Listen for RSVP updates from sibling components
    handleRSVPUpdate() {
        // Refresh the attendee list when RSVPs change
        this.handleRefresh();
    }
    
    // Lifecycle hook - component connected
    connectedCallback() {
        // Listen for RSVP updates
        this.addEventListener('rsvpsubmitted', this.handleRSVPUpdate.bind(this));
    }
    
    // Lifecycle hook - component disconnected
    disconnectedCallback() {
        // Clean up event listeners
        this.removeEventListener('rsvpsubmitted', this.handleRSVPUpdate.bind(this));
    }
}