import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getEnhancedFinancialDashboard from '@salesforce/apex/CVMAFinancialManagementController.getEnhancedFinancialDashboard';
import getMemberDuesManagement from '@salesforce/apex/CVMAFinancialManagementController.getMemberDuesManagement';
import getFundraisingPerformance from '@salesforce/apex/CVMAFinancialManagementController.getFundraisingPerformance';
import createAnnualDuesOpportunities from '@salesforce/apex/CVMAFinancialManagementController.createAnnualDuesOpportunities';
import getExpenseTrackingAnalytics from '@salesforce/apex/CVMAFinancialManagementController.getExpenseTrackingAnalytics';

export default class CvmaFinancialManagementDashboard extends LightningElement {
    @api userId; // Current user ID
    @api dashboardMode = 'enhanced'; // enhanced, basic, readonly

    // Component state
    @track isLoading = true;
    @track error = null;
    @track selectedTab = 'overview';

    // Financial data
    @track financialDashboard = {};
    @track memberDuesData = {};
    @track fundraisingData = {};
    @track expenseData = {};
    @track hasFinancialAccess = false;

    // Filters and settings
    @track currentYear = new Date().getFullYear();
    @track dateRange = {
        startDate: null,
        endDate: null
    };

    // Modal states
    @track showCreateDuesModal = false;
    @track showExpenseModal = false;
    @track processingOperation = false;

    // Wired results for refresh
    _dashboardResult;
    _memberDuesResult;
    _fundraisingResult;
    _expenseResult;

    connectedCallback() {
        this.initializeDateRange();
        this.loadFinancialData();
    }

    initializeDateRange() {
        const today = new Date();
        const startOfYear = new Date(today.getFullYear(), 0, 1);

        this.dateRange.startDate = this.formatDate(startOfYear);
        this.dateRange.endDate = this.formatDate(today);
    }

    formatDate(date) {
        return date.toISOString().split('T')[0];
    }

    // Wire enhanced financial dashboard
    @wire(getEnhancedFinancialDashboard, { userId: '$userId' })
    wiredFinancialDashboard(result) {
        this._dashboardResult = result;
        if (result.data) {
            this.financialDashboard = result.data;
            this.hasFinancialAccess = result.data.hasTreasurerAccess || false;
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            console.error('Error loading financial dashboard:', result.error);
        }
        this.isLoading = false;
    }

    // Wire member dues data
    @wire(getMemberDuesManagement, { year: '$currentYear' })
    wiredMemberDues(result) {
        this._memberDuesResult = result;
        if (result.data) {
            this.memberDuesData = result.data;
        } else if (result.error) {
            console.error('Error loading member dues:', result.error);
        }
    }

    // Wire fundraising data
    @wire(getFundraisingPerformance, {
        startDate: '$dateRange.startDate',
        endDate: '$dateRange.endDate'
    })
    wiredFundraising(result) {
        this._fundraisingResult = result;
        if (result.data) {
            this.fundraisingData = result.data;
        } else if (result.error) {
            console.error('Error loading fundraising data:', result.error);
        }
    }

    // Wire expense data
    @wire(getExpenseTrackingAnalytics, {
        startDate: '$dateRange.startDate',
        endDate: '$dateRange.endDate'
    })
    wiredExpenses(result) {
        this._expenseResult = result;
        if (result.data) {
            this.expenseData = result.data;
        } else if (result.error) {
            console.error('Error loading expense data:', result.error);
        }
    }

    // Event handlers
    handleTabChange(event) {
        this.selectedTab = event.target.value;
    }

    handleYearChange(event) {
        this.currentYear = parseInt(event.target.value);
    }

    handleDateRangeChange(event) {
        const field = event.target.dataset.field;
        this.dateRange[field] = event.target.value;
    }

    async handleCreateAnnualDues() {
        if (!this.hasFinancialAccess) {
            this.showToast('Access Denied', 'Treasurer permissions required', 'error');
            return;
        }

        this.showCreateDuesModal = true;
    }

    async handleConfirmCreateDues() {
        try {
            this.processingOperation = true;

            const result = await createAnnualDuesOpportunities({
                year: this.currentYear,
                campaignName: `Annual Dues ${this.currentYear}`
            });

            if (result.success) {
                this.showToast('Success',
                    `Created ${result.opportunitiesCreated} dues opportunities for ${result.totalMembers} members`,
                    'success');
                this.refreshAllData();
            } else {
                this.showToast('Error', result.error, 'error');
            }

        } catch (error) {
            console.error('Error creating annual dues:', error);
            this.showToast('Error', 'Failed to create annual dues opportunities', 'error');
        } finally {
            this.processingOperation = false;
            this.showCreateDuesModal = false;
        }
    }

