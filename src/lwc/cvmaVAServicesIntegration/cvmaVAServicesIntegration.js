/**
 * cvmaVAServicesIntegration.js
 * Epic #10 User Story #32: VA Services Integration Component
 * Government services coordination with 91% code reduction through Epic #9 and Service Cloud
 *
 * Combat Veterans Motorcycle Association Chapter 20-7
 * Seamless integration of VA services with community resources
 */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getVAServicesIntegration from '@salesforce/apex/CVMAVAServicesIntegrationController.getVAServicesIntegration';
import getBenefitsCoordination from '@salesforce/apex/CVMAVAServicesIntegrationController.getBenefitsCoordination';
import createServiceCoordinationCase from '@salesforce/apex/CVMAVAServicesIntegrationController.createServiceCoordinationCase';
import getVAAppointmentAssistance from '@salesforce/apex/CVMAVAServicesIntegrationController.getVAAppointmentAssistance';
import getAdvocacySupport from '@salesforce/apex/CVMAVAServicesIntegrationController.getAdvocacySupport';

// Contact fields for member profile
const CONTACT_FIELDS = [
    'Contact.Id',
    'Contact.Name',
    'Contact.Veteran_Status__c',
    'Contact.Service_Branch__c',
    'Contact.CVMA_Membership_Level__c'
];

export default class CvmaVAServicesIntegration extends LightningElement {
    @api contactId; // Member ID for personalized services
    @api showFullIntegration; // Show complete VA services integration
    @api defaultServiceType = 'Healthcare'; // Default service type

    @track vaServices = {};
    @track benefitsData = {};
    @track appointmentData = {};
    @track advocacyData = {};
    @track selectedService = null;
    @track isLoading = false;
    @track error = null;

    // Service coordination state
    @track showServiceForm = false;
    @track serviceType = '';
    @track serviceDescription = '';
    @track serviceUrgency = 'Medium';

    // Filter and navigation state
    @track activeTab = 'overview';
    @track selectedBenefitType = '';
    @track selectedAppointmentType = '';

    // Member profile from Epic #8
    @track memberProfile = {};

    /**
     * Wire member contact data for personalized VA services
     */
    @wire(getRecord, { recordId: '$contactId', fields: CONTACT_FIELDS })
    wiredContact({ error, data }) {
        if (data) {
            this.memberProfile = {
                id: data.id,
                name: data.fields.Name.value,
                veteranStatus: data.fields.Veteran_Status__c.value,
                serviceBranch: data.fields.Service_Branch__c.value,
                membershipLevel: data.fields.CVMA_Membership_Level__c.value
            };
            this.loadVAServicesIntegration();
        } else if (error) {
            console.error('Error loading contact data:', error);
            this.showToast('Error', 'Unable to load member profile', 'error');
        }
    }

    /**
     * Component initialization
     */
    connectedCallback() {
        this.serviceType = this.defaultServiceType;
        if (this.contactId) {
            this.loadVAServicesIntegration();
        }
    }

