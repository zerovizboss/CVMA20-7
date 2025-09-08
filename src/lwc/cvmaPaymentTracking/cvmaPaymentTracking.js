import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPaymentRecords from '@salesforce/apex/CVMAFinancialController.getPaymentRecords';
import processPayment from '@salesforce/apex/CVMAFinancialController.processPayment';
import getPaymentMethods from '@salesforce/apex/CVMAFinancialController.getPaymentMethods';

export default class CvmaPaymentTracking extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track isLoading = false;
    @track error;
    @track paymentRecords = [];
    @track showPaymentModal = false;
    @track selectedRecord = {};
    @track paymentData = {
        amount: 0,
        paymentMethod: '',
        referenceNumber: '',
        notes: ''
    };
    @track paymentMethods = [];

    // Filters
    @track filters = {
        year: new Date().getFullYear(),
        status: '',
        pageSize: 10,
        pageNumber: 0
    };

    @track pagination = {
        totalCount: 0,
        hasMore: false
    };

    _paymentRecordsResult;

    connectedCallback() {
        this.loadData();
    }

    @wire(getPaymentRecords, {
        year: '$filters.year',
        status: '$filters.status',
        pageSize: '$filters.pageSize',
        pageNumber: '$filters.pageNumber'
    })
    wiredPaymentRecords(result) {
        this._paymentRecordsResult = result;
        if (result.data) {
            this.paymentRecords = result.data.records || [];
            this.pagination = {
                totalCount: result.data.totalCount,
                hasMore: result.data.hasMore
            };
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.showToast('Error', 'Failed to load payment records', 'error');
        }
    }

    @wire(getPaymentMethods)
    wiredPaymentMethods(result) {
        if (result.data) {
            this.paymentMethods = result.data;
        }
    }

    // Event Handlers
    handleYearChange(event) {
        this.filters.year = parseInt(event.detail.value);
        this.filters.pageNumber = 0;
    }

    handleStatusChange(event) {
        this.filters.status = event.detail.value;
        this.filters.pageNumber = 0;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'process_payment':
                this.openPaymentModal(row);
                break;
            case 'view_details':
                this.viewPaymentDetails(row);
                break;
            default:
                break;
        }
    }

    openPaymentModal(record) {
        this.selectedRecord = { ...record };
        this.paymentData = {
            amount: record.balance,
            paymentMethod: '',
            referenceNumber: '',
            notes: ''
        };
        this.showPaymentModal = true;
    }

    closePaymentModal() {
        this.showPaymentModal = false;
        this.selectedRecord = {};
        this.paymentData = {
            amount: 0,
            paymentMethod: '',
            referenceNumber: '',
            notes: ''
        };
    }

    handlePaymentInputChange(event) {
        const field = event.target.dataset.field || event.target.name;
        this.paymentData[field] = event.target.value;
    }

    async handleProcessPayment() {
        if (!this.validatePaymentData()) {
            return;
        }

        try {
            this.isLoading = true;

            const result = await processPayment({
                opportunityId: this.selectedRecord.id,
                amount: parseFloat(this.paymentData.amount),
                paymentMethod: this.paymentData.paymentMethod,
                referenceNumber: this.paymentData.referenceNumber,
                notes: this.paymentData.notes
            });

            if (result.success) {
                this.showToast('Success', result.message, 'success');
                this.closePaymentModal();
                await this.refreshData();
            } else {
                this.showToast('Error', result.message, 'error');
            }
        } catch (error) {
            console.error('Payment processing error:', error);
            this.showToast('Error', error.body?.message || 'Payment processing failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    validatePaymentData() {
        const amount = parseFloat(this.paymentData.amount);
        const balance = parseFloat(this.selectedRecord.balance);

        if (!amount || amount <= 0) {
            this.showToast('Validation Error', 'Please enter a valid payment amount', 'error');
            return false;
        }

        if (amount > balance) {
            this.showToast('Validation Error', 'Payment amount cannot exceed outstanding balance', 'error');
            return false;
        }

        if (!this.paymentData.paymentMethod) {
            this.showToast('Validation Error', 'Please select a payment method', 'error');
            return false;
        }

        return true;
    }

    // Navigation
    handlePrevious() {
        if (this.filters.pageNumber > 0) {
            this.filters.pageNumber--;
        }
    }

    handleNext() {
        if (this.pagination.hasMore) {
            this.filters.pageNumber++;
        }
    }

    // Quick Actions
    handleQuickPayment(event) {
        const recordId = event.target.dataset.recordId;
        const record = this.paymentRecords.find(r => r.id === recordId);
        if (record) {
            this.openPaymentModal(record);
        }
    }

    handleMarkAsPaid(event) {
        const recordId = event.target.dataset.recordId;
        const record = this.paymentRecords.find(r => r.id === recordId);
        if (record) {
            this.paymentData = {
                amount: record.balance,
                paymentMethod: 'Cash',
                referenceNumber: '',
                notes: 'Marked as paid'
            };
            this.selectedRecord = record;
            this.handleProcessPayment();
        }
    }

    // Utility Methods
    async refreshData() {
        await refreshApex(this._paymentRecordsResult);
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
    get yearOptions() {
        const currentYear = new Date().getFullYear();
        const years = [];
        for (let i = currentYear; i >= currentYear - 3; i--) {
            years.push({ label: i.toString(), value: i });
        }
        return years;
    }

    get statusOptions() {
        return [
            { label: 'All', value: '' },
            { label: 'Pending', value: 'Pending' },
            { label: 'Overdue', value: 'Overdue' },
            { label: 'Paid', value: 'Paid' }
        ];
    }

    get columns() {
        return [
            {
                label: 'Member',
                fieldName: 'memberName',
                type: 'text',
                cellAttributes: { alignment: 'left' }
            },
            {
                label: 'Level',
                fieldName: 'memberLevel',
                type: 'text',
                cellAttributes: { alignment: 'center' }
            },
            {
                label: 'Due',
                fieldName: 'amountDue',
                type: 'currency',
                cellAttributes: { alignment: 'right' }
            },
            {
                label: 'Paid',
                fieldName: 'amountPaid',
                type: 'currency',
                cellAttributes: { alignment: 'right' }
            },
            {
                label: 'Balance',
                fieldName: 'balance',
                type: 'currency',
                cellAttributes: { alignment: 'right' }
            },
            {
                label: 'Status',
                fieldName: 'status',
                type: 'text',
                cellAttributes: {
                    alignment: 'center',
                    class: { fieldName: 'statusClass' }
                }
            },
            {
                label: 'Due Date',
                fieldName: 'dueDate',
                type: 'date',
                cellAttributes: { alignment: 'center' }
            },
            {
                type: 'action',
                typeAttributes: {
                    rowActions: [
                        { label: 'Process Payment', name: 'process_payment' },
                        { label: 'View Details', name: 'view_details' }
                    ],
                    menuAlignment: 'right'
                }
            }
        ];
    }

    get hasRecords() {
        return this.paymentRecords && this.paymentRecords.length > 0;
    }

    get overdueRecords() {
        return this.paymentRecords.filter(record => record.status === 'Overdue');
    }

    get hasOverdueRecords() {
        return this.overdueRecords.length > 0;
    }

    get totalOutstanding() {
        return this.paymentRecords.reduce((total, record) => total + (record.balance || 0), 0);
    }

    get cannotGoBack() {
        return this.filters.pageNumber <= 0;
    }

    get cannotGoForward() {
        return !this.pagination.hasMore;
    }

    get currentPageDisplay() {
        return this.filters.pageNumber + 1;
    }

    get recordRangeDisplay() {
        const startRecord = (this.filters.pageNumber * this.filters.pageSize) + 1;
        const endRecord = Math.min(startRecord + this.paymentRecords.length - 1, this.pagination.totalCount);
        return `${startRecord}-${endRecord} of ${this.pagination.totalCount}`;
    }
}
