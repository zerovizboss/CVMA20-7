import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getCommunicationMetrics from '@salesforce/apex/CVMAOfficerCommunicationController.getCommunicationMetrics';
import getActiveCampaigns from '@salesforce/apex/CVMAOfficerCommunicationController.getActiveCampaigns';
import getMemberGroups from '@salesforce/apex/CVMAOfficerCommunicationController.getMemberGroups';
import sendMassCommunication from '@salesforce/apex/CVMAOfficerCommunicationController.sendMassCommunication';
import createCommunicationCampaign from '@salesforce/apex/CVMAOfficerCommunicationController.createCommunicationCampaign';

export default class CvmaOfficerCommunicationDashboard extends NavigationMixin(LightningElement) {
    @api height = 800;
    @api showAnalytics = true;
    @api officerMode = true;
    @api chapterFilter = 'Chapter 20-7';

    @track selectedTab = 'overview';
    @track isLoading = true;
    @track error;

    // Data properties
    @track communicationMetrics = {};
    @track activeCampaigns = [];
    @track memberGroups = [];

    // Mass communication properties
    @track showMassComposer = false;
    @track massComposerData = {
        campaignType: 'Newsletter',
        subject: '',
        message: '',
        priority: 'Normal',
        sendToAll: false,
        selectedGroups: [],
        scheduleDate: null,
        includeImages: false
    };

    // Campaign creation properties
    @track showCampaignCreator = false;
    @track campaignData = {
        name: '',
        type: 'Newsletter',
        description: '',
        startDate: null,
        endDate: null,
        targetAudience: 'All Members'
    };

    // Wire methods for data loading
    @wire(getCommunicationMetrics, { chapterFilter: '$chapterFilter' })
    wiredMetrics(result) {
        this.metricsWireResult = result;
        if (result.data) {
            this.communicationMetrics = result.data;
            this.error = null;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Failed to load communication metrics';
        }
        this.updateLoadingState();
    }

    @wire(getActiveCampaigns, { chapterFilter: '$chapterFilter' })
    wiredCampaigns(result) {
        this.campaignsWireResult = result;
        if (result.data) {
            this.activeCampaigns = result.data.map(campaign => ({
                ...campaign,
                formattedStartDate: this.formatDate(campaign.startDate),
                formattedEndDate: this.formatDate(campaign.endDate),
                statusVariant: this.getCampaignStatusVariant(campaign.status),
                participationRate: this.calculateParticipationRate(campaign)
            }));
            this.error = null;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Failed to load active campaigns';
        }
        this.updateLoadingState();
    }

    @wire(getMemberGroups, { chapterFilter: '$chapterFilter' })
    wiredMemberGroups(result) {
        this.memberGroupsWireResult = result;
        if (result.data) {
            this.memberGroups = result.data.map(group => ({
                ...group,
                label: `${group.name} (${group.memberCount} members)`,
                value: group.id
            }));
            this.error = null;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Failed to load member groups';
        }
        this.updateLoadingState();
    }

    connectedCallback() {
        this.initializeDashboard();
    }

    initializeDashboard() {
        // Set default dates for campaign creation
        const today = new Date();
        const nextWeek = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);

