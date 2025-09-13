import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getBudgetSummary from '@salesforce/apex/CVMABudgetManagementController.getBudgetSummary';
import updateCampaignBudget from '@salesforce/apex/CVMABudgetManagementController.updateCampaignBudget';
import getBudgetVarianceAnalysis from '@salesforce/apex/CVMABudgetManagementController.getBudgetVarianceAnalysis';

export default class CvmaBudgetManagement extends LightningElement {
    @track budgetData;
    @track varianceData;
    @track error;
    @track isLoading = true;
    @track showBudgetModal = false;
    @track selectedCampaign = {};
    @track newBudgetAmount = 0;

    wiredBudgetResult;
    wiredVarianceResult;

    @wire(getBudgetSummary)
    wiredBudgetData(result) {
        this.wiredBudgetResult = result;
        const { data, error } = result;
        if (data) {
            this.budgetData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.budgetData = undefined;
            this.showErrorToast('Budget Data Error', error.body?.message || 'Failed to load budget data');
        }
        this.isLoading = false;
    }

    @wire(getBudgetVarianceAnalysis)
    wiredVarianceData(result) {
        this.wiredVarianceResult = result;
        const { data, error } = result;
        if (data) {
            this.varianceData = data;
        } else if (error) {
            this.showErrorToast('Variance Analysis Error', error.body?.message || 'Failed to load variance data');
        }
    }

    get formattedTotalBudget() {
        return this.budgetData ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.budgetData.totalBudget)
            : '$0';
    }

    get formattedTotalSpent() {
        return this.budgetData ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.budgetData.totalSpent)
            : '$0';
    }

    get formattedTotalRemaining() {
        return this.budgetData ?
            new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.budgetData.totalRemaining)
            : '$0';
    }

    get formattedBudgetUtilization() {
        return this.budgetData ?
            new Intl.NumberFormat('en-US', {
                style: 'percent',
                minimumFractionDigits: 1,
                maximumFractionDigits: 1
            }).format((this.budgetData.budgetUtilization || 0) / 100)
            : '0%';
    }

    get budgetUtilizationClass() {
        if (!this.budgetData) return 'slds-text-color_default';

        const utilization = this.budgetData.budgetUtilization || 0;
        if (utilization > 100) return 'slds-text-color_error';
        if (utilization > 80) return 'slds-text-color_warning';
        return 'slds-text-color_success';
    }

    get hasCampaignBudgets() {
        return this.budgetData && this.budgetData.campaignBudgets && this.budgetData.campaignBudgets.length > 0;
    }

    get hasBudgetAlerts() {
        return this.budgetData && this.budgetData.budgetAlerts && this.budgetData.budgetAlerts.length > 0;
    }

    get hasVarianceData() {
        return this.varianceData && this.varianceData.length > 0;
    }

    get categoryChartData() {
        if (!this.budgetData || !this.budgetData.spendingByCategory) return [];

        return Object.keys(this.budgetData.spendingByCategory).map(category => ({
            label: category,
            value: this.budgetData.spendingByCategory[category],
            formattedValue: this.formatCurrency(this.budgetData.spendingByCategory[category])
        }));
    }

    get alertsByType() {
        if (!this.budgetData || !this.budgetData.budgetAlerts) return {};

        const alerts = this.budgetData.budgetAlerts;
        return {
            high: alerts.filter(alert => alert.severity === 'High'),
            medium: alerts.filter(alert => alert.severity === 'Medium'),
            low: alerts.filter(alert => alert.severity === 'Low')
        };
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

    formatDate(dateValue) {
        if (!dateValue) return '';
        return new Date(dateValue).toLocaleDateString('en-US');
    }

    getUtilizationProgressClass(utilization) {
        if (utilization > 100) return 'slds-progress-bar__value slds-progress-bar__value_success';
        if (utilization > 80) return 'slds-progress-bar__value slds-progress-bar__value_warning';
        return 'slds-progress-bar__value slds-progress-bar__value_success';
    }

    getVarianceClass(variance) {
        if (variance > 20) return 'slds-text-color_error';
        if (variance > 10) return 'slds-text-color_warning';
        if (variance > -10) return 'slds-text-color_success';
        if (variance > -20) return 'slds-text-color_default';
        return 'slds-text-color_weak';
    }

    getAlertIcon(severity) {
        switch(severity) {
            case 'High': return 'utility:error';
            case 'Medium': return 'utility:warning';
            default: return 'utility:info';
        }
    }

    getAlertClass(severity) {
        switch(severity) {
            case 'High': return 'slds-theme_error';
            case 'Medium': return 'slds-theme_warning';
            default: return 'slds-theme_info';
        }
    }

    handleEditBudget(event) {
        const campaignId = event.currentTarget.dataset.campaignId;
        const campaign = this.budgetData.campaignBudgets.find(cb => cb.campaignId === campaignId);

        if (campaign) {
            this.selectedCampaign = { ...campaign };
            this.newBudgetAmount = campaign.budgetedCost;
            this.showBudgetModal = true;
        }
    }

    handleBudgetAmountChange(event) {
        this.newBudgetAmount = parseFloat(event.target.value) || 0;
    }

    async handleSaveBudget() {
        try {
            this.isLoading = true;

            const updatedCampaign = await updateCampaignBudget({
                campaignId: this.selectedCampaign.campaignId,
                newBudget: this.newBudgetAmount
            });

            // Refresh data
            await Promise.all([
                refreshApex(this.wiredBudgetResult),
                refreshApex(this.wiredVarianceResult)
            ]);

            this.showBudgetModal = false;
            this.showSuccessToast('Budget Updated',
                `Budget for ${this.selectedCampaign.campaignName} updated successfully`);

        } catch (error) {
            this.showErrorToast('Update Failed', error.body?.message || 'Failed to update budget');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancelBudget() {
        this.showBudgetModal = false;
        this.selectedCampaign = {};
        this.newBudgetAmount = 0;
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await Promise.all([
                refreshApex(this.wiredBudgetResult),
                refreshApex(this.wiredVarianceResult)
            ]);
            this.showSuccessToast('Data Refreshed', 'Budget data has been updated');
        } catch (error) {
            this.showErrorToast('Refresh Failed', 'Failed to refresh data');
        } finally {
            this.isLoading = false;
        }
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

    showWarningToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning'
        });
        this.dispatchEvent(evt);
    }
}
