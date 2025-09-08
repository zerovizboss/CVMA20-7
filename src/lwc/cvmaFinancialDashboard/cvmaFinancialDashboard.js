import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getFinancialSummary from '@salesforce/apex/CVMAFinancialController.getFinancialSummary';
import getPaymentRecords from '@salesforce/apex/CVMAFinancialController.getPaymentRecords';
import getFinancialTransactions from '@salesforce/apex/CVMAFinancialController.getFinancialTransactions';
import processPayment from '@salesforce/apex/CVMAFinancialController.processPayment';
import getPaymentMethods from '@salesforce/apex/CVMAFinancialController.getPaymentMethods';

export default class CvmaFinancialDashboard extends LightningElement {
    @track selectedTab = 'summary';
    @track isLoading = false;
    @track error;

    // Financial Summary Data
    @track financialSummary = {};
    @track chartData = [];
    @track revenueChartData = [];
    @track expenseChartData = [];

    // Payment Records Data
    @track paymentRecords = [];
    @track paymentFilters = {
        year: new Date().getFullYear(),
        status: '',
        pageSize: 25,
        pageNumber: 0
    };
    @track paymentPagination = {};

    // Transaction Data
    @track transactions = [];
    @track transactionFilters = {
        startDate: null,
        endDate: null,
        transactionType: '',
        pageSize: 25,
        pageNumber: 0
    };
    @track transactionPagination = {};

    // Payment Processing
    @track showPaymentModal = false;
    @track selectedPaymentRecord = {};
    @track paymentData = {
        amount: 0,
        paymentMethod: '',
        referenceNumber: '',
        notes: ''
    };
    @track paymentMethods = [];

    // Wired Data
    _financialSummaryResult;
    _paymentRecordsResult;
    _transactionsResult;

    connectedCallback() {
        this.setDefaultDates();
        this.loadData();
    }

    setDefaultDates() {
        const today = new Date();
        const startOfYear = new Date(today.getFullYear(), 0, 1);

        this.transactionFilters.startDate = this.formatDate(startOfYear);
        this.transactionFilters.endDate = this.formatDate(today);
    }

    formatDate(date) {
        return date.toISOString().split('T')[0];
    }

    @wire(getFinancialSummary, {
        startDate: '$transactionFilters.startDate',
        endDate: '$transactionFilters.endDate'
    })
    wiredFinancialSummary(result) {
        this._financialSummaryResult = result;
        if (result.data) {
            this.financialSummary = result.data;
            this.processChartData();
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.showToast('Error', 'Failed to load financial summary', 'error');
        }
    }

    @wire(getPaymentRecords, {
        year: '$paymentFilters.year',
        status: '$paymentFilters.status',
        pageSize: '$paymentFilters.pageSize',
        pageNumber: '$paymentFilters.pageNumber'
    })
    wiredPaymentRecords(result) {
        this._paymentRecordsResult = result;
        if (result.data) {
            this.paymentRecords = result.data.records || [];
            this.paymentPagination = {
                totalCount: result.data.totalCount,
                pageSize: result.data.pageSize,
                pageNumber: result.data.pageNumber,
                hasMore: result.data.hasMore
            };
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.showToast('Error', 'Failed to load payment records', 'error');
        }
    }

    @wire(getFinancialTransactions, {
        startDate: '$transactionFilters.startDate',
        endDate: '$transactionFilters.endDate',
        transactionType: '$transactionFilters.transactionType',
        pageSize: '$transactionFilters.pageSize',
        pageNumber: '$transactionFilters.pageNumber'
    })
    wiredTransactions(result) {
        this._transactionsResult = result;
        if (result.data) {
            this.transactions = result.data.transactions || [];
            this.transactionPagination = {
                totalCount: result.data.totalCount,
                pageSize: result.data.pageSize,
                pageNumber: result.data.pageNumber,
                hasMore: result.data.hasMore
            };
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.showToast('Error', 'Failed to load transactions', 'error');
        }
    }

    @wire(getPaymentMethods)
    wiredPaymentMethods(result) {
        if (result.data) {
            this.paymentMethods = result.data;
        }
    }

    processChartData() {
        if (!this.financialSummary.revenueByCategory) return;

        // Revenue chart data
        this.revenueChartData = Object.keys(this.financialSummary.revenueByCategory).map(category => ({
            name: category,
            value: this.financialSummary.revenueByCategory[category]
        }));

        // Expense chart data
        if (this.financialSummary.expensesByCategory) {
            this.expenseChartData = Object.keys(this.financialSummary.expensesByCategory).map(category => ({
                name: category,
                value: this.financialSummary.expensesByCategory[category]
            }));
        }
    }

    // Event Handlers
    handleTabChange(event) {
        this.selectedTab = event.target.value;
    }

    handleYearChange(event) {
        this.paymentFilters.year = parseInt(event.target.value);
        this.paymentFilters.pageNumber = 0;
    }

    handleStatusFilterChange(event) {
        this.paymentFilters.status = event.target.value;
        this.paymentFilters.pageNumber = 0;
    }

    handleDateFilterChange(event) {
        const field = event.target.dataset.field;
        this.transactionFilters[field] = event.target.value;
        this.transactionFilters.pageNumber = 0;
    }

    handleTransactionTypeChange(event) {
        this.transactionFilters.transactionType = event.target.value;
        this.transactionFilters.pageNumber = 0;
    }

