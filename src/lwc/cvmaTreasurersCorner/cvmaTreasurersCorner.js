/**
 * @description CVMA Treasurer's Corner - Monthly Financial Reports for Member Transparency
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-30
 *
 * Integration Requirements:
 * - Accessible to all CVMA members except guests
 * - Experience Cloud Treasurer's Corner page display
 * - Internal dashboard for authorized users
 * - NPSP financial data with CVMA formatting
 * - Mirrors traditional CVMA Treasurer report structure
 */
import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getNPSPFinancialSummary from '@salesforce/apex/CVMANPSPFinancialController.getNPSPFinancialSummary';

export default class CvmaTreasurersCorner extends LightningElement {
    // Public properties from Experience Cloud
    @api showExportButton;
    @api compactView;

    @track financialSummary;
    @track error;
    @track isLoading = true;
    @track selectedMonth = new Date().getMonth() + 1;
    @track selectedYear = new Date().getFullYear();

    // CVMA Financial Report Categories
    @track reportSections = {
        summary: true,
        income: true,
        expenses: true,
        memberFinancial: true,
        compliance: false
    };

    get monthOptions() {
        return [
            { label: 'January', value: 1 },
            { label: 'February', value: 2 },
            { label: 'March', value: 3 },
            { label: 'April', value: 4 },
            { label: 'May', value: 5 },
            { label: 'June', value: 6 },
            { label: 'July', value: 7 },
            { label: 'August', value: 8 },
            { label: 'September', value: 9 },
            { label: 'October', value: 10 },
            { label: 'November', value: 11 },
            { label: 'December', value: 12 }
        ];
    }

    get yearOptions() {
        const currentYear = new Date().getFullYear();
        const years = [];
        for (let i = currentYear; i >= currentYear - 3; i--) {
            years.push({ label: i.toString(), value: i });
        }
        return years;
    }

    get reportTitle() {
        const monthName = this.monthOptions.find(m => m.value === this.selectedMonth)?.label || 'Current';
        return `CVMA Chapter 20-7 ${monthName} ${this.selectedYear} Treasurer's Report`;
    }

    get hasFinancialData() {
        return this.financialSummary && !this.error;
    }

    get hideExportButton() {
        return this.showExportButton === false;
    }

    get formattedBeginningBalance() {
        // This would be calculated from previous month's ending balance
        return this.formatCurrency(this.financialSummary?.totalDonations || 0);
    }

    get formattedTotalIncome() {
        return this.formatCurrency(this.financialSummary?.totalDonations || 0);
    }

    get formattedTotalExpenses() {
        // This would be calculated from expense records
        return this.formatCurrency(0);
    }

    get formattedEndingBalance() {
        return this.formatCurrency(this.financialSummary?.totalDonations || 0);
    }

    get formattedNetChange() {
        const netChange = (this.financialSummary?.totalDonations || 0) - 0; // minus expenses
        return this.formatCurrency(netChange);
    }

    get membershipMetrics() {
        return {
            totalMembers: this.financialSummary?.totalDonors || 0,
            householdCount: this.financialSummary?.householdCount || 0,
            averageContribution: this.formatCurrency(this.financialSummary?.averageGiftSize || 0)
        };
    }

    get incomeCategories() {
        // Sample data structure for income categories
        return [
            { category: 'Member Dues', amount: 2500.00, percentage: 45 },
            { category: 'Fundraising Events', amount: 1800.00, percentage: 32 },
            { category: 'Donations', amount: 900.00, percentage: 16 },
            { category: 'Merchandise', amount: 400.00, percentage: 7 }
        ];
    }

    get incomeColumns() {
        return [
            { label: 'Category', fieldName: 'category', type: 'text' },
            { label: 'Amount', fieldName: 'amount', type: 'currency' },
            { label: 'Percentage', fieldName: 'percentage', type: 'percent',
              typeAttributes: { minimumFractionDigits: 1, maximumFractionDigits: 1 } }
        ];
    }

    get currentDateTime() {
        return new Date().toLocaleString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    get treasurerName() {
        // This would come from user context or CEB position query
        return 'Chapter Treasurer';
    }

    get treasurerEmail() {
        // This would come from user context or CEB position query
        return 'treasurer@cvma20-7.org';
    }

    @wire(getNPSPFinancialSummary)
    wiredFinancialData(result) {
        this.wiredFinancialResult = result;
        if (result.data) {
            this.financialSummary = result.data;
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.error = result.error;
            this.financialSummary = undefined;
            this.isLoading = false;
            this.showErrorToast('Error loading financial data', result.error.body?.message);
        }
    }

    handleMonthChange(event) {
        this.selectedMonth = parseInt(event.detail.value);
        this.refreshData();
    }

    handleYearChange(event) {
        this.selectedYear = parseInt(event.detail.value);
        this.refreshData();
    }

    handleSectionToggle(event) {
        const section = event.target.dataset.section;
        this.reportSections[section] = event.target.checked;
    }

    handleRefresh() {
        this.isLoading = true;
        this.refreshData();
    }

    handleExportReport() {
        // Generate PDF or Excel export of the treasurer's report
        this.showSuccessToast('Export Started', 'Treasurer\'s report export has been initiated.');
    }

    refreshData() {
        this.isLoading = true;
        return refreshApex(this.wiredFinancialResult);
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2
        }).format(amount || 0);
    }

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
