import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import generateComplianceReport from '@salesforce/apex/CVMAFinancialComplianceController.generateComplianceReport';
import getComplianceSummary from '@salesforce/apex/CVMAFinancialComplianceController.getComplianceSummary';
import getAuditTrail from '@salesforce/apex/CVMAFinancialComplianceController.getAuditTrail';

export default class CvmaFinancialCompliance extends LightningElement {
    @track complianceData = {};
    @track auditTrail = [];
    @track complianceReport = {};
    @track isLoading = true;
    @track error;
    @track selectedReportType = 'Full Compliance Review';
    @track startDate;
    @track endDate;
    @track showReportModal = false;

    // Compliance summary wire
    @wire(getComplianceSummary)
    wiredComplianceData(result) {
        this.wiredComplianceResult = result;
        const { data, error } = result;
        this.isLoading = true;

        if (data) {
            this.complianceData = data;
            this.isLoading = false;
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading compliance data: ' + (error.body?.message || error.message);
            this.isLoading = false;
        }
    }

    // Audit trail wire
    @wire(getAuditTrail)
    wiredAuditTrail(result) {
        const { data, error } = result;
        if (data) {
            this.auditTrail = data.map(audit => ({
                ...audit,
                formattedTimestamp: new Date(audit.timestamp).toLocaleString(),
                severityClass: this.getSeverityClass(audit.severity),
                actionIcon: this.getActionIcon(audit.actionType)
            }));
        } else if (error) {
            console.error('Audit trail error:', error);
        }
    }

    // Computed properties
    get hasComplianceData() {
        return this.complianceData && Object.keys(this.complianceData).length > 0;
    }

    get hasAuditTrail() {
        return this.auditTrail && this.auditTrail.length > 0;
    }

    get hasRiskIndicators() {
        return this.complianceData.riskIndicators && this.complianceData.riskIndicators.length > 0;
    }

    get hasComplianceIssues() {
        return this.complianceData.complianceIssues && this.complianceData.complianceIssues.length > 0;
    }

    get overallComplianceClass() {
        if (!this.complianceData.overallCompliance) return '';
        const score = parseFloat(this.complianceData.overallCompliance);
        if (score >= 95) return 'slds-text-color_success';
        if (score >= 85) return 'slds-text-color_warning';
        return 'slds-text-color_error';
    }

    get reportTypeOptions() {
        return [
            { label: 'Full Compliance Review', value: 'Full Compliance Review' },
            { label: 'Budget Overrun Analysis', value: 'Budget Overrun Analysis' },
            { label: 'Large Transaction Review', value: 'Large Transaction Review' },
            { label: 'Documentation Gap Report', value: 'Documentation Gap Report' },
            { label: 'Risk Assessment Summary', value: 'Risk Assessment Summary' }
        ];
    }

    // Event handlers
    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredComplianceResult);
    }

    handleReportTypeChange(event) {
        this.selectedReportType = event.detail.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleGenerateReport() {
        if (!this.startDate || !this.endDate) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Information',
                    message: 'Please select start and end dates for the compliance report.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isLoading = true;
        generateComplianceReport({
            reportType: this.selectedReportType,
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(result => {
            this.complianceReport = result;
            this.showReportModal = true;
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Compliance report generated successfully.',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error generating compliance report: ' + (error.body?.message || error.message),
                    variant: 'error'
                })
            );
        });
    }

    handleCloseReportModal() {
        this.showReportModal = false;
    }

    // Utility methods
    getSeverityClass(severity) {
        switch (severity?.toLowerCase()) {
            case 'high':
                return 'slds-text-color_error';
            case 'medium':
                return 'slds-text-color_warning';
            case 'low':
                return 'slds-text-color_success';
            default:
                return '';
        }
    }

    getActionIcon(actionType) {
        switch (actionType?.toLowerCase()) {
            case 'create':
                return 'utility:add';
            case 'update':
                return 'utility:edit';
            case 'delete':
                return 'utility:delete';
            case 'review':
                return 'utility:preview';
            case 'approve':
                return 'utility:success';
            default:
                return 'utility:info';
        }
    }

    getRiskLevelClass(level) {
        switch (level?.toLowerCase()) {
            case 'critical':
                return 'risk-critical';
            case 'high':
                return 'risk-high';
            case 'medium':
                return 'risk-medium';
            case 'low':
                return 'risk-low';
            default:
                return '';
        }
    }

    formatCurrency(value) {
        if (value == null) return '$0.00';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2
        }).format(value);
    }

    formatPercentage(value) {
        if (value == null) return '0%';
        return parseFloat(value).toFixed(1) + '%';
    }
}
