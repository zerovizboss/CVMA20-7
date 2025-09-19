/**
 * @description Lightning Web Component for CVMA Member-to-Member Messaging System
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getMessages from '@salesforce/apex/CVMAMessagingController.getMessages';
import sendMessage from '@salesforce/apex/CVMAMessagingController.sendMessage';
import markMessageAsRead from '@salesforce/apex/CVMAMessagingController.markMessageAsRead';
import getAvailableMembers from '@salesforce/apex/CVMAMessagingController.getAvailableMembers';
import archiveMessage from '@salesforce/apex/CVMAMessagingController.archiveMessage';

const COLUMNS = [
    {
        label: 'Subject',
        fieldName: 'Subject__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'statusClass' } }
    },
    {
        label: 'From/To',
        fieldName: 'contactName',
        type: 'text'
    },
    {
        label: 'Priority',
        fieldName: 'Priority__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'priorityClass' } }
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'statusBadgeClass' } }
    },
    {
        label: 'Date',
        fieldName: 'CreatedDate',
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
        type: 'action',
        typeAttributes: { rowActions: [] }
    }
];

export default class CvmaMessaging extends LightningElement {
    // Public properties
    columns = COLUMNS;

    // Tracked properties
    @track messages = [];
    @track selectedMessage = null;
    @track isLoading = false;
    @track error = null;
    @track currentView = 'inbox';
    @track pageNumber = 0;
    @track pageSize = 25;
    @track totalCount = 0;
    @track hasMore = false;

    // Compose message properties
    @track showComposeModal = false;
    @track newMessage = {
        recipientId: '',
        subject: '',
        messageBody: '',
        priority: 'Normal'
    };
    @track availableMembers = [];
    @track memberSearchTerm = '';
    @track isComposing = false;

    // View message modal
    @track showMessageModal = false;
    @track selectedMessageDetails = {};

    // Wired methods
    wiredMessagesResult;

    @wire(getMessages, { pageSize: '$pageSize', pageNumber: '$pageNumber', messageType: '$currentView' })
    wiredMessages(result) {
        this.wiredMessagesResult = result;
        if (result.data) {
            this.handleMessagesSuccess(result.data);
        } else if (result.error) {
            this.handleError('Failed to load messages', result.error);
        }
    }

    @wire(getAvailableMembers, { searchTerm: '$memberSearchTerm' })
    wiredAvailableMembers({ error, data }) {
        if (data) {
            this.availableMembers = data;
        } else if (error) {
            console.error('Error loading members:', error);
        }
    }

    // Getters
    get inboxActive() {
        return this.currentView === 'inbox' ? 'slds-is-active' : '';
    }

    get sentActive() {
        return this.currentView === 'sent' ? 'slds-is-active' : '';
    }

    get archivedActive() {
        return this.currentView === 'archived' ? 'slds-is-active' : '';
    }

    get hasMessages() {
        return this.messages && this.messages.length > 0;
    }

    get memberOptions() {
        return this.availableMembers.map(member => ({
            label: member.displayName,
            value: member.contactId
        }));
    }

    get priorityOptions() {
        return [
            { label: 'Normal', value: 'Normal' },
            { label: 'High', value: 'High' },
            { label: 'Urgent', value: 'Urgent' }
        ];
    }

    get unreadCount() {
        return this.messages ? this.messages.filter(msg => msg.Status__c === 'Sent').length : 0;
    }

    get pageInfo() {
        const start = (this.pageNumber * this.pageSize) + 1;
        const end = Math.min(start + this.pageSize - 1, this.totalCount);
        return `${start}-${end} of ${this.totalCount}`;
    }

    get isFirstPage() {
        return this.pageNumber === 0;
    }

    get isLastPage() {
        return !this.hasMore;
    }

    // Event handlers
    handleViewChange(event) {
        this.currentView = event.target.dataset.view;
        this.pageNumber = 0;
        this.refreshMessages();
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.viewMessage(selectedRows[0]);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view':
                this.viewMessage(row);
                break;
            case 'archive':
                this.archiveSelectedMessage(row.Id);
                break;
            case 'reply':
                this.replyToMessage(row);
                break;
        }
    }

    handleComposeClick() {
        this.resetComposeForm();
        this.showComposeModal = true;
    }

    handleComposeCancel() {
        this.showComposeModal = false;
        this.resetComposeForm();
    }

    handleMessageModalClose() {
        this.showMessageModal = false;
        this.selectedMessageDetails = {};
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        if (field) {
            this.newMessage[field] = event.target.value;
        }
    }

    handleMemberSearch(event) {
        this.memberSearchTerm = event.target.value;
    }

    async handleSendMessage() {
        if (!this.validateMessage()) {
            return;
        }

        this.isComposing = true;

        try {
            const result = await sendMessage({
                recipientId: this.newMessage.recipientId,
                subject: this.newMessage.subject,
                messageBody: this.newMessage.messageBody,
                priority: this.newMessage.priority,
                threadId: null
            });

            if (result.success) {
                this.showToast('Success', result.successMessage, 'success');
                this.showComposeModal = false;
                this.resetComposeForm();
                this.refreshMessages();
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.handleError('Failed to send message', error);
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
        this.refreshMessages();
    }

    // Private methods
    async viewMessage(message) {
        this.selectedMessageDetails = {
            ...message,
            formattedDate: new Intl.DateTimeFormat('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }).format(new Date(message.CreatedDate))
        };

        // Mark as read if it's in the user's inbox and unread
        if (this.currentView === 'inbox' && message.Status__c === 'Sent') {
            try {
                const result = await markMessageAsRead({ messageId: message.Id });
                if (result.success) {
                    // Refresh the messages to update status
                    this.refreshMessages();
                }
            } catch (error) {
                console.error('Error marking message as read:', error);
            }
        }

        this.showMessageModal = true;
    }

    replyToMessage(originalMessage) {
        this.resetComposeForm();
        this.newMessage.recipientId = this.currentView === 'inbox' ? originalMessage.Sender__c : originalMessage.Recipient__c;
        this.newMessage.subject = originalMessage.Subject__c.startsWith('Re: ') ?
            originalMessage.Subject__c : 'Re: ' + originalMessage.Subject__c;
        this.showComposeModal = true;
    }

    async archiveSelectedMessage(messageId) {
        this.isLoading = true;

        try {
            const result = await archiveMessage({ messageId });

            if (result.success) {
                this.showToast('Success', result.successMessage, 'success');
                this.refreshMessages();
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.handleError('Failed to archive message', error);
        } finally {
            this.isLoading = false;
        }
    }

    validateMessage() {
        if (!this.newMessage.recipientId) {
            this.showToast('Validation Error', 'Please select a recipient', 'error');
            return false;
        }

        if (!this.newMessage.subject || this.newMessage.subject.trim().length === 0) {
            this.showToast('Validation Error', 'Subject is required', 'error');
            return false;
        }

        if (!this.newMessage.messageBody || this.newMessage.messageBody.trim().length === 0) {
            this.showToast('Validation Error', 'Message body is required', 'error');
            return false;
        }

        if (this.newMessage.subject.length > 255) {
            this.showToast('Validation Error', 'Subject cannot exceed 255 characters', 'error');
            return false;
        }

        if (this.newMessage.messageBody.length > 32768) {
            this.showToast('Validation Error', 'Message body cannot exceed 32,768 characters', 'error');
            return false;
        }

        return true;
    }

    resetComposeForm() {
        this.newMessage = {
            recipientId: '',
            subject: '',
            messageBody: '',
            priority: 'Normal'
        };
    }

    refreshMessages() {
        return refreshApex(this.wiredMessagesResult);
    }

    handleMessagesSuccess(data) {
        if (data.success) {
            this.messages = this.processMessages(data.messages);
            this.totalCount = data.totalCount;
            this.hasMore = data.hasMore;
            this.error = null;

            // Set row actions based on current view
            this.updateRowActions();
        } else {
            this.handleError('Failed to load messages', data.errorMessage);
        }
        this.isLoading = false;
    }

    processMessages(messages) {
        return messages.map(msg => {
            const processed = { ...msg };

            // Determine contact name based on current view
            if (this.currentView === 'sent') {
                processed.contactName = msg.Recipient__r ? msg.Recipient__r.Name : 'Unknown Recipient';
            } else {
                processed.contactName = msg.Sender__r ? msg.Sender__r.Name : 'Unknown Sender';
            }

            // Add CSS classes for styling
            processed.statusClass = msg.Status__c === 'Sent' ? 'slds-text-color_default slds-text-title_caps' : '';
            processed.priorityClass = this.getPriorityClass(msg.Priority__c);
            processed.statusBadgeClass = this.getStatusBadgeClass(msg.Status__c);

            return processed;
        });
    }

    getPriorityClass(priority) {
        switch (priority) {
            case 'High':
                return 'slds-text-color_error';
            case 'Urgent':
                return 'slds-text-color_error slds-text-title_caps';
            default:
                return '';
        }
    }

    getStatusBadgeClass(status) {
        switch (status) {
            case 'Sent':
                return 'slds-badge slds-badge_lightest';
            case 'Read':
                return 'slds-badge slds-theme_success';
            case 'Replied':
                return 'slds-badge slds-theme_info';
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
            actions.push({ label: 'Archive', name: 'archive' });
        }

        if (this.currentView === 'inbox') {
            actions.push({ label: 'Reply', name: 'reply' });
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
