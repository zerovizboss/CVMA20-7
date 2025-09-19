import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getAllEvents from '@salesforce/apex/CVMAEventManagementController.getAllEvents';
import createEvent from '@salesforce/apex/CVMAEventManagementController.createEvent';
import updateEvent from '@salesforce/apex/CVMAEventManagementController.updateEvent';
import deleteEvent from '@salesforce/apex/CVMAEventManagementController.deleteEvent';
import getEventDetails from '@salesforce/apex/CVMAEventManagementController.getEventDetails';
import getEventTypes from '@salesforce/apex/CVMAEventManagementController.getEventTypes';
import getEventStatuses from '@salesforce/apex/CVMAEventManagementController.getEventStatuses';

export default class CvmaEventManagement extends LightningElement {
    @track events = [];
    @track isLoading = false;
    @track showModal = false;
    @track showDetailsModal = false;
    @track selectedEvent = null;
    @track isSubmitting = false;
    @track isEditing = false;
    @track eventTypes = [];
    @track eventStatuses = [];

    // Form data
    @track formData = {
        name: '',
        description: '',
        startDate: '',
        endDate: '',
        eventType: '',
        status: 'Planned',
        location: '',
        capacity: null,
        isRecurring: false,
        recurrenceType: '',
        recurrenceCount: null,
        endRecurrenceDate: ''
    };

    // Toast properties
    @track toastMessage = '';
    @track toastVariant = '';
    @track toastIcon = '';
    @track toastClass = '';