    handleCancelCreateDues() {
        this.showCreateDuesModal = false;
    }

    async handleRefreshData() {
        this.isLoading = true;
        try {
            await this.refreshAllData();
            this.showToast('Success', 'Financial data refreshed', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to refresh data', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleExportData() {
        if (!this.hasFinancialAccess) {
            this.showToast('Access Denied', 'Treasurer permissions required', 'error');
            return;
        }

        // Implementation for data export would go here
        this.showToast('Info', 'Export functionality will be implemented in future release', 'info');
    }

    async loadFinancialData() {
        try {
            this.isLoading = true;
            // Data is loaded via @wire decorators
        } catch (error) {
            this.error = error;
            console.error('Error loading financial data:', error);
        }
    }

    async refreshAllData() {
        await Promise.all([
            refreshApex(this._dashboardResult),
            refreshApex(this._memberDuesResult),
            refreshApex(this._fundraisingResult),
            refreshApex(this._expenseResult)
        ]);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    // Getters for UI
    get tabOptions() {
        return [
            { label: 'Overview', value: 'overview' },
            { label: 'Member Dues', value: 'dues' },
            { label: 'Fundraising', value: 'fundraising' },
            { label: 'Expenses', value: 'expenses' },
            { label: 'Reports', value: 'reports' }
        ];
    }

    get yearOptions() {
        const currentYear = new Date().getFullYear();
        const years = [];
        for (let i = currentYear + 1; i >= currentYear - 3; i--) {
            years.push({ label: i.toString(), value: i });
        }
        return years;
    }

    get showOverview() {
        return this.selectedTab === 'overview';
    }

    get showDues() {
        return this.selectedTab === 'dues';
    }

    get showFundraising() {
        return this.selectedTab === 'fundraising';
    }

    get showExpenses() {
        return this.selectedTab === 'expenses';
    }

    get showReports() {
        return this.selectedTab === 'reports';
    }

    get hasError() {
        return this.error != null;
    }

    get errorMessage() {
        if (this.error) {
            return this.error.body ? this.error.body.message : this.error.message;
        }
        return '';
    }

    // Financial metrics getters
    get totalRevenue() {
        return this.financialDashboard.npspDashboard?.totalRevenue || 0;
    }

    get totalExpenses() {
        return this.financialDashboard.npspDashboard?.totalExpenses || 0;
    }

    get netIncome() {
        return this.totalRevenue - this.totalExpenses;
    }

    get netIncomeClass() {
        return this.netIncome >= 0 ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    get collectionRate() {
        const analytics = this.memberDuesData.duesAnalysis;
        return analytics?.collectionRate || 0;
    }

    get collectionRateClass() {
        const rate = this.collectionRate;
        if (rate >= 90) return 'slds-text-color_success';
        if (rate >= 75) return 'slds-text-color_warning';
        return 'slds-text-color_error';
    }

    get activeCampaigns() {
        return this.fundraisingData.campaigns || [];
    }

    get topFundraiser() {
        const campaigns = this.activeCampaigns;
        if (campaigns.length === 0) return null;
        return campaigns.reduce((top, campaign) =>
            (campaign.AmountWonOpportunities || 0) > (top.AmountWonOpportunities || 0) ? campaign : top
        );
    }

    get recentExpenses() {
        return this.expenseData.expenses || [];
    }

    get monthlyExpenseTotal() {
        const expenses = this.recentExpenses;
        const thisMonth = new Date().getMonth();
        return expenses
            .filter(expense => new Date(expense.CloseDate).getMonth() === thisMonth)
            .reduce((total, expense) => total + (expense.Amount || 0), 0);
    }

    get dashboardTitle() {
        return `CVMA Financial Management - ${this.currentYear}`;
    }

    get accessMessage() {
        if (!this.hasFinancialAccess) {
            return 'Limited access - Contact treasurer for full financial dashboard access';
        }
        return 'Full financial management access';
    }

    get canCreateDues() {
        return this.hasFinancialAccess && !this.processingOperation;
    }

    get canExportData() {
        return this.hasFinancialAccess && !this.processingOperation;
    }

    // Formatting helpers
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value || 0);
    }

    formatPercent(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'percent',
            minimumFractionDigits: 1,
            maximumFractionDigits: 1
        }).format((value || 0) / 100);
    }

    formatNumber(value) {
        return new Intl.NumberFormat('en-US').format(value || 0);
    }
}