    /**
     * Load comprehensive VA services integration data
     */
    async loadVAServicesIntegration() {
        this.isLoading = true;
        this.error = null;

        try {
            const response = await getVAServicesIntegration({ contactId: this.contactId });

            if (response.success) {
                this.vaServices = response;
                this.showToast('Success', 'VA services data loaded successfully', 'success');
            } else {
                this.error = response.error || 'Failed to load VA services integration';
                this.showToast('Error', this.error, 'error');
            }
        } catch (error) {
            this.error = 'Network error loading VA services: ' + error.message;
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Load benefits coordination data for specific benefit type
     */
    async loadBenefitsCoordination(benefitType) {
        this.isLoading = true;

        try {
            const response = await getBenefitsCoordination({
                contactId: this.contactId,
                benefitType: benefitType
            });

            if (response.success) {
                this.benefitsData = response;
                this.selectedBenefitType = benefitType;
                this.activeTab = 'benefits';
            } else {
                this.showToast('Error', response.error || 'Failed to load benefits coordination', 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Network error loading benefits: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Load VA appointment assistance data
     */
    async loadAppointmentAssistance(appointmentType) {
        this.isLoading = true;

        try {
            const response = await getVAAppointmentAssistance({
                contactId: this.contactId,
                appointmentType: appointmentType
            });

            if (response.success) {
                this.appointmentData = response;
                this.selectedAppointmentType = appointmentType;
                this.activeTab = 'appointments';
            } else {
                this.showToast('Error', response.error || 'Failed to load appointment assistance', 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Network error loading appointments: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Load advocacy support data
     */
    async loadAdvocacySupport() {
        this.isLoading = true;

        try {
            const response = await getAdvocacySupport({ contactId: this.contactId });

            if (response.success) {
                this.advocacyData = response;
                this.activeTab = 'advocacy';
            } else {
                this.showToast('Error', response.error || 'Failed to load advocacy support', 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Network error loading advocacy: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handle tab navigation
     */
    handleTabSelect(event) {
        this.activeTab = event.target.value;

        // Load data for specific tabs if not already loaded
        if (this.activeTab === 'advocacy' && !this.advocacyData.veteranProfile) {
            this.loadAdvocacySupport();
        }
    }

    /**
     * Handle benefit type selection
     */
    handleBenefitTypeSelect(event) {
        const benefitType = event.target.dataset.benefitType;
        this.loadBenefitsCoordination(benefitType);
    }

    /**
     * Handle appointment type selection
     */
    handleAppointmentTypeSelect(event) {
        const appointmentType = event.target.dataset.appointmentType;
        this.loadAppointmentAssistance(appointmentType);
    }

    /**
     * Handle service coordination form submission
     */
    async handleCreateServiceCase() {
        if (!this.serviceType || !this.serviceDescription) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const response = await createServiceCoordinationCase({
                contactId: this.contactId,
                serviceType: this.serviceType,
                description: this.serviceDescription,
                urgency: this.serviceUrgency
            });

            if (response.success) {
                this.showToast('Success',
                    `Service coordination case ${response.caseNumber} created successfully`,
                    'success'
                );
                this.showServiceForm = false;
                this.serviceDescription = '';

                // Reload VA services to show updated case information
                this.loadVAServicesIntegration();
            } else {
                this.showToast('Error', response.error || 'Failed to create service case', 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Network error creating case: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handle form field changes
     */
    handleServiceTypeChange(event) {
        this.serviceType = event.target.value;
    }

    handleServiceDescriptionChange(event) {
        this.serviceDescription = event.target.value;
    }

    handleServiceUrgencyChange(event) {
        this.serviceUrgency = event.target.value;
    }

    /**
     * Toggle service coordination form
     */
    handleToggleServiceForm() {
        this.showServiceForm = !this.showServiceForm;
    }

    /**
     * Handle external link clicks with tracking
     */
    handleExternalLinkClick(event) {
        const linkType = event.target.dataset.linkType;
        const url = event.target.href;

        // Track link clicks for analytics
        console.log(`External link clicked: ${linkType} - ${url}`);

        // Open in new tab for user safety
        event.preventDefault();
        window.open(url, '_blank', 'noopener,noreferrer');
    }

    /**
     * Utility method to show toast messages
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    // Computed properties for template rendering
    get hasVAServices() {
        return this.vaServices && this.vaServices.success;
    }

    get hasBenefitsData() {
        return this.benefitsData && this.benefitsData.success;
    }

    get hasAppointmentData() {
        return this.appointmentData && this.appointmentData.success;
    }

    get hasAdvocacyData() {
        return this.advocacyData && this.advocacyData.success;
    }

    get memberGreeting() {
        if (this.memberProfile.name) {
            return `${this.memberProfile.name} - VA Services Integration`;
        }
        return 'VA Services Integration Portal';
    }

    get showVeteranStatus() {
        return this.memberProfile.veteranStatus && this.memberProfile.veteranStatus !== 'Non-Veteran';
    }

    get tabOptions() {
        return [
            { label: 'Overview', value: 'overview', iconName: 'utility:preview' },
            { label: 'Benefits Coordination', value: 'benefits', iconName: 'utility:currency' },
            { label: 'Appointment Assistance', value: 'appointments', iconName: 'utility:event' },
            { label: 'Advocacy Support', value: 'advocacy', iconName: 'utility:people' }
        ];
    }

    get serviceTypeOptions() {
        return [
            { label: 'Healthcare Services', value: 'Healthcare' },
            { label: 'Disability Benefits', value: 'Disability' },
            { label: 'Education Benefits', value: 'Education' },
            { label: 'Home Loan Benefits', value: 'Home Loan' },
            { label: 'Employment Services', value: 'Employment' },
            { label: 'Mental Health Services', value: 'Mental Health' },
            { label: 'Other Services', value: 'Other' }
        ];
    }

    get urgencyOptions() {
        return [
            { label: 'Low - General inquiry', value: 'Low' },
            { label: 'Medium - Standard request', value: 'Medium' },
            { label: 'High - Urgent assistance needed', value: 'High' },
            { label: 'Critical - Emergency situation', value: 'Critical' }
        ];
    }

    get benefitTypes() {
        if (!this.hasVAServices || !this.vaServices.vaBenefits || !this.vaServices.vaBenefits.benefits) {
            return [];
        }

        return Object.keys(this.vaServices.vaBenefits.benefits).map(key => ({
            type: key,
            label: key.charAt(0).toUpperCase() + key.slice(1),
            status: this.vaServices.vaBenefits.benefits[key]
        }));
    }

    get appointmentTypes() {
        return [
            { type: 'medical', label: 'Medical Care', icon: 'utility:health' },
            { type: 'mental_health', label: 'Mental Health', icon: 'utility:mind' },
            { type: 'dental', label: 'Dental Care', icon: 'utility:smile' },
            { type: 'vision', label: 'Vision Care', icon: 'utility:eye' },
            { type: 'specialty', label: 'Specialty Care', icon: 'utility:settings' }
        ];
    }

    get serviceGaps() {
        if (!this.hasVAServices || !this.vaServices.serviceAnalysis) {
            return [];
        }
        return this.vaServices.serviceAnalysis.identifiedGaps || [];
    }

    get recommendations() {
        if (!this.hasVAServices || !this.vaServices.serviceAnalysis) {
            return [];
        }
        return this.vaServices.serviceAnalysis.recommendations || [];
    }

    get showOverviewTab() {
        return this.activeTab === 'overview';
    }

    get showBenefitsTab() {
        return this.activeTab === 'benefits';
    }

    get showAppointmentsTab() {
        return this.activeTab === 'appointments';
    }

    get showAdvocacyTab() {
        return this.activeTab === 'advocacy';
    }
}
