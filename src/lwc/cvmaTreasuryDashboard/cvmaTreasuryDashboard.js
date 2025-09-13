/**
 * @description CVMA Treasury Dashboard - Standard Feature Integration LWC
 * User Story #18: Treasury Dashboard with 75% code reduction
 * Uses Lightning Design System standard components
 */
import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTreasurySummary from '@salesforce/apex/CVMATreasuryDashboardController.getTreasurySummary';
import getCampaignMemberFinancials from '@salesforce/apex/CVMATreasuryDashboardController.getCampaignMemberFinancials';

export default class CvmaTreasuryDashboard extends LightningElement {
    @track treasuryData;
    @track campaignMemberData;
    @track error;
    @track isLoading = true;

    // Wire treasury summary data
    @wire(getTreasurySummary)
    wiredTreasuryData(result) {
        this.treasuryWireResult = result;
        const { data, error } = result;

        if (data) {
            this.treasuryData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.treasuryData = undefined;
            this.showErrorToast('Treasury data loading failed', error.body?.message);
        }
        this.isLoading = false;
    }

    // Wire campaign member financial data
    @wire(getCampaignMemberFinancials)
    wiredCampaignData(result) {
        this.campaignWireResult = result;
        const { data, error } = result;

        if (data) {
            this.campaignMemberData = data;
        } else if (error) {
            this.showErrorToast('Campaign member data loading failed', error.body?.message);
        }
    }

    // Computed properties for dashboard display
    get formattedTotalRevenue() {
        return this.treasuryData?.totalRevenue ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })
                .format(this.treasuryData.totalRevenue) : '$0.00';
    }

    get formattedMonthlyRevenue() {
        return this.treasuryData?.monthlyRevenue ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })
                .format(this.treasuryData.monthlyRevenue) : '$0.00';
    }

    get formattedBudgetVariance() {
        const variance = this.treasuryData?.budgetVariance || 0;
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })
            .format(variance);
    }

    get budgetVarianceClass() {
        const variance = this.treasuryData?.budgetVariance || 0;
        return variance >= 0 ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    get budgetVarianceIcon() {
        const variance = this.treasuryData?.budgetVariance || 0;
        return variance >= 0 ? 'utility:success' : 'utility:warning';
    }

    get hasCampaignData() {
        return this.treasuryData?.campaignBreakdown && this.treasuryData.campaignBreakdown.length > 0;
    }

    get hasMemberData() {
        return this.campaignMemberData && this.campaignMemberData.length > 0;
    }

    // Campaign breakdown columns for lightning-datatable
    get campaignColumns() {
        return [
            { label: 'Campaign', fieldName: 'campaignName', type: 'text' },
            { label: 'Type', fieldName: 'campaignType', type: 'text' },
            { label: 'Status', fieldName: 'status', type: 'text' },
            {
                label: 'Revenue',
                fieldName: 'revenue',
                type: 'currency',
                typeAttributes: { currencyCode: 'USD' }
            },
            { label: 'Opportunities', fieldName: 'opportunities', type: 'number' },
            { label: 'Members', fieldName: 'memberCount', type: 'number' },
            {
                label: 'Response Rate',
                fieldName: 'responseRate',
                type: 'percent',
                typeAttributes: { minimumFractionDigits: 1 }
            }
        ];
    }

    // Member analytics columns
    get memberColumns() {
        return [
            { label: 'Campaign', fieldName: 'campaignName', type: 'text' },
            {
                label: 'Revenue',
                fieldName: 'revenue',
                type: 'currency',
                typeAttributes: { currencyCode: 'USD' }
            },
            { label: 'Total Members', fieldName: 'totalMembers', type: 'number' },
            { label: 'Responded Yes', fieldName: 'respondedYes', type: 'number' },
            {
                label: 'Response Rate',
                fieldName: 'responseRate',
                type: 'percent',
                typeAttributes: { minimumFractionDigits: 1 }
            },
            {
                label: 'Revenue/Member',
                fieldName: 'revenuePerMember',
                type: 'currency',
                typeAttributes: { currencyCode: 'USD' }
            }
        ];
    }

    // Refresh dashboard data
    handleRefresh() {
        this.isLoading = true;
        Promise.all([
            refreshApex(this.treasuryWireResult),
            refreshApex(this.campaignWireResult)
        ]).then(() => {
            this.isLoading = false;
            this.showSuccessToast('Treasury Dashboard Refreshed', 'Data updated successfully');
        }).catch(error => {
            this.isLoading = false;
            this.showErrorToast('Refresh Failed', error.body?.message || 'Unknown error');
        });
    }

    // Toast notification helpers
    showSuccessToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        }));
    }

    showErrorToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        }));
    }
}
