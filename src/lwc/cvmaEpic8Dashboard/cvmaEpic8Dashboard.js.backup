import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEpic8Phase3Dashboard from '@salesforce/apex/CVMAEpic8Phase3Controller.getEpic8Phase3Dashboard';
import getVeteranServicesIntegration from '@salesforce/apex/CVMAEpic8Phase3Controller.getVeteranServicesIntegration';
import getCrossChapterAnalytics from '@salesforce/apex/CVMAEpic8Phase3Controller.getCrossChapterAnalytics';
import getAdvancedAutomationEngine from '@salesforce/apex/CVMAEpic8Phase3Controller.getAdvancedAutomationEngine';
import getEinsteinPredictiveAnalytics from '@salesforce/apex/CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics';

export default class CvmaEpic8Dashboard extends LightningElement {
    @api memberAccessLevel = 'Basic'; // Premium, Basic, Limited
    @api memberId;

    @track isLoading = true;
    @track dashboardData = {};
    @track veteranServices = {};
    @track crossChapterData = {};
    @track automationData = {};
    @track analyticsData = {};
    @track activeView = 'overview';

    @track error = null;

    connectedCallback() {
        this.loadDashboardData();
    }

    async loadDashboardData() {
        this.isLoading = true;
        this.error = null;

        try {
            // Load Epic #8 Phase 3 main dashboard
            this.dashboardData = await getEpic8Phase3Dashboard();

            // Load veteran services data (available to all levels)
            this.veteranServices = await getVeteranServicesIntegration();

            // Load additional data based on access level
            if (this.memberAccessLevel === 'Premium') {
                await this.loadPremiumFeatures();
            }

        } catch (error) {
            this.error = error;
            console.error('Error loading Epic #8 dashboard:', error);
            this.showToast('Error', 'Failed to load dashboard data', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadPremiumFeatures() {
        try {
            // Premium members get cross-chapter analytics
            this.crossChapterData = await getCrossChapterAnalytics();

            // Premium members get automation engine data
            this.automationData = await getAdvancedAutomationEngine();

            // Premium members get Einstein Analytics
            this.analyticsData = await getEinsteinPredictiveAnalytics();

        } catch (error) {
            console.error('Error loading premium features:', error);
            // Don't fail the entire dashboard for premium feature errors
        }
    }

    // View navigation
    handleViewChange(event) {
        this.activeView = event.target.dataset.view;
    }

    // Getters for view states
    get isOverviewActive() {
        return this.activeView === 'overview';
    }

    get isVeteranServicesActive() {
        return this.activeView === 'veteranservices';
    }

    get isCrossChapterActive() {
        return this.activeView === 'crosschapter';
    }

    get isAutomationActive() {
        return this.activeView === 'automation';
    }

    get isAnalyticsActive() {
        return this.activeView === 'analytics';
    }

    // Access level checks
    get hasPremiumAccess() {
        return this.memberAccessLevel === 'Premium';
    }

    get hasBasicAccess() {
        return this.memberAccessLevel === 'Basic' || this.memberAccessLevel === 'Premium';
    }

    // Data getters with null checks
    get phase3Status() {
        return this.dashboardData?.phase3_status || 'Unknown';
    }

    get successIndicators() {
        return this.dashboardData?.success_indicators || [];
    }

    get deploymentMetrics() {
        return this.dashboardData?.deployment_metrics || {};
    }

    get veteranServicesStatus() {
        return this.veteranServices?.va_benefits_api || 'Unknown';
    }

    get servicesProvidedToday() {
        return this.veteranServices?.services_provided_today || 0;
    }

    get integrationHealth() {
        return this.veteranServices?.integration_health || 0;
    }

    get chaptersConnected() {
        return this.crossChapterData?.national_chapters_connected || 0;
    }

    get collaborationScore() {
        return this.crossChapterData?.collaboration_score || 0;
    }

    get activeWorkflows() {
        return this.automationData?.ai_workflows_active || 0;
    }

    get automationEfficiency() {
        return this.automationData?.automation_efficiency || 0;
    }

    get automationROI() {
        return this.automationData?.automation_roi || 0;
    }

    get predictiveAccuracy() {
        return this.analyticsData?.predictive_accuracy || 0;
    }

    get memberRetentionForecast() {
        return this.analyticsData?.member_retention_forecast || 0;
    }

    get eventSuccessPrediction() {
        return this.analyticsData?.event_success_prediction || 0;
    }

    // Status badge classes
    get phase3StatusClass() {
        const status = this.phase3Status.toLowerCase();
        return `status-badge status-${status}`;
    }

    get integrationHealthClass() {
        const health = this.integrationHealth;
        if (health >= 95) return 'health-excellent';
        if (health >= 85) return 'health-good';
        if (health >= 70) return 'health-fair';
        return 'health-poor';
    }

    // Utility methods
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        }));
    }

    handleRefresh() {
        this.loadDashboardData();
        this.showToast('Refresh', 'Dashboard data refreshed', 'success');
    }

    // Format numbers for display
    formatNumber(value) {
        if (typeof value !== 'number') return value;
        return value.toLocaleString();
    }

    formatPercentage(value) {
        if (typeof value !== 'number') return value;
        return `${value.toFixed(1)}%`;
    }

    formatCurrency(value) {
        if (typeof value !== 'number') return value;
        return `$${value.toLocaleString()}`;
    }
}