    // Payment Processing
    handleProcessPayment(event) {
        const recordId = event.target.dataset.recordId;
        this.selectedPaymentRecord = this.paymentRecords.find(record => record.id === recordId);
        this.paymentData.amount = this.selectedPaymentRecord.balance;
        this.showPaymentModal = true;
    }

    handlePaymentInputChange(event) {
        const field = event.target.dataset.field;
        this.paymentData[field] = event.target.value;
    }

    async handleSavePayment() {
        try {
            this.isLoading = true;

            const result = await processPayment({
                opportunityId: this.selectedPaymentRecord.id,
                amount: parseFloat(this.paymentData.amount),
                paymentMethod: this.paymentData.paymentMethod,
                referenceNumber: this.paymentData.referenceNumber,
                notes: this.paymentData.notes
            });

            if (result.success) {
                this.showToast('Success', result.message, 'success');
                this.closePaymentModal();
                this.refreshData();
            } else {
                this.showToast('Error', result.message, 'error');
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Payment processing failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    closePaymentModal() {
        this.showPaymentModal = false;
        this.selectedPaymentRecord = {};
        this.paymentData = {
            amount: 0,
            paymentMethod: '',
            referenceNumber: '',
            notes: ''
        };
    }

    // Pagination
    handlePaymentPrevious() {
        if (this.paymentFilters.pageNumber > 0) {
            this.paymentFilters.pageNumber--;
        }
    }

    handlePaymentNext() {
        if (this.paymentPagination.hasMore) {
            this.paymentFilters.pageNumber++;
        }
    }

    handleTransactionPrevious() {
        if (this.transactionFilters.pageNumber > 0) {
            this.transactionFilters.pageNumber--;
        }
    }

    handleTransactionNext() {
        if (this.transactionPagination.hasMore) {
            this.transactionFilters.pageNumber++;
        }
    }

    // Utility Methods
    async refreshData() {
        await Promise.all([
            refreshApex(this._financialSummaryResult),
            refreshApex(this._paymentRecordsResult),
            refreshApex(this._transactionsResult)
        ]);
    }

    async loadData() {
        this.isLoading = true;
        try {
            await this.refreshData();
        } catch (error) {
            this.showToast('Error', 'Failed to load data', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Getters
    get tabOptions() {
        return [
            { label: 'Financial Summary', value: 'summary' },
            { label: 'Payment Records', value: 'payments' },
            { label: 'Transactions', value: 'transactions' }
        ];
    }

    get yearOptions() {
        const currentYear = new Date().getFullYear();
        const years = [];
        for (let i = currentYear; i >= currentYear - 5; i--) {
            years.push({ label: i.toString(), value: i });
        }
        return years;
    }

    get statusOptions() {
        return [
            { label: 'All', value: '' },
            { label: 'Paid', value: 'Paid' },
            { label: 'Pending', value: 'Pending' },
            { label: 'Overdue', value: 'Overdue' }
        ];
    }

    get transactionTypeOptions() {
        return [
            { label: 'All', value: '' },
            { label: 'Dues Payment', value: 'Dues Payment' },
            { label: 'Donation', value: 'Donation' },
            { label: 'Expense', value: 'Expense' },
            { label: 'Fundraiser', value: 'Fundraiser' }
        ];
    }

    get formattedCurrency() {
        return (value) => {
            return new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD'
            }).format(value || 0);
        };
    }

    get isFirstPaymentPage() {
        return this.paymentFilters.pageNumber <= 0;
    }

    get isLastPaymentPage() {
        return !this.paymentPagination.hasMore;
    }

    get isFirstTransactionPage() {
        return this.transactionFilters.pageNumber <= 0;
    }

    get isLastTransactionPage() {
        return !this.transactionPagination.hasMore;
    }

    get currentPaymentPage() {
        return this.paymentFilters.pageNumber + 1;
    }

    get currentTransactionPage() {
        return this.transactionFilters.pageNumber + 1;
    }

    get paymentRecordColumns() {
        return [
            { label: 'Member', fieldName: 'memberName', type: 'text' },
            { label: 'Level', fieldName: 'memberLevel', type: 'text' },
            { label: 'Amount Due', fieldName: 'amountDue', type: 'currency' },
            { label: 'Amount Paid', fieldName: 'amountPaid', type: 'currency' },
            { label: 'Balance', fieldName: 'balance', type: 'currency' },
            { label: 'Status', fieldName: 'status', type: 'text' },
            { label: 'Due Date', fieldName: 'dueDate', type: 'date' },
            { label: 'Days Past Due', fieldName: 'daysPastDue', type: 'number' },
            {
                type: 'action',
                typeAttributes: {
                    rowActions: [
                        { label: 'Process Payment', name: 'process_payment' }
                    ]
                }
            }
        ];
    }

    get transactionColumns() {
        return [
            { label: 'Date', fieldName: 'transactionDate', type: 'date' },
            { label: 'Type', fieldName: 'transactionType', type: 'text' },
            { label: 'Description', fieldName: 'description', type: 'text' },
            { label: 'Amount', fieldName: 'amount', type: 'currency' },
            { label: 'Category', fieldName: 'category', type: 'text' },
            { label: 'Member', fieldName: 'memberName', type: 'text' },
            { label: 'Payment Method', fieldName: 'paymentMethod', type: 'text' },
            { label: 'Status', fieldName: 'status', type: 'text' },
            { label: 'Reference #', fieldName: 'referenceNumber', type: 'text' }
        ];
    }
}
