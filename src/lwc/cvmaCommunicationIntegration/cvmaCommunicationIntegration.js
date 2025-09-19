import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import sendMultiChannelCommunication from '@salesforce/apex/CVMACommunicationIntegrationController.sendMultiChannelCommunication';
import getAvailableIntegrations from '@salesforce/apex/CVMACommunicationIntegrationController.getAvailableIntegrations';
import testIntegration from '@salesforce/apex/CVMACommunicationIntegrationController.testIntegration';
import getDeliveryStatistics from '@salesforce/apex/CVMACommunicationIntegrationController.getDeliveryStatistics';

// Import labels for internationalization
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import MEMBERSHIP_LEVEL_FIELD from '@salesforce/schema/Contact.Membership_Level__c';

export default class CvmaCommunicationIntegration extends LightningElement {
    @track activeTab = 'integrations';
    @track isLoading = false;
    @track showSendModal = false;
    @track showTestModal = false;
    @track showStatisticsModal = false;

    // Integration data
    @track integrations = [];
    @track selectedIntegration = null;
    @track testResults = {};

    // Communication form data
    @track communicationForm = {
        messageType: 'ANNOUNCEMENT',
        subject: '',
        content: '',
        contactIds: [],
        channels: [],
        priority: 'NORMAL',
        trackDelivery: true,
        campaignId: ''
    };

    // Statistics data
    @track deliveryStatistics = {};
    @track statisticsDateRange = {
        startDate: null,
        endDate: null
    };

    // Contact selection
    @track availableContacts = [];
    @track selectedContacts = [];
    @track contactSearchTerm = '';

    // UI state
    @track showContactSelector = false;
    @track sendingCommunication = false;
    @track testingIntegration = false;
    @track loadingStatistics = false;

    // Computed properties
    get messageTypeOptions() {
        return [
            { label: 'Announcement', value: 'ANNOUNCEMENT' },
            { label: 'Alert', value: 'ALERT' },
            { label: 'Reminder', value: 'REMINDER' },
            { label: 'Update', value: 'UPDATE' },
            { label: 'Emergency', value: 'EMERGENCY' }
        ];
    }

    get priorityOptions() {
        return [
            { label: 'Low', value: 'LOW' },
            { label: 'Normal', value: 'NORMAL' },
            { label: 'High', value: 'HIGH' },
            { label: 'Critical', value: 'CRITICAL' }
        ];
    }

    get channelOptions() {
        const channels = [];
        this.integrations.forEach(integration => {
            if (integration.isActive && integration.supportedChannels) {
                integration.supportedChannels.forEach(channel => {
                    if (!channels.find(c => c.value === channel)) {
                        channels.push({
                            label: this.formatChannelLabel(channel),
                            value: channel
                        });
                    }
                });
            }
        });
        return channels;
    }

    get hasActiveIntegrations() {
        return this.integrations.some(integration => integration.isActive);
    }

    get selectedContactsCount() {
        return this.selectedContacts.length;
    }

    get canSendCommunication() {
        return this.communicationForm.content &&
               this.communicationForm.channels.length > 0 &&
               this.selectedContacts.length > 0 &&
               !this.sendingCommunication;
    }

    get filteredContacts() {
        if (!this.contactSearchTerm) {
            return this.availableContacts;
        }
        const searchTerm = this.contactSearchTerm.toLowerCase();
        return this.availableContacts.filter(contact =>
            contact.Name.toLowerCase().includes(searchTerm) ||
            (contact.Email && contact.Email.toLowerCase().includes(searchTerm))
        );
    }

    get statisticsStartDate() {
        return this.statisticsDateRange.startDate || this.getDefaultStartDate();
    }

    get statisticsEndDate() {
        return this.statisticsDateRange.endDate || this.getDefaultEndDate();
    }

    get hasStatisticsData() {
        return this.deliveryStatistics &&
               this.deliveryStatistics.totalCommunications !== undefined;
    }

    // Wire methods
    @wire(getAvailableIntegrations)
    wiredIntegrations({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.integrations = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.integrations = [];
            this.showToast('Error', 'Failed to load integrations: ' + error.body.message, 'error');
        }
    }

    // Lifecycle methods
    connectedCallback() {
        this.isLoading = true;
        this.initializeDefaultDates();
        this.loadContacts();
    }

    // Event handlers
    handleTabChange(event) {
        this.activeTab = event.target.value;

        if (this.activeTab === 'statistics') {
            this.loadDeliveryStatistics();
        }
    }

    handleOpenSendModal() {
        this.resetCommunicationForm();
        this.showSendModal = true;
    }

    handleCloseSendModal() {
        this.showSendModal = false;
        this.resetCommunicationForm();
    }

    handleOpenTestModal(event) {
        const integrationId = event.target.dataset.integration;
        this.selectedIntegration = this.integrations.find(i => i.providerId === integrationId);
        this.showTestModal = true;
    }

    handleCloseTestModal() {
        this.showTestModal = false;
        this.selectedIntegration = null;
    }

    handleOpenStatisticsModal() {
        this.showStatisticsModal = true;
        this.loadDeliveryStatistics();
    }

    handleCloseStatisticsModal() {
        this.showStatisticsModal = false;
    }

    handleFormFieldChange(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;

        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        }

        if (field === 'channels') {
            // Handle multi-select for channels
            const selectedOptions = Array.from(event.target.selectedOptions || []);
            value = selectedOptions.map(option => option.value);
        }