        this.campaignData.startDate = today.toISOString().split('T')[0];
        this.campaignData.endDate = nextWeek.toISOString().split('T')[0];
    }

    updateLoadingState() {
        // Check if all wire methods have completed
        const hasMetrics = this.metricsWireResult?.data || this.metricsWireResult?.error;
        const hasCampaigns = this.campaignsWireResult?.data || this.campaignsWireResult?.error;
        const hasGroups = this.memberGroupsWireResult?.data || this.memberGroupsWireResult?.error;

        if (hasMetrics && hasCampaigns && hasGroups) {
            this.isLoading = false;
        }
    }

    // Tab navigation
    handleTabChange(event) {
        this.selectedTab = event.target.value;
    }

    get tabOptions() {
        return [
            { label: 'Overview', value: 'overview' },
            { label: 'Active Campaigns', value: 'campaigns' },
            { label: 'Mass Communication', value: 'communication' },
            { label: 'Analytics', value: 'analytics' }
        ];
    }

    get showOverview() {
        return this.selectedTab === 'overview';
    }

    get showCampaigns() {
        return this.selectedTab === 'campaigns';
    }

    get showCommunication() {
        return this.selectedTab === 'communication';
    }

    get showAnalyticsTab() {
        return this.selectedTab === 'analytics';
    }

    // Mass communication handlers
    handleOpenMassComposer() {
        this.showMassComposer = true;
        this.resetMassComposer();
    }

    handleCloseMassComposer() {
        this.showMassComposer = false;
    }

    handleMassComposerFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.massComposerData = { ...this.massComposerData, [field]: value };
    }

    handleGroupSelection(event) {
        this.massComposerData.selectedGroups = event.detail.value;
    }

    async handleSendMassCommunication() {
        if (!this.validateMassComposer()) {
            return;
        }

        try {
            this.isLoading = true;

            const result = await sendMassCommunication({
                campaignType: this.massComposerData.campaignType,
                subject: this.massComposerData.subject,
                message: this.massComposerData.message,
                priority: this.massComposerData.priority,
                sendToAll: this.massComposerData.sendToAll,
                selectedGroupIds: this.massComposerData.selectedGroups,
                scheduleDate: this.massComposerData.scheduleDate,
                chapterFilter: this.chapterFilter
            });

            this.showToast('Success', `Mass communication sent to ${result.recipientCount} members`, 'success');
            this.showMassComposer = false;
            this.refreshData();

        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to send mass communication', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    validateMassComposer() {
        if (!this.massComposerData.subject.trim()) {
            this.showToast('Error', 'Subject is required', 'error');
            return false;
        }

        if (!this.massComposerData.message.trim()) {
            this.showToast('Error', 'Message is required', 'error');
            return false;
        }

        if (!this.massComposerData.sendToAll && this.massComposerData.selectedGroups.length === 0) {
            this.showToast('Error', 'Please select member groups or choose "Send to All"', 'error');
            return false;
        }

        return true;
    }

    resetMassComposer() {
        this.massComposerData = {
            campaignType: 'Newsletter',
            subject: '',
            message: '',
            priority: 'Normal',
            sendToAll: false,
            selectedGroups: [],
            scheduleDate: null,
            includeImages: false
        };
    }

    // Campaign creation handlers
    handleCreateCampaign() {
        this.showCampaignCreator = true;
    }

    handleCloseCampaignCreator() {
        this.showCampaignCreator = false;
    }

    handleCampaignFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.campaignData = { ...this.campaignData, [field]: value };
    }

    async handleSaveCampaign() {
        if (!this.validateCampaignData()) {
            return;
        }

        try {
            this.isLoading = true;

            const result = await createCommunicationCampaign({
                campaignName: this.campaignData.name,
                campaignType: this.campaignData.type,
                description: this.campaignData.description,
                startDate: this.campaignData.startDate,
                endDate: this.campaignData.endDate,
                targetAudience: this.campaignData.targetAudience,
                chapterFilter: this.chapterFilter
            });

            this.showToast('Success', 'Communication campaign created successfully', 'success');
            this.showCampaignCreator = false;
            this.refreshData();

        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to create campaign', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    validateCampaignData() {
        if (!this.campaignData.name.trim()) {
            this.showToast('Error', 'Campaign name is required', 'error');
            return false;
        }

        if (!this.campaignData.startDate || !this.campaignData.endDate) {
            this.showToast('Error', 'Start and end dates are required', 'error');
            return false;
        }

        if (new Date(this.campaignData.startDate) >= new Date(this.campaignData.endDate)) {
            this.showToast('Error', 'End date must be after start date', 'error');
            return false;
        }

        return true;
    }

    // Campaign navigation
    handleCampaignClick(event) {
        const campaignId = event.currentTarget.dataset.id;
        this.navigateToRecord(campaignId);
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

    // Data refresh
    async refreshData() {
        try {
            await Promise.all([
                refreshApex(this.metricsWireResult),
                refreshApex(this.campaignsWireResult),
                refreshApex(this.memberGroupsWireResult)
            ]);
        } catch (error) {
            this.showToast('Error', 'Failed to refresh data', 'error');
        }
    }

    // Utility methods
    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString();
    }

    getCampaignStatusVariant(status) {
        const variantMap = {
            'Active': 'success',
            'Planned': 'warning',
            'Completed': 'inverse',
            'Paused': 'error'
        };
        return variantMap[status] || 'inverse';
    }

    calculateParticipationRate(campaign) {
        if (!campaign.totalMembers || campaign.totalMembers === 0) {
            return 0;
        }
        return Math.round((campaign.respondedMembers / campaign.totalMembers) * 100);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Getters for template
    get campaignTypeOptions() {
        return [
            { label: 'Newsletter', value: 'Newsletter' },
            { label: 'Event Promotion', value: 'Event Promotion' },
            { label: 'Fundraising', value: 'Fundraising' },
            { label: 'Announcement', value: 'Announcement' },
            { label: 'Emergency', value: 'Emergency' },
            { label: 'Membership Drive', value: 'Membership Drive' }
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

    get targetAudienceOptions() {
        return [
            { label: 'All Members', value: 'All Members' },
            { label: 'Officers Only', value: 'Officers Only' },
            { label: 'Full Members', value: 'Full Members' },
            { label: 'Associate Members', value: 'Associate Members' },
            { label: 'Prospect Members', value: 'Prospect Members' },
            { label: 'Custom Groups', value: 'Custom Groups' }
        ];
    }

    get hasActiveCampaigns() {
        return this.activeCampaigns && this.activeCampaigns.length > 0;
    }

    get hasMemberGroups() {
        return this.memberGroups && this.memberGroups.length > 0;
    }

    get dashboardHeight() {
        return `height: ${this.height}px;`;
    }
}
