/**
 * @description Guest User-friendly Lightning Calendar component for CVMA events
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-10
 *
 * Standard Feature Integration for Guest Access:
 * - Uses CVMAGuestCalendarHelper for limited, public event data
 * - Maintains security boundaries while providing calendar functionality
 * - Read-only interface appropriate for community guest users
 *
 * Multi-Agent Development:
 * - Strategic Agent (Claude): Guest UX design and security boundaries
 * - Tactical Agent (Copilot): Community deployment and testing
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import Guest-friendly calendar methods
import getPublicCalendarEvents from '@salesforce/apex/CVMAGuestCalendarHelper.getPublicCalendarEvents';
import getPublicEventDetails from '@salesforce/apex/CVMAGuestCalendarHelper.getPublicEventDetails';
import getCurrentMonthPublicEvents from '@salesforce/apex/CVMAGuestCalendarHelper.getCurrentMonthPublicEvents';

export default class CvmaGuestCalendar extends LightningElement {

    @track currentDate = new Date();
    @track selectedDate = null;
    @track showDetailsModal = false;
    @track isLoading = false;
    @track selectedEvent = null;
    @track eventDetails = null;

    // Calendar data
    publicEventsResult;
    @track calendarEvents = [];

    // Wire current month's public events
    @wire(getCurrentMonthPublicEvents)
    wiredPublicEvents(result) {
        this.publicEventsResult = result;
        if (result.data) {
            this.calendarEvents = this.processEventsForCalendar(result.data);
        } else if (result.error) {
            console.error('Error loading public events:', result.error);
            this.calendarEvents = [];
        }
    }

    // Computed properties
    get monthYearDisplay() {
        return this.currentDate.toLocaleDateString('en-US', {
            month: 'long',
            year: 'numeric'
        });
    }

    get monthStartDate() {
        return new Date(this.currentDate.getFullYear(), this.currentDate.getMonth(), 1);
    }

    get monthEndDate() {
        return new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 0);
    }

    get hasEvents() {
        return this.calendarEvents && this.calendarEvents.length > 0;
    }

    get noEventsMessage() {
        return `No public events scheduled for ${this.monthYearDisplay}`;
    }

    // Event handlers
    handlePreviousMonth() {
        this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1);
        this.loadMonthEvents();
    }

    handleNextMonth() {
        this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1);
        this.loadMonthEvents();
    }

    handleToday() {
        this.currentDate = new Date();
        this.loadMonthEvents();
    }

    async handleEventClick(event) {
        const eventId = event.currentTarget.dataset.eventId;
        if (!eventId) return;

        this.isLoading = true;
        this.selectedEvent = this.calendarEvents.find(evt => evt.Id === eventId);

        try {
            this.eventDetails = await getPublicEventDetails({ eventId: eventId });
            this.showDetailsModal = true;
        } catch (error) {
            this.handleError('Error loading event details', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleCloseModal() {
        this.showDetailsModal = false;
        this.selectedEvent = null;
        this.eventDetails = null;
    }

    // Utility methods
    async loadMonthEvents() {
        this.isLoading = true;

        try {
            const events = await getPublicCalendarEvents({
                startDate: this.monthStartDate,
                endDate: this.monthEndDate
            });

            this.calendarEvents = this.processEventsForCalendar(events);
        } catch (error) {
            this.handleError('Error loading calendar events', error);
        } finally {
            this.isLoading = false;
        }
    }

    processEventsForCalendar(events) {
        if (!events) return [];

        return events.map(event => {
            return {
                ...event,
                displayDate: this.formatEventDate(event.StartDateTime),
                displayTime: this.formatEventTime(event.StartDateTime, event.EndDateTime),
                isToday: this.isEventToday(event.StartDateTime),
                isUpcoming: this.isEventUpcoming(event.StartDateTime)
            };
        });
    }

    formatEventDate(dateTimeString) {
        if (!dateTimeString) return '';

        try {
            const date = new Date(dateTimeString);
            return date.toLocaleDateString('en-US', {
                weekday: 'short',
                month: 'short',
                day: 'numeric'
            });
        } catch (e) {
            return dateTimeString;
        }
    }

    formatEventTime(startDateTime, endDateTime) {
        if (!startDateTime) return '';

        try {
            const startDate = new Date(startDateTime);
            const startTime = startDate.toLocaleTimeString('en-US', {
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });

            if (endDateTime) {
                const endDate = new Date(endDateTime);
                const endTime = endDate.toLocaleTimeString('en-US', {
                    hour: 'numeric',
                    minute: '2-digit',
                    hour12: true
                });
                return `${startTime} - ${endTime}`;
            }

            return startTime;
        } catch (e) {
            return '';
        }
    }

    isEventToday(dateTimeString) {
        if (!dateTimeString) return false;

        try {
            const eventDate = new Date(dateTimeString);
            const today = new Date();
            return eventDate.toDateString() === today.toDateString();
        } catch (e) {
            return false;
        }
    }

    isEventUpcoming(dateTimeString) {
        if (!dateTimeString) return false;

        try {
            const eventDate = new Date(dateTimeString);
            const now = new Date();
            return eventDate > now;
        } catch (e) {
            return false;
        }
    }

    handleError(title, error) {
        console.error(title + ':', error);

        let message = 'Unable to load calendar information';
        if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }

        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'pester'
        }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}