        this.communicationForm = {
            ...this.communicationForm,
            [field]: value
        };
    }

    handleContactSearch(event) {
        this.contactSearchTerm = event.target.value;
    }

    handleContactSelection(event) {
        const contactId = event.target.dataset.contactId;
        const isChecked = event.target.checked;

        if (isChecked) {
            const contact = this.availableContacts.find(c => c.Id === contactId);
            if (contact && !this.selectedContacts.find(c => c.Id === contactId)) {
                this.selectedContacts = [...this.selectedContacts, contact];
            }
        } else {
            this.selectedContacts = this.selectedContacts.filter(c => c.Id !== contactId);
        }

        // Update form with selected contact IDs
        this.communicationForm.contactIds = this.selectedContacts.map(c => c.Id);
    }

    handleRemoveContact(event) {
        const contactId = event.target.dataset.contactId;
        this.selectedContacts = this.selectedContacts.filter(c => c.Id !== contactId);
        this.communicationForm.contactIds = this.selectedContacts.map(c => c.Id);
    }

    handleOpenContactSelector() {
        this.showContactSelector = true;
    }

    handleCloseContactSelector() {
        this.showContactSelector = false;
    }

    handleStatisticsDateChange(event) {
        const field = event.target.dataset.field;
        this.statisticsDateRange[field] = event.target.value;
    }

    handleRefreshStatistics() {
        this.loadDeliveryStatistics();
    }

    // Action handlers
    async handleSendCommunication() {
        if (!this.canSendCommunication) {
            this.showToast('Warning', 'Please complete all required fields', 'warning');
            return;
        }

        this.sendingCommunication = true;

        try {
            const result = await sendMultiChannelCommunication({
                request: this.communicationForm
            });

            if (result.success) {
                this.showToast(
                    'Success',
                    `Communication sent successfully! ${result.message}`,
                    'success'
                );
                this.handleCloseSendModal();
            } else {
                this.showToast('Error', result.message, 'error');
            }

        } catch (error) {
            this.showToast('Error', 'Failed to send communication: ' + error.body.message, 'error');
        } finally {
            this.sendingCommunication = false;
        }
    }

    async handleTestIntegration() {
        if (!this.selectedIntegration) return;

        this.testingIntegration = true;

        try {
            const result = await testIntegration({
                providerId: this.selectedIntegration.providerId
            });

            this.testResults = {
                ...this.testResults,
                [this.selectedIntegration.providerId]: result
            };

            const toastVariant = result.success ? 'success' : 'error';
            this.showToast('Test Result', result.message, toastVariant);

        } catch (error) {
            this.showToast('Error', 'Test failed: ' + error.body.message, 'error');
        } finally {
            this.testingIntegration = false;
            this.handleCloseTestModal();
        }
    }

    // Utility methods
    async loadContacts() {
        try {
            // In a real implementation, this would use a wire service or imperative Apex call
            // For now, we'll simulate contact loading
            this.availableContacts = [];
        } catch (error) {
            this.showToast('Error', 'Failed to load contacts', 'error');
        }
    }

    async loadDeliveryStatistics() {
        this.loadingStatistics = true;

        try {
            const result = await getDeliveryStatistics({
                startDate: this.statisticsStartDate,
                endDate: this.statisticsEndDate
            });

            if (result.error) {
                this.showToast('Error', result.error, 'error');
            } else {
                this.deliveryStatistics = result;
            }

        } catch (error) {
            this.showToast('Error', 'Failed to load statistics: ' + error.body.message, 'error');
        } finally {
            this.loadingStatistics = false;
        }
    }

    resetCommunicationForm() {
        this.communicationForm = {
            messageType: 'ANNOUNCEMENT',
            subject: '',
            content: '',
            contactIds: [],
            channels: [],
            priority: 'NORMAL',
            trackDelivery: true,
            campaignId: ''
        };
        this.selectedContacts = [];
    }

    initializeDefaultDates() {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - 30);

        this.statisticsDateRange = {
            startDate: this.formatDateForInput(startDate),
            endDate: this.formatDateForInput(endDate)
        };
    }

    getDefaultStartDate() {
        const date = new Date();
        date.setDate(date.getDate() - 30);
        return this.formatDateForInput(date);
    }

    getDefaultEndDate() {
        return this.formatDateForInput(new Date());
    }

    formatDateForInput(date) {
        return date.toISOString().split('T')[0];
    }

    formatChannelLabel(channel) {
        const channelLabels = {
            'SMS': 'SMS Text Message',
            'MMS': 'MMS Media Message',
            'EMAIL': 'Email',
            'HTML_EMAIL': 'HTML Email',
            'SLACK_MESSAGE': 'Slack Message',
            'SLACK_ALERT': 'Slack Alert'
        };
        return channelLabels[channel] || channel;
    }

    getIntegrationStatusClass(integration) {
        return integration.isActive ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    getIntegrationStatusIcon(integration) {
        return integration.isActive ? 'utility:success' : 'utility:error';
    }

    getUsagePercentage(integration) {
        if (!integration.dailyLimit || integration.dailyLimit === 0) return 0;
        return Math.round((integration.dailyUsage / integration.dailyLimit) * 100);
    }

    getUsageProgressClass(integration) {
        const percentage = this.getUsagePercentage(integration);
        if (percentage >= 90) return 'slds-progress-bar__value_error';
        if (percentage >= 75) return 'slds-progress-bar__value_warning';
        return 'slds-progress-bar__value_success';
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}
