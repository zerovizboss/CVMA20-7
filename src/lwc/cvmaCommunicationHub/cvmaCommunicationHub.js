import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCommunicationGroups from '@salesforce/apex/CVMACommunicationHubController.getCommunicationGroups';
import getCommunicationActivities from '@salesforce/apex/CVMACommunicationHubController.getCommunicationActivities';
import getCommunicationMetrics from '@salesforce/apex/CVMACommunicationHubController.getCommunicationMetrics';
import createChatterPost from '@salesforce/apex/CVMACommunicationHubController.createChatterPost';
import sendGroupNotification from '@salesforce/apex/CVMACommunicationHubController.sendGroupNotification';

export default class CvmaCommunicationHub extends LightningElement {
    @track communicationGroups = [];
    @track activities = [];
    @track metrics = {};
    @track isLoading = true;
    @track error;
    @track selectedGroupId;
    @track selectedView = 'dashboard';

    // New post form fields
    @track newPostMessage = '';
    @track showNewPostModal = false;

    // Email notification fields
    @track emailSubject = '';
    @track emailContent = '';
    @track emailPriority = 'Normal';
    @track showEmailModal = false;

    // Wire communication groups
    @wire(getCommunicationGroups)
    wiredGroups(result) {
        this.wiredGroupsResult = result;
        const { data, error } = result;

        if (data) {
            this.communicationGroups = data.groups || [];
            this.error = undefined;
            this.checkLoadingComplete();
        } else if (error) {
            this.error = 'Error loading communication groups: ' + (error.body?.message || error.message);
            this.isLoading = false;
        }
    }

    // Wire communication metrics
    @wire(getCommunicationMetrics)
    wiredMetrics(result) {
        this.wiredMetricsResult = result;
        const { data, error } = result;

        if (data) {
            this.metrics = data;
            this.error = undefined;
            this.checkLoadingComplete();
        } else if (error) {
            this.error = 'Error loading communication metrics: ' + (error.body?.message || error.message);
            this.isLoading = false;
        }
    }

    // Computed properties
    get hasGroups() {
        return this.communicationGroups && this.communicationGroups.length > 0;
    }

    get hasActivities() {
        return this.activities && this.activities.length > 0;
    }

    get isDashboardView() {
        return this.selectedView === 'dashboard';
    }

    get isGroupView() {
        return this.selectedView === 'group';
    }

    get isActivitiesView() {
        return this.selectedView === 'activities';
    }

    get selectedGroupName() {
        const group = this.communicationGroups.find(g => g.id === this.selectedGroupId);
        return group ? group.name : 'Select Group';
    }

    get groupOptions() {
        return this.communicationGroups.map(group => ({
            label: group.name,
            value: group.id
        }));
    }

    get priorityOptions() {
        return [
            { label: 'High', value: 'High' },
            { label: 'Normal', value: 'Normal' },
            { label: 'Low', value: 'Low' }
        ];
    }

    get formattedMetrics() {
        if (!this.metrics || Object.keys(this.metrics).length === 0) return [];

        return [
            {
                label: 'Active Groups',
                value: this.metrics.activeGroups || 0,
                icon: 'utility:groups',
                variant: 'success'
            },
            {
                label: 'Recent Posts',
                value: this.metrics.recentPosts || 0,
                icon: 'utility:comments',
                variant: 'info'
            },
            {
                label: 'Emails Sent',
                value: this.metrics.emailsSent || 0,
                icon: 'utility:email',
                variant: 'warning'
            },
            {
                label: 'Member Engagement',
                value: this.metrics.memberEngagement || 0,
                icon: 'utility:like',
                variant: 'error'
            }
        ];
    }

    // Event handlers
    handleViewChange(event) {
        this.selectedView = event.target.dataset.view;

        if (this.selectedView === 'activities') {
            this.loadActivities();
        }
    }

    handleGroupSelection(event) {
        this.selectedGroupId = event.detail.value;
        this.selectedView = 'group';
        this.loadActivities();
    }

    handleRefresh() {
        this.isLoading = true;
        Promise.all([
            refreshApex(this.wiredGroupsResult),
            refreshApex(this.wiredMetricsResult)
        ]).then(() => {
            this.loadActivities();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Communication data refreshed successfully.',
                    variant: 'success'
                })
            );
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error refreshing data: ' + (error.body?.message || error.message),
                    variant: 'error'
                })
            );
        });
    }

    // New post modal handlers
    handleNewPost() {
        if (!this.selectedGroupId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'Please select a group first.',
                    variant: 'warning'
                })
            );
            return;
        }
        this.showNewPostModal = true;
    }

    handleCancelPost() {
        this.showNewPostModal = false;
        this.newPostMessage = '';
    }

    handlePostMessageChange(event) {
        this.newPostMessage = event.target.value;
    }

    handleCreatePost() {
        if (!this.newPostMessage.trim()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter a message.',
                    variant: 'error'
                })
            );
            return;
        }

        createChatterPost({
            groupId: this.selectedGroupId,
            message: this.newPostMessage,
            mentionIds: [] // Could be enhanced with @mention functionality
        })
        .then(result => {
            if (result.success) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: result.message,
                        variant: 'success'
                    })
                );
                this.showNewPostModal = false;
                this.newPostMessage = '';
                this.loadActivities();
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error creating post: ' + (error.body?.message || error.message),
                    variant: 'error'
                })
            );
        });
    }

    // Email notification modal handlers
    handleSendNotification() {
        if (!this.selectedGroupId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'Please select a group first.',
                    variant: 'warning'
                })
            );
            return;
        }
        this.showEmailModal = true;
    }

    handleCancelEmail() {
        this.showEmailModal = false;
        this.emailSubject = '';
        this.emailContent = '';
        this.emailPriority = 'Normal';
    }

    handleEmailFieldChange(event) {
        const field = event.target.dataset.field;
        if (field === 'subject') {
            this.emailSubject = event.target.value;
        } else if (field === 'content') {
            this.emailContent = event.target.value;
        } else if (field === 'priority') {
            this.emailPriority = event.detail.value;
        }
    }

    handleSendEmail() {
        if (!this.emailSubject.trim() || !this.emailContent.trim()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter both subject and content.',
                    variant: 'error'
                })
            );
            return;
        }

        sendGroupNotification({
            groupId: this.selectedGroupId,
            subject: this.emailSubject,
            content: this.emailContent,
            priority: this.emailPriority
        })
        .then(result => {
            if (result.success) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: result.message,
                        variant: 'success'
                    })
                );
                this.showEmailModal = false;
                this.emailSubject = '';
                this.emailContent = '';
                this.emailPriority = 'Normal';
                this.handleRefresh(); // Refresh metrics
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error sending notification: ' + (error.body?.message || error.message),
                    variant: 'error'
                })
            );
        });
    }

    // Utility methods
    loadActivities() {
        getCommunicationActivities({
            groupId: this.selectedGroupId,
            pageSize: 20
        })
        .then(result => {
            this.activities = result.activities || [];
            this.error = undefined;
        })
        .catch(error => {
            this.error = 'Error loading activities: ' + (error.body?.message || error.message);
            this.activities = [];
        });
    }

    checkLoadingComplete() {
        // Check if all required data has loaded
        const groupsLoaded = this.communicationGroups !== undefined;
        const metricsLoaded = this.metrics && Object.keys(this.metrics).length > 0;

        if (groupsLoaded && metricsLoaded) {
            this.isLoading = false;
        }
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    truncateText(text, maxLength) {
        if (!text) return '';
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    }
}
