import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getMemberEngagementAnalytics from '@salesforce/apex/CVMANPSPAnalyticsController.getMemberEngagementAnalytics';
import getFinancialEngagementAnalytics from '@salesforce/apex/CVMANPSPAnalyticsController.getFinancialEngagementAnalytics';
import getEventParticipationAnalytics from '@salesforce/apex/CVMANPSPAnalyticsController.getEventParticipationAnalytics';

export default class CvmaNPSPAnalytics extends LightningElement {
    @track memberData = {};
    @track financialData = {};
    @track eventData = {};
    @track isLoading = true;
    @track error;
    @track selectedView = 'overview';

    // Wire member engagement data
    @wire(getMemberEngagementAnalytics)
    wiredMemberData(result) {
        this.wiredMemberResult = result;
        const { data, error } = result;

        if (data) {
            this.memberData = data;
            this.error = undefined;
            this.checkLoadingComplete();
        } else if (error) {
            this.error = 'Error loading member analytics: ' + (error.body?.message || error.message);
            this.isLoading = false;
        }
    }

    // Wire financial engagement data
    @wire(getFinancialEngagementAnalytics)
    wiredFinancialData(result) {
        this.wiredFinancialResult = result;
        const { data, error } = result;

        if (data) {
            this.financialData = data;
            this.error = undefined;
            this.checkLoadingComplete();
        } else if (error) {
            this.error = 'Error loading financial analytics: ' + (error.body?.message || error.message);
            this.isLoading = false;
        }
    }

    // Wire event participation data
    @wire(getEventParticipationAnalytics)
    wiredEventData(result) {
        this.wiredEventResult = result;
        const { data, error } = result;

        if (data) {
            this.eventData = data;
            this.error = undefined;
            this.checkLoadingComplete();
        } else if (error) {
            this.error = 'Error loading event analytics: ' + (error.body?.message || error.message);
            this.isLoading = false;
        }
    }

    // Computed properties
    get hasMemberData() {
        return this.memberData && Object.keys(this.memberData).length > 0;
    }

    get hasFinancialData() {
        return this.financialData && Object.keys(this.financialData).length > 0;
    }

    get hasEventData() {
        return this.eventData && Object.keys(this.eventData).length > 0;
    }

    get isOverviewView() {
        return this.selectedView === 'overview';
    }

    get isMemberView() {
        return this.selectedView === 'members';
    }

    get isFinancialView() {
        return this.selectedView === 'financial';
    }

    get isEventView() {
        return this.selectedView === 'events';
    }

    get formattedRetentionRate() {
        return this.memberData.memberRetentionRate ? this.memberData.memberRetentionRate.toFixed(1) + '%' : '0%';
    }

    get formattedEngagementScore() {
        return this.memberData.averageEngagementScore ? this.memberData.averageEngagementScore.toFixed(1) : '0';
    }

    get formattedThisYearTotal() {
        return this.formatCurrency(this.financialData.thisYearTotal);
    }

    get formattedAverageDonation() {
        return this.formatCurrency(this.financialData.averageDonation);
    }

    get formattedGrowthRate() {
        const rate = this.financialData.growthRate;
        return rate ? (rate > 0 ? '+' : '') + rate.toFixed(1) + '%' : '0%';
    }

    get formattedAttendanceRate() {
        const rate = this.eventData.overallAttendanceRate;
        return rate ? rate.toFixed(1) + '%' : '0%';
    }

    get retentionRateClass() {
        const rate = this.memberData.memberRetentionRate;
        if (!rate) return '';
        if (rate >= 90) return 'slds-text-color_success';
        if (rate >= 75) return 'slds-text-color_warning';
        return 'slds-text-color_error';
    }

    get growthRateClass() {
        const rate = this.financialData.growthRate;
        if (!rate) return '';
        if (rate > 0) return 'slds-text-color_success';
        if (rate === 0) return 'slds-text-color_default';
        return 'slds-text-color_error';
    }

    get attendanceRateClass() {
        const rate = this.eventData.overallAttendanceRate;
        if (!rate) return '';
        if (rate >= 80) return 'slds-text-color_success';
        if (rate >= 60) return 'slds-text-color_warning';
        return 'slds-text-color_error';
    }

    get engagementMetricsList() {
        return this.memberData.engagementMetrics || [];
    }

    get membershipTrendsList() {
        return this.memberData.membershipTrends || [];
    }

    get participationActivities() {
        const activities = this.memberData.participationByActivity;
        if (!activities) return [];

        return Object.keys(activities).map(activity => ({
            activity: activity,
            count: activities[activity],
            id: activity.replace(/\s+/g, '_').toLowerCase()
        }));
    }

    get eventTypeParticipation() {
        const participation = this.eventData.eventTypeParticipation;
        if (!participation) return [];

        return Object.keys(participation).map(type => ({
            type: type,
            count: participation[type],
            id: type.replace(/\s+/g, '_').toLowerCase()
        }));
    }

    get recentEventMetrics() {
        return this.eventData.eventMetrics || [];
    }

    get viewOptions() {
        return [
            { label: 'Overview', value: 'overview' },
            { label: 'Member Analytics', value: 'members' },
            { label: 'Financial Analytics', value: 'financial' },
            { label: 'Event Analytics', value: 'events' }
        ];
    }

    // Event handlers
    handleRefresh() {
        this.isLoading = true;
        Promise.all([
            refreshApex(this.wiredMemberResult),
            refreshApex(this.wiredFinancialResult),
            refreshApex(this.wiredEventResult)
        ]).then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Analytics data refreshed successfully.',
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

    handleViewChange(event) {
        this.selectedView = event.detail.value;
    }

    // Utility methods
    checkLoadingComplete() {
        // Check if all wire methods have completed (either success or error)
        const memberComplete = this.memberData && Object.keys(this.memberData).length > 0;
        const financialComplete = this.financialData && Object.keys(this.financialData).length > 0;
        const eventComplete = this.eventData && Object.keys(this.eventData).length > 0;

        if (memberComplete && financialComplete && eventComplete) {
            this.isLoading = false;
        }
    }

    formatCurrency(value) {
        if (value == null || value === undefined) return '$0.00';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }

    getTrendIcon(trend) {
        switch (trend) {
            case 'up':
                return 'utility:trending';
            case 'down':
                return 'utility:down';
            default:
                return 'utility:dash';
        }
    }

    getTrendClass(trend) {
        switch (trend) {
            case 'up':
                return 'slds-text-color_success';
            case 'down':
                return 'slds-text-color_error';
            default:
                return 'slds-text-color_default';
        }
    }
}