    // Data table columns
    columns = [
        {
            label: 'Event Name',
            fieldName: 'Name',
            type: 'text',
            sortable: true
        },
        {
            label: 'Start Date',
            fieldName: 'StartDate',
            type: 'date',
            sortable: true
        },
        {
            label: 'End Date',
            fieldName: 'EndDate',
            type: 'date',
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text'
        },
        {
            label: 'Yes RSVPs',
            fieldName: 'yesCount',
            type: 'number'
        },
        {
            label: 'Maybe RSVPs',
            fieldName: 'maybeCount',
            type: 'number'
        },
        {
            label: 'Total RSVPs',
            fieldName: 'totalRSVPs',
            type: 'number'
        },
        {
            label: 'Available Spots',
            fieldName: 'availableSpots',
            type: 'number'
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View Details', name: 'view_details' },
                    { label: 'Edit', name: 'edit' },
                    { label: 'Cancel Event', name: 'cancel' },
                    { label: 'Delete', name: 'delete' }
                ]
            }
        }
    ];

    // RSVP Details columns
    rsvpColumns = [
        {
            label: 'Member Name',
            fieldName: 'Member__r.Name',
            type: 'text'
        },
        {
            label: 'Response',
            fieldName: 'Response__c',
            type: 'text'
        },
        {
            label: 'RSVP Date',
            fieldName: 'RSVP_Date__c',
            type: 'date'
        },
        {
            label: 'Plus One',
            fieldName: 'Plus_One__c',
            type: 'boolean'
        },
        {
            label: 'Plus One Name',
            fieldName: 'Plus_One_Name__c',
            type: 'text'
        },
        {
            label: 'Notes',
            fieldName: 'Notes__c',
            type: 'text'
        }
    ];

    // Wire methods
    wiredEventsResult;

    @wire(getAllEvents)
    wiredEvents(result) {
        this.wiredEventsResult = result;
        const { error, data } = result;
        if (data) {
            this.events = data.map(wrapper => ({
                Id: wrapper.event.Id,
                Name: wrapper.event.Name,
                Description: wrapper.event.Description,
                StartDate: wrapper.event.StartDate,
                EndDate: wrapper.event.EndDate,
                Status: wrapper.event.Status,
                yesCount: wrapper.yesCount || 0,
                noCount: wrapper.noCount || 0,
                maybeCount: wrapper.maybeCount || 0,
                totalRSVPs: wrapper.totalRSVPs || 0,
                availableSpots: wrapper.availableSpots === -1 ? 'Unlimited' : wrapper.availableSpots
            }));
            this.isLoading = false;
        } else if (error) {
            this.showToast('Error', 'Unable to load events: ' + error.body.message, 'error');
            this.isLoading = false;
        }
    }

    @wire(getEventTypes)
    wiredEventTypes({ error, data }) {
        if (data) {
            this.eventTypes = data.map(type => ({ label: type, value: type }));
        } else if (error) {
            console.error('Error loading event types:', error);
        }
    }

    @wire(getEventStatuses)
    wiredEventStatuses({ error, data }) {
        if (data) {
            this.eventStatuses = data.map(status => ({ label: status, value: status }));
        } else if (error) {
            console.error('Error loading event statuses:', error);
        }
    }

    // Computed properties
    get modalTitle() {
        return this.isEditing ? 'Edit Event' : 'Create New Event';
    }

    get submitButtonLabel() {
        return this.isEditing ? 'Update Event' : 'Create Event';
    }

    get eventTypeOptions() {
        return this.eventTypes;
    }

    get statusOptions() {
        return this.eventStatuses;
    }

    get recurrenceOptions() {
        return [
            { label: 'Weekly', value: 'weekly' },
            { label: 'Monthly', value: 'monthly' },
            { label: 'Yearly', value: 'yearly' }
        ];
    }

    get availableSpotsDisplay() {
        return this.selectedEvent?.availableSpots === -1 ? 'Unlimited' : this.selectedEvent?.availableSpots;
    }

    // Event handlers
    connectedCallback() {
        this.isLoading = true;
    }

    openCreateModal() {
        this.resetForm();
        this.isEditing = false;
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.resetForm();
    }

    closeDetailsModal() {
        this.showDetailsModal = false;
        this.selectedEvent = null;
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;

        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        }

        this.formData = { ...this.formData, [field]: value };
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view_details':
                this.viewEventDetails(row.Id);
                break;
            case 'edit':
                this.editEvent(row);
                break;
            case 'cancel':
                this.cancelEvent(row.Id);
                break;
            case 'delete':
                this.deleteEventHandler(row.Id);
                break;
        }
    }

    async viewEventDetails(eventId) {
        try {
            this.isLoading = true;
            const result = await getEventDetails({ eventId: eventId });
            this.selectedEvent = result;
            this.showDetailsModal = true;
        } catch (error) {
            this.showToast('Error', 'Unable to load event details: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    editEvent(row) {
        this.formData = {
            id: row.Id,
            name: row.Name,
            description: row.Description,
            startDate: row.StartDate,
            endDate: row.EndDate,
            status: row.Status,
            location: '',
            capacity: null,
            isRecurring: false,
            recurrenceType: '',
            recurrenceCount: null,
            endRecurrenceDate: ''
        };
        this.isEditing = true;
        this.showModal = true;
    }

    editEventFromDetails() {
        if (this.selectedEvent) {
            this.editEvent({
                Id: this.selectedEvent.event.Id,
                Name: this.selectedEvent.event.Name,
                Description: this.selectedEvent.event.Description,
                StartDate: this.selectedEvent.event.StartDate,
                EndDate: this.selectedEvent.event.EndDate,
                Status: this.selectedEvent.event.Status
            });
            this.closeDetailsModal();
        }
    }

    async cancelEvent(eventId) {
        const reason = prompt('Please provide a reason for cancelling this event:');
        if (!reason) return;

        try {
            this.isLoading = true;
            await updateEvent({
                eventId: eventId,
                eventData: { status: 'Aborted', description: 'CANCELLED: ' + reason }
            });
            this.showToast('Success', 'Event cancelled successfully', 'success');
            this.refreshEvents();
        } catch (error) {
            this.showToast('Error', 'Unable to cancel event: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async deleteEventHandler(eventId) {
        if (!confirm('Are you sure you want to delete this event? This action cannot be undone.')) {
            return;
        }

        try {
            this.isLoading = true;
            await deleteEvent({ eventId: eventId });
            this.showToast('Success', 'Event deleted successfully', 'success');
            this.refreshEvents();
        } catch (error) {
            this.showToast('Error', 'Unable to delete event: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async submitForm() {
        try {
            this.isSubmitting = true;

            // Validate required fields
            if (!this.formData.name || !this.formData.startDate) {
                this.showToast('Error', 'Please fill in all required fields', 'error');
                return;
            }

            if (this.isEditing) {
                await updateEvent({
                    eventId: this.formData.id,
                    eventData: this.formData
                });
                this.showToast('Success', 'Event updated successfully', 'success');
            } else {
                await createEvent({ eventData: this.formData });
                this.showToast('Success', 'Event created successfully', 'success');
            }

            this.closeModal();
            this.refreshEvents();

        } catch (error) {
            this.showToast('Error', 'Unable to save event: ' + error.body.message, 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    refreshEvents() {
        this.isLoading = true;
        return refreshApex(this.wiredEventsResult);
    }

    resetForm() {
        this.formData = {
            name: '',
            description: '',
            startDate: '',
            endDate: '',
            eventType: '',
            status: 'Planned',
            location: '',
            capacity: null,
            isRecurring: false,
            recurrenceType: '',
            recurrenceCount: null,
            endRecurrenceDate: ''
        };
        this.isEditing = false;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
