import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getListUi } from 'lightning/uiListApi';
import { getRecord, getFieldValue, createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

// Campaign object and fields
import CAMPAIGN_OBJECT from '@salesforce/schema/Campaign';
import CAMPAIGN_NAME from '@salesforce/schema/Campaign.Name';
import CAMPAIGN_DESCRIPTION from '@salesforce/schema/Campaign.Description';
import CAMPAIGN_START_DATE from '@salesforce/schema/Campaign.StartDate';
import CAMPAIGN_END_DATE from '@salesforce/schema/Campaign.EndDate';
import CAMPAIGN_STATUS from '@salesforce/schema/Campaign.Status';
import CAMPAIGN_TYPE from '@salesforce/schema/Campaign.Type';
import CAMPAIGN_NUMBER_SENT from '@salesforce/schema/Campaign.NumberSent';

// Apex methods for server-side logic only
import createRecurringEvents from '@salesforce/apex/CVMAEventControllerLDS.createRecurringEvents';
import getEventStats from '@salesforce/apex/CVMAEventControllerLDS.getEventStats';
import getUpcomingEventsSummary from '@salesforce/apex/CVMAEventControllerLDS.getUpcomingEventsSummary';
import getEventTypes from '@salesforce/apex/CVMAEventControllerLDS.getEventTypes';

export default class CvmaEventManagementLDS extends LightningElement {
    @track showModal = false;
    @track showDetailsModal = false;
    @track selectedEventId = null;
    @track selectedEventStats = null;
    @track isEditing = false;
    @track isSubmitting = false;
    @track eventTypes = [];

    // Form data for create/edit
    @track formData = {
        name: '',
        description: '',
        startDate: '',
        endDate: '',
        status: 'Planned',
        capacity: null,
        isRecurring: false,
        recurrenceType: '',
        recurrenceCount: null,
        endRecurrenceDate: ''
    };

    // Wire LDS to get list of events
    @wire(getListUi, {
        objectApiName: CAMPAIGN_OBJECT,
        listViewApiName: 'AllActiveCampaigns',
        pageSize: 50,
        sortBy: 'StartDate',
        fields: [
            CAMPAIGN_NAME,
            CAMPAIGN_START_DATE,
            CAMPAIGN_END_DATE,
            CAMPAIGN_STATUS,
            CAMPAIGN_NUMBER_SENT
        ]
    })
    wiredEventsList({ error, data }) {
        if (data) {
            // Filter for CVMA Events only
            this.events = data.records.records.filter(record =>
                getFieldValue(record, 'Type') === 'CVMA Event'
            ).map(record => ({
                Id: record.id,
                Name: getFieldValue(record, CAMPAIGN_NAME),
                StartDate: getFieldValue(record, CAMPAIGN_START_DATE),
                EndDate: getFieldValue(record, CAMPAIGN_END_DATE),
                Status: getFieldValue(record, CAMPAIGN_STATUS),
                Capacity: getFieldValue(record, CAMPAIGN_NUMBER_SENT)
            }));
        } else if (error) {
            this.showToast('Error', 'Unable to load events: ' + error.body.message, 'error');
        }
    }

    // Wire event types
    @wire(getEventTypes)
    wiredEventTypes({ error, data }) {
        if (data) {
            this.eventTypes = data.map(type => ({ label: type, value: type }));
        } else if (error) {
            console.error('Error loading event types:', error);
        }
    }

    // Data table columns
    get columns() {
        return [
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
                label: 'Capacity',
                fieldName: 'Capacity',
                type: 'number'
            },
            {
                type: 'action',
                typeAttributes: {
                    rowActions: [
                        { label: 'View Details', name: 'view_details' },
                        { label: 'Edit', name: 'edit' },
                        { label: 'Delete', name: 'delete' }
                    ]
                }
            }
        ];
    }

    get modalTitle() {
        return this.isEditing ? 'Edit Event' : 'Create New Event';
    }

    get submitButtonLabel() {
        return this.isEditing ? 'Update Event' : 'Create Event';
    }

    get statusOptions() {
        return [
            { label: 'Planned', value: 'Planned' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Completed', value: 'Completed' },
            { label: 'Aborted', value: 'Aborted' }
        ];
    }

    get recurrenceOptions() {
        return [
            { label: 'Weekly', value: 'weekly' },
            { label: 'Monthly', value: 'monthly' },
            { label: 'Yearly', value: 'yearly' }
        ];
    }

    // Event handlers
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
        this.selectedEventId = null;
        this.selectedEventStats = null;
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
            case 'delete':
                this.deleteEventHandler(row.Id);
                break;
        }
    }

    async viewEventDetails(eventId) {
        try {
            this.selectedEventId = eventId;
            const stats = await getEventStats({ eventId: eventId });
            this.selectedEventStats = stats;
            this.showDetailsModal = true;
        } catch (error) {
            this.showToast('Error', 'Unable to load event details: ' + error.body.message, 'error');
        }
    }

    editEvent(row) {
        this.formData = {
            id: row.Id,
            name: row.Name,
            description: '', // Will be loaded via LDS
            startDate: row.StartDate,
            endDate: row.EndDate,
            status: row.Status,
            capacity: row.Capacity,
            isRecurring: false,
            recurrenceType: '',
            recurrenceCount: null,
            endRecurrenceDate: ''
        };
        this.isEditing = true;
        this.showModal = true;
    }

    async deleteEventHandler(eventId) {
        if (!confirm('Are you sure you want to delete this event? This action cannot be undone.')) {
            return;
        }

        try {
            await deleteRecord(eventId);
            this.showToast('Success', 'Event deleted successfully', 'success');
            // LDS will automatically refresh the list
        } catch (error) {
            this.showToast('Error', 'Unable to delete event: ' + error.body.message, 'error');
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

            const fields = {
                [CAMPAIGN_NAME.fieldApiName]: this.formData.name,
                [CAMPAIGN_DESCRIPTION.fieldApiName]: this.formData.description,
                [CAMPAIGN_START_DATE.fieldApiName]: this.formData.startDate,
                [CAMPAIGN_END_DATE.fieldApiName]: this.formData.endDate,
                [CAMPAIGN_STATUS.fieldApiName]: this.formData.status,
                [CAMPAIGN_TYPE.fieldApiName]: 'CVMA Event'
            };

            if (this.formData.capacity) {
                fields[CAMPAIGN_NUMBER_SENT.fieldApiName] = parseInt(this.formData.capacity);
            }

            let eventId;
            if (this.isEditing) {
                const recordInput = {
                    recordId: this.formData.id,
                    fields: fields
                };
                await updateRecord(recordInput);
                eventId = this.formData.id;
                this.showToast('Success', 'Event updated successfully', 'success');
            } else {
                const recordInput = { apiName: CAMPAIGN_OBJECT.objectApiName, fields };
                const result = await createRecord(recordInput);
                eventId = result.id;
                this.showToast('Success', 'Event created successfully', 'success');
            }

            // Handle recurring events if specified
            if (!this.isEditing && this.formData.isRecurring && this.formData.recurrenceType && this.formData.recurrenceCount) {
                try {
                    const recurringIds = await createRecurringEvents({
                        baseEventId: eventId,
                        recurrenceType: this.formData.recurrenceType,
                        recurrenceCount: parseInt(this.formData.recurrenceCount),
                        endRecurrenceDate: this.formData.endRecurrenceDate || null
                    });

                    if (recurringIds && recurringIds.length > 0) {
                        this.showToast('Success', `Created ${recurringIds.length} recurring events`, 'success');
                    }
                } catch (recurringError) {
                    this.showToast('Warning', 'Event created but recurring events failed: ' + recurringError.body.message, 'warning');
                }
            }

            this.closeModal();
            // LDS will automatically refresh the list

        } catch (error) {
            this.showToast('Error', 'Unable to save event: ' + error.body.message, 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    resetForm() {
        this.formData = {
            name: '',
            description: '',
            startDate: '',
            endDate: '',
            status: 'Planned',
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
