import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getVAForms from '@salesforce/apex/CVMARealVAFormsController.getVAForms';
import getNearbyVAFacilities from '@salesforce/apex/CVMARealVAFacilitiesController.getNearbyFacilities';
import validateAddress from '@salesforce/apex/CVMAAddressValidationController.validateAddress';
import getCurrentUser from '@salesforce/apex/CVMAMemberProfileController.getCurrentUser';

export default class VaServicesIntegration extends LightningElement {
    @track activeTab = 'forms';
    @track isLoading = false;
    @track memberProfile = {};

    // VA Forms Data
    @track vaForms = [];
    @track filteredForms = [];
    @track formSearchTerm = '';
    @track selectedFormCategory = 'All';
    @track popularForms = [];

    // VA Facilities Data
    @track vaFacilities = [];
    @track memberLocation = {};
    @track facilitySearchRadius = 25;
    @track selectedFacilityType = 'All';

    // Address Validation Data
    @track addressToValidate = {
        street: '',
        city: '',
        state: '',
        zipCode: ''
    };
    @track validationResults = null;
    @track showValidationResults = false;

    formCategoryOptions = [
        { label: 'All Forms', value: 'All' },
        { label: 'Disability Compensation', value: 'Disability' },
        { label: 'Education Benefits', value: 'Education' },
        { label: 'Healthcare', value: 'Healthcare' },
        { label: 'Home Loans', value: 'Housing' },
        { label: 'Vocational Rehabilitation', value: 'VocRehab' },
        { label: 'Life Insurance', value: 'Insurance' },
        { label: 'Burial & Cemetery', value: 'Burial' }
    ];

    facilityTypeOptions = [
        { label: 'All Facilities', value: 'All' },
        { label: 'VA Medical Centers', value: 'va_medical_center' },
        { label: 'Community Clinics', value: 'va_clinic' },
        { label: 'Regional Offices', value: 'va_benefits_facility' },
        { label: 'Vet Centers', value: 'vet_center' },
        { label: 'National Cemeteries', value: 'va_cemetery' }
    ];

    radiusOptions = [
        { label: '10 miles', value: 10 },
        { label: '25 miles', value: 25 },
        { label: '50 miles', value: 50 },
        { label: '100 miles', value: 100 }
    ];

    @wire(getCurrentUser)
    wiredUser({ error, data }) {
        if (data) {
            this.memberProfile = data;
            if (data.mailingAddress) {
                this.memberLocation = {
                    lat: data.mailingAddress.latitude,
                    lng: data.mailingAddress.longitude,
                    city: data.mailingAddress.city,
                    state: data.mailingAddress.state
                };
                this.loadNearbyFacilities();
            }
        } else if (error) {
            console.error('Error loading member profile:', error);
        }
    }

    connectedCallback() {
        this.loadVAForms();
        this.loadPopularForms();
    }

    // Tab Navigation
    handleTabChange(event) {
        this.activeTab = event.target.value;

        if (this.activeTab === 'facilities' && this.vaFacilities.length === 0) {
            this.loadNearbyFacilities();
        }
    }

