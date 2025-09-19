import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import authenticateMember from '@salesforce/apex/CVMAMemberAuthenticationController.authenticateMember';
import getMemberEpic8Access from '@salesforce/apex/CVMAMemberAuthenticationController.getMemberEpic8Access';
import getMemberAnalyticsDashboard from '@salesforce/apex/CVMAMemberAuthenticationController.getMemberAnalyticsDashboard';
import getMemberCrossChapterAccess from '@salesforce/apex/CVMAMemberAuthenticationController.getMemberCrossChapterAccess';
import getEpic8Phase3Dashboard from '@salesforce/apex/CVMAEpic8Phase3Controller.getEpic8Phase3Dashboard';
import getEinsteinPredictiveAnalytics from '@salesforce/apex/CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics';

export default class CvmaMemberPortal extends LightningElement {
    @track isAuthenticated = false;
    @track isLoading = false;
    @track membershipId = '';
    @track lastName = '';
    @track email = '';
    @track errorMessage = '';

    @track memberData = {};
    @track accessLevel = '';
    @track availableFeatures = {};
    @track dashboardData = {};
    @track crossChapterData = {};
    @track epic8Data = {};
    @track analyticsData = {};

    @track activeTab = 'dashboard';

    // Authentication form handling
    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
        this.errorMessage = '';
    }

    async handleAuthentication() {
        if (!this.membershipId || !this.lastName) {
            this.errorMessage = 'Membership ID and Last Name are required';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        try {
            const authResult = await authenticateMember({
                membershipId: this.membershipId,
                lastName: this.lastName,
                email: this.email || null
            });

            if (authResult.success) {
                this.memberData = authResult;
                this.accessLevel = authResult.accessLevel;
                this.availableFeatures = authResult.epic8Features;
                this.isAuthenticated = true;

                // Load member-specific data
                await this.loadMemberDashboard();

                this.showToast('Success', 'Welcome to Epic #8, ' + authResult.memberName + '!', 'success');
            }
        } catch (error) {
            this.errorMessage = error.body ? error.body.message : 'Authentication failed. Please check your credentials.';
            this.showToast('Authentication Failed', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadMemberDashboard() {
        try {
            // Load member analytics dashboard
            this.dashboardData = await getMemberAnalyticsDashboard({
                memberId: this.memberData.memberId
            });

            // Load cross-chapter access for qualified members
            if (this.accessLevel === 'Premium') {
                this.crossChapterData = await getMemberCrossChapterAccess({
                    memberId: this.memberData.memberId
                });
            }

            // Load Epic #8 Phase 3 data
            this.epic8Data = await getEpic8Phase3Dashboard();

            // Load Einstein Analytics for Premium members
            if (this.accessLevel === 'Premium') {
                this.analyticsData = await getEinsteinPredictiveAnalytics();
            }

        } catch (error) {
            console.error('Error loading dashboard data:', error);
            this.showToast('Warning', 'Some dashboard features may be limited', 'warning');
        }
    }

    // Tab navigation
    handleTabClick(event) {
        this.activeTab = event.target.dataset.tab;
    }

    // Feature access checks
    get hasAnalyticsAccess() {
        return this.availableFeatures.analytics && this.availableFeatures.analytics.length > 0;
    }

    get hasExternalIntegrationAccess() {
        return this.availableFeatures.external_integration && this.availableFeatures.external_integration.length > 0;
    }

    get hasCrossChapterAccess() {
        return this.accessLevel === 'Premium' && this.crossChapterData.canViewOtherChapters;
    }

    get hasLeadershipTools() {
        return this.accessLevel === 'Premium' &&
               this.availableFeatures.external_integration &&
               this.availableFeatures.external_integration.includes('Leadership Tools');
    }

    // UI state getters
    get isDashboardActive() {
        return this.activeTab === 'dashboard';
    }

    get isAnalyticsActive() {
        return this.activeTab === 'analytics';
    }

    get isVaBenefitsActive() {
        return this.activeTab === 'benefits';
    }

    get isCrossChapterActive() {
        return this.activeTab === 'crosschapter';
    }

    get isCrisisActive() {
        return this.activeTab === 'crisis';
    }

    get accessLevelClass() {
        return `access-level access-level-${this.accessLevel.toLowerCase()}`;
    }

    get membershipStatus() {
        return this.memberData.membershipStatus === 'expired' ? 'Expired' : 'Active';
    }

    get membershipStatusClass() {
        return this.memberData.membershipStatus === 'expired' ? 'status-expired' : 'status-active';
    }

    // Tab CSS class getters
    get dashboardTabClass() {
        return this.activeTab === 'dashboard' ? 'tab active' : 'tab';
    }

    get analyticsTabClass() {
        return this.activeTab === 'analytics' ? 'tab active' : 'tab';
    }

    get benefitsTabClass() {
        return this.activeTab === 'benefits' ? 'tab active' : 'tab';
    }

    get crossChapterTabClass() {
        return this.activeTab === 'crosschapter' ? 'tab active' : 'tab';
    }

    get crisisTabClass() {
        return this.activeTab === 'crisis' ? 'tab active' : 'tab';
    }

    // Utility methods
    handleLogout() {
        this.isAuthenticated = false;
        this.memberData = {};
        this.accessLevel = '';
        this.availableFeatures = {};
        this.dashboardData = {};
        this.membershipId = '';
        this.lastName = '';
        this.email = '';
        this.activeTab = 'dashboard';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        }));
    }

    // Emergency crisis support
    handleCrisisSupport() {
        // Open crisis support in new window
        window.open('tel:988', '_blank');
        this.showToast('Crisis Support', 'Connecting to Crisis Lifeline: 988', 'info');
    }

    // VA Benefits helper
    handleVaBenefitsLink() {
        window.open('https://va.gov/disability/', '_blank');
    }

    // Cross-chapter event registration
    handleEventRegistration(event) {
        const eventId = event.target.dataset.eventId;
        this.showToast('Event Registration', 'Event registration functionality will be available soon', 'info');
    }
}
