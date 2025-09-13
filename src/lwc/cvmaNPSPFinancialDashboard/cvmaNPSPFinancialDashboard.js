import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getNPSPFinancialSummary from '@salesforce/apex/CVMANPSPFinancialController.getNPSPFinancialSummary';
import getCampaignROIAnalytics from '@salesforce/apex/CVMANPSPFinancialController.getCampaignROIAnalytics';

export default class CvmaNPSPFinancialDashboard extends LightningElement {
    @track npspData;
    @track campaignROI;
    @track error;
    @track isLoading = true;

    wiredNPSPResult;
    wiredCampaignResult;

    @wire(getNPSPFinancialSummary)
    wiredNPSPData(result) {
        this.wiredNPSPResult = result;
        const { data, error } = result;
        if (data) {
            this.npspData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.npspData = undefined;
            this.showErrorToast('NPSP Data Error', error.body?.message || 'Failed to load NPSP financial data');
        }
        this.isLoading = false;
    }

    @wire(getCampaignROIAnalytics)
    wiredCampaignData(result) {
        this.wiredCampaignResult = result;
        const { data, error } = result;
        if (data) {
            this.campaignROI = data;
        } else if (error) {
            this.showErrorToast('Campaign ROI Error', error.body?.message || 'Failed to load campaign ROI data');
        }
    }

    get formattedTotalDonations() {
        return this.npspData ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.npspData.totalDonations)
            : '$0';
    }

    get formattedAverageGift() {
        return this.npspData ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.npspData.averageGiftSize)
            : '$0';
    }

    get formattedLargestGift() {
        return this.npspData ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.npspData.largestGift)
            : '$0';
    }

    get hasTopDonors() {
        return this.npspData && this.npspData.topDonors && this.npspData.topDonors.length > 0;
    }

    get hasHouseholds() {
        return this.npspData && this.npspData.householdGiving && this.npspData.householdGiving.length > 0;
    }

    get hasCampaignROI() {
        return this.campaignROI && this.campaignROI.length > 0;
    }

    get regionChartData() {
        if (!this.npspData || !this.npspData.givingByRegion) return [];

        return Object.keys(this.npspData.givingByRegion).map(region => ({
            label: region,
            value: this.npspData.givingByRegion[region]
        }));
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount || 0);
    }

    formatPercentage(percentage) {
        return new Intl.NumberFormat('en-US', {
            style: 'percent',
            minimumFractionDigits: 1,
            maximumFractionDigits: 1
        }).format((percentage || 0) / 100);
    }

    handleRefresh() {
        this.isLoading = true;
        return Promise.all([
            refreshApex(this.wiredNPSPResult),
            refreshApex(this.wiredCampaignResult)
        ]).finally(() => {
            this.isLoading = false;
        });
    }

    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }

    showSuccessToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }
}
