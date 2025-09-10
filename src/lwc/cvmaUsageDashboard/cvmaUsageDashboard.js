/**
 * @description CVMA Usage Tracking Dashboard - Visual analytics for development progress and Claude Code usage
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUsageMetrics from '@salesforce/apex/CVMAUsageTrackingController.getUsageMetrics';
import getClaudeCodeUsage from '@salesforce/apex/CVMAUsageTrackingController.getClaudeCodeUsage';
import exportUsageMetrics from '@salesforce/apex/CVMAUsageTrackingController.exportUsageMetrics';

export default class CvmaUsageDashboard extends LightningElement {
    @track developmentMetrics = {};
    @track claudeCodeUsage = {};
    @track loading = false;
    @track error = null;
    @track activeTab = 'overview';

    // Chart data for visualization
    @track chartData = null;
    @track epicProgressData = null;

    @wire(getUsageMetrics)
    wiredMetrics({ error, data }) {
        if (data) {
            this.developmentMetrics = data;
            this.error = null;
            this.prepareChartData();
        } else if (error) {
            this.error = error.body?.message || 'Error loading usage metrics';
            this.developmentMetrics = {};
        }
    }

    @wire(getClaudeCodeUsage)
    wiredClaudeUsage({ error, data }) {
        if (data) {
            this.claudeCodeUsage = data;
            this.error = null;
        } else if (error) {
            this.error = error.body?.message || 'Error loading Claude Code usage';
            this.claudeCodeUsage = {};
        }
    }

    // Tab handling
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    get isOverviewActive() {
        return this.activeTab === 'overview';
    }

    get isEpicsActive() {
        return this.activeTab === 'epics';
    }

    get isSessionsActive() {
        return this.activeTab === 'sessions';
    }

    get isClaudeActive() {
        return this.activeTab === 'claude';
    }

    // Data preparation for charts
    prepareChartData() {
        if (!this.developmentMetrics.epicProgress) return;

        // Prepare epic progress chart data
        this.epicProgressData = this.developmentMetrics.epicProgress.map(epic => ({
            label: epic.epicName.replace('Epic #', '').replace(': ', '\n'),
            value: epic.completionPercentage,
            codeReduction: epic.codeReduction,
            status: epic.status
        }));

        // Prepare overall metrics chart
        this.chartData = [
            { label: 'User Stories Completed', value: this.developmentMetrics.completedUserStories, total: this.developmentMetrics.totalUserStories },
            { label: 'Code Reduction %', value: this.developmentMetrics.codeReductionPercentage, total: 100 },
            { label: 'Components Created', value: this.developmentMetrics.componentsCreated, total: this.developmentMetrics.componentsCreated },
            { label: 'Test Classes', value: this.developmentMetrics.testClassesCreated, total: this.developmentMetrics.testClassesCreated }
        ];
    }

    // Utility getters for UI display
    get completionPercentage() {
        if (!this.developmentMetrics.totalUserStories) return 0;
        return Math.round((this.developmentMetrics.completedUserStories / this.developmentMetrics.totalUserStories) * 100);
    }

    get formattedLinesOfCode() {
        if (!this.developmentMetrics.linesOfCodeGenerated) return '0';
        return this.developmentMetrics.linesOfCodeGenerated.toLocaleString();
    }

    get progressBarClass() {
        const percentage = this.completionPercentage;
        if (percentage >= 75) return 'slds-progress-bar__value_success';
        if (percentage >= 50) return 'slds-progress-bar__value_warning';
        return 'slds-progress-bar__value';
    }

    // Epic status styling
    getEpicStatusClass(status) {
        switch (status) {
            case 'Completed':
                return 'slds-badge slds-theme_success';
            case 'In Progress':
                return 'slds-badge slds-theme_warning';
            default:
                return 'slds-badge slds-theme_default';
        }
    }

    // Session status styling
    getSessionStatusClass(status) {
        switch (status) {
            case 'Completed':
                return 'slds-badge slds-theme_success';
            case 'Planning Complete':
                return 'slds-badge slds-theme_info';
            default:
                return 'slds-badge slds-theme_default';
        }
    }

    // Export functionality
    async handleExport() {
        this.loading = true;
        try {
            const csvData = await exportUsageMetrics();
            const blob = new Blob([csvData], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `CVMA_Usage_Metrics_${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Usage metrics exported successfully',
                variant: 'success'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Export Error',
                message: error.body?.message || 'Failed to export usage metrics',
                variant: 'error'
            }));
        } finally {
            this.loading = false;
        }
    }

    // Refresh data
    async handleRefresh() {
        this.loading = true;
        try {
            // Force refresh of wired data
            eval("$A.get('e.force:refreshView').fire();");

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Usage data refreshed successfully',
                variant: 'success'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Refresh Error',
                message: 'Failed to refresh usage data',
                variant: 'error'
            }));
        } finally {
            this.loading = false;
        }
    }

    // Calculate development velocity
    get developmentVelocity() {
        if (!this.claudeCodeUsage.developmentVelocityIncrease) return '0%';
        return `${this.claudeCodeUsage.developmentVelocityIncrease}%`;
    }

    // Calculate quality score
    get qualityScore() {
        if (!this.claudeCodeUsage.qualityImprovementScore) return '0%';
        return `${this.claudeCodeUsage.qualityImprovementScore}%`;
    }
}
