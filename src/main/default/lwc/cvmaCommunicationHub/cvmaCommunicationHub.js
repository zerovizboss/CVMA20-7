import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getCurrentUser from '@salesforce/apex/CVMACommunicationHubController.getCurrentUser';
import getRecentCommunications from '@salesforce/apex/CVMACommunicationHubController.getRecentCommunications';
import getChatterGroups from '@salesforce/apex/CVMACommunicationHubController.getChatterGroups';
import sendCommunication from '@salesforce/apex/CVMACommunicationHubController.sendCommunication';
import CONTACT_ID_FIELD from '@salesforce/schema/User.ContactId';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';

const PLATFORM_EVENT_CHANNEL = '/event/CVMA_Communication_Event__e';

export default class CvmaCommunicationHub extends NavigationMixin(LightningElement) {
    @api height = 600;
    @api showRelatedCommunications = false;
    @api communityMode = false;
    @api recordId;

    @track currentUser;
    @track recentCommunications = [];
    @track chatterGroups = [];
    @track selectedTab = 'inbox';
    @track isLoading = true;
    @track error;

    // Platform Event subscription
    subscription = {};

    // Communication composition
    @track showComposer = false;
    @track composerType = 'email';
    @track composerSubject = '';
    @track composerBody = '';
    @track composerRecipients = [];
    @track composerPriority = 'Normal';

    connectedCallback() {
        this.initializeComponent();
        this.subscribeToPlatformEvents();
    }

    disconnectedCallback() {
        this.unsubscribeFromPlatformEvents();
    }

    async initializeComponent() {
        try {
            this.isLoading = true;
            await this.loadCurrentUser();
            await this.loadRecentCommunications();
            await this.loadChatterGroups();
            this.error = null;
        } catch (error) {
            this.error = error.body?.message || 'Failed to initialize communication hub';
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadCurrentUser() {
        try {
            this.currentUser = await getCurrentUser();
        } catch (error) {
            throw new Error('Failed to load current user information');
        }
    }

    async loadRecentCommunications() {
        try {
            const communications = await getRecentCommunications({
                contactId: this.currentUser?.contactId,
                recordId: this.recordId,
                limitSize: 50
            });
            this.recentCommunications = communications.map(comm => ({
                ...comm,
                formattedDate: this.formatDate(comm.createdDate),
                isHighPriority: comm.priority === 'High' || comm.priority === 'Urgent',
                typeIcon: this.getCommunicationIcon(comm.type),
                typeLabel: this.getCommunicationLabel(comm.type)
            }));
        } catch (error) {
            throw new Error('Failed to load recent communications');
        }
    }

    async loadChatterGroups() {
        try {
            const groups = await getChatterGroups({
                contactId: this.currentUser?.contactId
            });
            this.chatterGroups = groups.map(group => ({
                ...group,
                memberCount: group.memberCount || 0,
                hasNewPosts: group.lastPostDate && this.isRecent(group.lastPostDate),
                formattedLastPost: group.lastPostDate ? this.formatDate(group.lastPostDate) : 'No recent posts'
            }));
        } catch (error) {
            throw new Error('Failed to load Chatter groups');
        }
    }

    subscribeToPlatformEvents() {
        const messageCallback = (response) => {
            this.handlePlatformEvent(response);
        };

        subscribe(PLATFORM_EVENT_CHANNEL, -1, messageCallback).then(response => {
            this.subscription = response;
        });

        onError(error => {
            console.error('Platform Event subscription error:', error);
        });
    }

    unsubscribeFromPlatformEvents() {
        if (this.subscription) {
            unsubscribe(this.subscription);
        }
    }

    handlePlatformEvent(response) {
        const eventData = response.data.payload;

        // Check if this event is relevant to current user
        if (eventData.Member_Id__c === this.currentUser?.contactId) {
            this.showToast(
                'New Communication',
                `${eventData.Communication_Type__c}: ${eventData.Content__c?.substring(0, 100)}...`,
                'info'
            );

            // Refresh communications list
            this.loadRecentCommunications();
        }
    }

    // Tab handling
    handleTabChange(event) {
        this.selectedTab = event.target.value;
    }

    get tabOptions() {
        return [
            { label: 'Inbox', value: 'inbox' },
            { label: 'Chatter Groups', value: 'groups' },
            { label: 'Compose', value: 'compose' },
            { label: 'Analytics', value: 'analytics' }
        ];
    }

    get showInbox() {
        return this.selectedTab === 'inbox';
    }

    get showGroups() {
        return this.selectedTab === 'groups';
    }

    get showCompose() {
        return this.selectedTab === 'compose';
    }

    get showAnalytics() {
        return this.selectedTab === 'analytics';
    }

    // Communication composition
    handleComposeTypeChange(event) {
        this.composerType = event.detail.value;
    }

    handleSubjectChange(event) {
        this.composerSubject = event.target.value;
    }

    handleBodyChange(event) {
        this.composerBody = event.target.value;
    }

    handlePriorityChange(event) {
        this.composerPriority = event.detail.value;
    }

    async handleSendCommunication() {
        if (!this.composerSubject.trim() || !this.composerBody.trim()) {
            this.showToast('Error', 'Subject and message body are required', 'error');
            return;
        }

        try {
            this.isLoading = true;

            await sendCommunication({
                communicationType: this.composerType,
                subject: this.composerSubject,
                body: this.composerBody,
                priority: this.composerPriority,
                recipientIds: this.composerRecipients,
                senderId: this.currentUser?.contactId
            });

            this.showToast('Success', 'Communication sent successfully', 'success');
            this.resetComposer();
            this.selectedTab = 'inbox';
            await this.loadRecentCommunications();

        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to send communication', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    resetComposer() {
        this.composerSubject = '';
        this.composerBody = '';
        this.composerRecipients = [];
        this.composerPriority = 'Normal';
    }

    // Navigation handlers
    handleCommunicationClick(event) {
        const commId = event.currentTarget.dataset.id;
        const communication = this.recentCommunications.find(c => c.id === commId);

        if (communication) {
            this.navigateToRecord(communication.relatedRecordId || communication.id);
        }
    }

    handleGroupClick(event) {
        const groupId = event.currentTarget.dataset.id;
        this.navigateToChatterGroup(groupId);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    navigateToChatterGroup(groupId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: groupId,
                objectApiName: 'CollaborationGroup',
                actionName: 'view'
            }
        });
    }

    // Utility methods
    formatDate(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diff = now - date;
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));