    // VA Forms Methods
    loadVAForms() {
        this.isLoading = true;

        getVAForms({ category: this.selectedFormCategory, searchTerm: this.formSearchTerm })
            .then(result => {
                this.vaForms = result.map(form => ({
                    ...form,
                    formUrl: `https://www.va.gov/find-forms/about-form-${form.formNumber.toLowerCase()}/`,
                    downloadUrl: form.url,
                    isPopular: this.isPopularForm(form.formNumber),
                    categoryClass: this.getCategoryClass(form.formCategory)
                }));
                this.filterForms();
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load VA forms: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadPopularForms() {
        // Most commonly used forms by veterans
        this.popularForms = [
            { formNumber: '21-526EZ', title: 'Disability Compensation', category: 'Disability' },
            { formNumber: '22-1990', title: 'Education Benefits', category: 'Education' },
            { formNumber: '10-10EZ', title: 'Healthcare Enrollment', category: 'Healthcare' },
            { formNumber: '26-1880', title: 'Home Loan Certificate', category: 'Housing' },
            { formNumber: '21-8940', title: 'Veteran Educational Assistance', category: 'Education' }
        ];
    }

    isPopularForm(formNumber) {
        return this.popularForms.some(form => form.formNumber === formNumber);
    }

    getCategoryClass(category) {
        const categoryClasses = {
            'Disability': 'category-disability',
            'Education': 'category-education',
            'Healthcare': 'category-healthcare',
            'Housing': 'category-housing',
            'Insurance': 'category-insurance',
            'Burial': 'category-burial'
        };
        return categoryClasses[category] || 'category-default';
    }

    handleFormSearch(event) {
        this.formSearchTerm = event.target.value;
        this.filterForms();
    }

    handleFormCategoryChange(event) {
        this.selectedFormCategory = event.detail.value;
        this.filterForms();
    }

    filterForms() {
        let filtered = [...this.vaForms];

        if (this.formSearchTerm) {
            const searchLower = this.formSearchTerm.toLowerCase();
            filtered = filtered.filter(form =>
                form.title.toLowerCase().includes(searchLower) ||
                form.formNumber.toLowerCase().includes(searchLower) ||
                form.description.toLowerCase().includes(searchLower)
            );
        }

        if (this.selectedFormCategory && this.selectedFormCategory !== 'All') {
            filtered = filtered.filter(form => form.formCategory === this.selectedFormCategory);
        }

        // Sort by popularity and form number
        filtered.sort((a, b) => {
            if (a.isPopular && !b.isPopular) return -1;
            if (!a.isPopular && b.isPopular) return 1;
            return a.formNumber.localeCompare(b.formNumber);
        });

        this.filteredForms = filtered;
    }

    handleFormAction(event) {
        const action = event.currentTarget.dataset.action;
        const formNumber = event.currentTarget.dataset.form;
        const form = this.filteredForms.find(f => f.formNumber === formNumber);

        if (action === 'view') {
            window.open(form.formUrl, '_blank');
        } else if (action === 'download') {
            window.open(form.downloadUrl, '_blank');
        } else if (action === 'help') {
            this.showFormHelp(form);
        }
    }

    showFormHelp(form) {
        // Could open a modal with form completion guidance
        this.showToast('Form Help', `Need help with ${form.title}? Contact CVMA member services for assistance.`, 'info');
    }

    // VA Facilities Methods
    loadNearbyFacilities() {
        if (!this.memberLocation.lat || !this.memberLocation.lng) {
            this.showToast('Location Required', 'Please update your profile with a valid address to find nearby facilities.', 'warning');
            return;
        }

        this.isLoading = true;

        getNearbyVAFacilities({
            latitude: this.memberLocation.lat,
            longitude: this.memberLocation.lng,
            radiusMiles: this.facilitySearchRadius,
            facilityType: this.selectedFacilityType
        })
            .then(result => {
                this.vaFacilities = result.map(facility => ({
                    ...facility,
                    distanceText: `${Math.round(facility.distance * 10) / 10} miles`,
                    phoneLink: `tel:${facility.phone}`,
                    directionsUrl: `https://maps.google.com/maps?daddr=${facility.address.street},${facility.address.city},${facility.address.state}`,
                    facilityTypeLabel: this.getFacilityTypeLabel(facility.facilityType),
                    statusClass: this.getFacilityStatusClass(facility.operatingStatus)
                }));
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load VA facilities: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    getFacilityTypeLabel(type) {
        const typeLabels = {
            'va_medical_center': 'Medical Center',
            'va_clinic': 'Community Clinic',
            'va_benefits_facility': 'Regional Office',
            'vet_center': 'Vet Center',
            'va_cemetery': 'National Cemetery'
        };
        return typeLabels[type] || type;
    }

    getFacilityStatusClass(status) {
        const statusClasses = {
            'NORMAL': 'status-normal',
            'LIMITED': 'status-limited',
            'CLOSED': 'status-closed'
        };
        return statusClasses[status] || 'status-unknown';
    }

    handleFacilityRadiusChange(event) {
        this.facilitySearchRadius = parseInt(event.detail.value);
        this.loadNearbyFacilities();
    }

    handleFacilityTypeChange(event) {
        this.selectedFacilityType = event.detail.value;
        this.loadNearbyFacilities();
    }

    handleFacilityAction(event) {
        const action = event.currentTarget.dataset.action;
        const facilityId = event.currentTarget.dataset.facility;
        const facility = this.vaFacilities.find(f => f.id === facilityId);

        if (action === 'directions') {
            window.open(facility.directionsUrl, '_blank');
        } else if (action === 'call') {
            window.open(facility.phoneLink);
        } else if (action === 'website') {
            window.open(facility.website, '_blank');
        } else if (action === 'schedule') {
            this.handleScheduleAppointment(facility);
        }
    }

    handleScheduleAppointment(facility) {
        // This would integrate with VA appointment scheduling system
        this.showToast('Appointment Scheduling',
            `To schedule an appointment at ${facility.name}, please call ${facility.phone} or visit MyHealtheVet.va.gov`,
            'info');
    }

    // Address Validation Methods
    handleAddressChange(event) {
        const field = event.target.dataset.field;
        this.addressToValidate[field] = event.target.value;
    }

    handleValidateAddress() {
        if (!this.addressToValidate.street || !this.addressToValidate.city || !this.addressToValidate.state) {
            this.showToast('Incomplete Address', 'Please provide street, city, and state for validation.', 'warning');
            return;
        }

        this.isLoading = true;

        validateAddress({ address: this.addressToValidate })
            .then(result => {
                this.validationResults = result;
                this.showValidationResults = true;
            })
            .catch(error => {
                this.showToast('Validation Error', 'Failed to validate address: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleUseValidatedAddress() {
        if (this.validationResults && this.validationResults.validatedAddress) {
            const validated = this.validationResults.validatedAddress;
            this.addressToValidate = {
                street: validated.street,
                city: validated.city,
                state: validated.state,
                zipCode: validated.zipCode
            };
            this.showValidationResults = false;
            this.showToast('Success', 'Address updated with validated information.', 'success');
        }
    }

    handleUpdateProfile() {
        // This would update the member's profile with the validated address
        this.showToast('Profile Update', 'Address validation complete. Update your member profile to save changes.', 'info');
    }

    // Utility Methods
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get hasLocationData() {
        return this.memberLocation.lat && this.memberLocation.lng;
    }

    get formsTabClass() {
        return this.activeTab === 'forms' ? 'slds-is-active' : '';
    }

    get facilitiesTabClass() {
        return this.activeTab === 'facilities' ? 'slds-is-active' : '';
    }

    get addressTabClass() {
        return this.activeTab === 'address' ? 'slds-is-active' : '';
    }
}