        if (days === 0) {
            return 'Today';
        } else if (days === 1) {
            return 'Yesterday';
        } else if (days < 7) {
            return `${days} days ago`;
        } else {
            return date.toLocaleDateString();
        }
    }

    isRecent(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diff = now - date;
        const hours = diff / (1000 * 60 * 60);
        return hours <= 24;
    }

    getCommunicationIcon(type) {
        const iconMap = {
            'Event Registration': 'utility:event',
            'Event Reminder': 'utility:reminder',
            'Event Update': 'utility:notification',
            'Donation Acknowledgment': 'utility:money',
            'Membership Payment': 'utility:user',
            'Membership Application': 'utility:identity',
            'Chapter Announcement': 'utility:announcement',
            'Emergency Notification': 'utility:warning',
            'Birthday Greeting': 'utility:gift',
            'Anniversary Recognition': 'utility:celebration'
        };
        return iconMap[type] || 'utility:email';
    }

    getCommunicationLabel(type) {
        return type || 'Communication';
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get composerTypeOptions() {
        return [
            { label: 'Email', value: 'email' },
            { label: 'Chatter Post', value: 'chatter' },
            { label: 'Announcement', value: 'announcement' }
        ];
    }

    get priorityOptions() {
        return [
            { label: 'Low', value: 'Low' },
            { label: 'Normal', value: 'Normal' },
            { label: 'High', value: 'High' },
            { label: 'Urgent', value: 'Urgent' }
        ];
    }

    get hasRecentCommunications() {
        return this.recentCommunications && this.recentCommunications.length > 0;
    }

    get hasChatterGroups() {
        return this.chatterGroups && this.chatterGroups.length > 0;
    }

    get componentTitle() {
        if (this.communityMode) {
            return 'CVMA Chapter Communication';
        }
        return 'Communication Hub';
    }

    get containerClass() {
        return `communication-hub slds-card ${this.communityMode ? 'community-mode' : ''}`;
    }
}
