import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitMembershipApplication from '@salesforce/apex/CVMAMembershipApplicationController.submitMembershipApplication';
import checkApplicationStatus from '@salesforce/apex/CVMAMembershipApplicationController.checkApplicationStatus';

export default class CvmaMembershipApplication extends LightningElement {
    @track currentStep = 'personal';
    @track isProcessing = false;
    @track errors = [];
    @track recordId; // For file uploads

    @track application = {
        // Personal Information
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        mailingAddress: '',
        city: '',
        state: '',
        postalCode: '',
        dateOfBirth: '',
        roadName: '',
        
        // Military Service
        serviceStatus: '',
        servicesBranch: '',
        militaryOccupation: '',
        serviceStartDate: '',
        serviceEndDate: '',
        deployments: '',
        awards: '',
        isCombatVeteran: false,
        
        // Emergency Contact
        emergencyContactName: '',
        emergencyContactRelationship: '',
        emergencyContactPhone: '',
        emergencyContactEmail: '',
        membershipLevel: '',
        
        // Documents & Terms
        dd214Uploaded: false,
        termsAccepted: false
    };

    // Step navigation properties
    get isPersonalStep() { return this.currentStep === 'personal'; }
    get isMilitaryStep() { return this.currentStep === 'military'; }
    get isEmergencyStep() { return this.currentStep === 'emergency'; }
    get isDocumentsStep() { return this.currentStep === 'documents'; }
    
    get isFirstStep() { return this.currentStep === 'personal'; }
    get isLastStep() { return this.currentStep === 'documents'; }
    
    get hasErrors() { return this.errors.length > 0; }
    
    get submitDisabled() {
        return !this.application.dd214Uploaded || 
               !this.application.termsAccepted || 
               this.isProcessing;
    }

    // Form options
    stateOptions = [
        { label: 'Alabama', value: 'AL' },
        { label: 'Alaska', value: 'AK' },
        { label: 'Arizona', value: 'AZ' },
        { label: 'Arkansas', value: 'AR' },
        { label: 'California', value: 'CA' },
        { label: 'Colorado', value: 'CO' },
        { label: 'Connecticut', value: 'CT' },
        { label: 'Delaware', value: 'DE' },
        { label: 'Florida', value: 'FL' },
        { label: 'Georgia', value: 'GA' },
        { label: 'Hawaii', value: 'HI' },
        { label: 'Idaho', value: 'ID' },
        { label: 'Illinois', value: 'IL' },
        { label: 'Indiana', value: 'IN' },
        { label: 'Iowa', value: 'IA' },
        { label: 'Kansas', value: 'KS' },
        { label: 'Kentucky', value: 'KY' },
        { label: 'Louisiana', value: 'LA' },
        { label: 'Maine', value: 'ME' },
        { label: 'Maryland', value: 'MD' },
        { label: 'Massachusetts', value: 'MA' },
        { label: 'Michigan', value: 'MI' },
        { label: 'Minnesota', value: 'MN' },
        { label: 'Mississippi', value: 'MS' },
        { label: 'Missouri', value: 'MO' },
        { label: 'Montana', value: 'MT' },
        { label: 'Nebraska', value: 'NE' },
        { label: 'Nevada', value: 'NV' },
        { label: 'New Hampshire', value: 'NH' },
        { label: 'New Jersey', value: 'NJ' },
        { label: 'New Mexico', value: 'NM' },
        { label: 'New York', value: 'NY' },
        { label: 'North Carolina', value: 'NC' },
        { label: 'North Dakota', value: 'ND' },
        { label: 'Ohio', value: 'OH' },
        { label: 'Oklahoma', value: 'OK' },
        { label: 'Oregon', value: 'OR' },
        { label: 'Pennsylvania', value: 'PA' },
        { label: 'Rhode Island', value: 'RI' },
        { label: 'South Carolina', value: 'SC' },
        { label: 'South Dakota', value: 'SD' },
        { label: 'Tennessee', value: 'TN' },
        { label: 'Texas', value: 'TX' },
        { label: 'Utah', value: 'UT' },
        { label: 'Vermont', value: 'VT' },
        { label: 'Virginia', value: 'VA' },
        { label: 'Washington', value: 'WA' },
        { label: 'West Virginia', value: 'WV' },
        { label: 'Wisconsin', value: 'WI' },
        { label: 'Wyoming', value: 'WY' }
    ];

    serviceStatusOptions = [
        { label: 'Active Duty', value: 'Active Duty' },
        { label: 'Veteran', value: 'Veteran' },
        { label: 'National Guard', value: 'National Guard' },
        { label: 'Reserves', value: 'Reserves' }
    ];

    serviceBranchOptions = [
        { label: 'Army', value: 'Army' },
        { label: 'Navy', value: 'Navy' },
        { label: 'Air Force', value: 'Air Force' },
        { label: 'Marines', value: 'Marines' },
        { label: 'Coast Guard', value: 'Coast Guard' },
        { label: 'Space Force', value: 'Space Force' }
    ];

    membershipLevelOptions = [
        { label: 'Full Member', value: 'Full Member' },
        { label: 'Support Member', value: 'Support Member' },
        { label: 'Auxiliary Member', value: 'Auxiliary Member' }
    ];

    connectedCallback() {
        // Generate temporary record ID for file uploads
        this.recordId = 'temp_' + Date.now();
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        
        this.application = {
            ...this.application,
            [field]: value
        };
        
        // Clear any existing errors for this field
        this.clearFieldErrors(field);
    }

    handleCheckboxChange(event) {
        const field = event.target.dataset.field;
        const checked = event.target.checked;
        
        this.application = {
            ...this.application,
            [field]: checked
        };
    }

    handleNext() {
        if (this.validateCurrentStep()) {
            this.moveToNextStep();
        }
    }

    handlePrevious() {
        this.moveToPreviousStep();
    }

    handleDD214Upload(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.application = {
                ...this.application,
                dd214Uploaded: true
            };
            
            this.showToast('Success', 'DD-214 uploaded successfully', 'success');
        }
    }

    async handleSubmit() {
        if (!this.validateFinalSubmission()) {
            return;
        }

        this.isProcessing = true;
        
        try {
            const result = await submitMembershipApplication({ 
                applicationData: JSON.stringify(this.application) 
            });
            
            if (result.success) {
                this.showToast(
                    'Application Submitted', 
                    'Your membership application has been submitted successfully. You will receive a confirmation email shortly.', 
                    'success'
                );
                
                // Reset form or redirect
                this.resetForm();
            } else {
                this.showToast('Submission Error', result.message, 'error');
            }
            
        } catch (error) {
            console.error('Submission error:', error);
            this.showToast(
                'Submission Error', 
                'There was an error submitting your application. Please try again.', 
                'error'
            );
        } finally {
            this.isProcessing = false;
        }
    }

    validateCurrentStep() {
        this.errors = [];
        
        switch (this.currentStep) {
            case 'personal':
                return this.validatePersonalInfo();
            case 'military':
                return this.validateMilitaryInfo();
            case 'emergency':
                return this.validateEmergencyInfo();
            case 'documents':
                return this.validateDocuments();
            default:
                return true;
        }
    }

    validatePersonalInfo() {
        const required = ['firstName', 'lastName', 'email', 'phone', 'mailingAddress', 'city', 'state', 'postalCode', 'dateOfBirth'];
        
        for (let field of required) {
            if (!this.application[field]) {
                this.errors.push(`${this.getFieldLabel(field)} is required`);
            }
        }
        
        // Email validation
        if (this.application.email && !this.isValidEmail(this.application.email)) {
            this.errors.push('Please enter a valid email address');
        }
        
        // Age validation (must be 18+)
        if (this.application.dateOfBirth && !this.isValidAge(this.application.dateOfBirth)) {
            this.errors.push('You must be at least 18 years old to apply');
        }
        
        return this.errors.length === 0;
    }

    validateMilitaryInfo() {
        const required = ['serviceStatus', 'servicesBranch', 'serviceStartDate'];
        
        for (let field of required) {
            if (!this.application[field]) {
                this.errors.push(`${this.getFieldLabel(field)} is required`);
            }
        }
        
        // Validate service dates
        if (this.application.serviceStartDate && this.application.serviceEndDate) {
            if (new Date(this.application.serviceStartDate) >= new Date(this.application.serviceEndDate)) {
                this.errors.push('Service end date must be after service start date');
            }
        }
        
        return this.errors.length === 0;
    }

    validateEmergencyInfo() {
        const required = ['emergencyContactName', 'emergencyContactRelationship', 'emergencyContactPhone', 'membershipLevel'];
        
        for (let field of required) {
            if (!this.application[field]) {
                this.errors.push(`${this.getFieldLabel(field)} is required`);
            }
        }
        
        return this.errors.length === 0;
    }

    validateDocuments() {
        if (!this.application.dd214Uploaded) {
            this.errors.push('DD-214 or service record upload is required');
        }
        
        if (!this.application.termsAccepted) {
            this.errors.push('You must accept the terms and conditions');
        }
        
        return this.errors.length === 0;
    }

    validateFinalSubmission() {
        // Run all validations
        const validations = [
            this.validatePersonalInfo(),
            this.validateMilitaryInfo(),
            this.validateEmergencyInfo(),
            this.validateDocuments()
        ];
        
        return validations.every(v => v === true);
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    isValidAge(dateOfBirth) {
        const today = new Date();
        const birthDate = new Date(dateOfBirth);
        const age = today.getFullYear() - birthDate.getFullYear();
        const monthDiff = today.getMonth() - birthDate.getMonth();
        
        if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
            return age - 1 >= 18;
        }
        
        return age >= 18;
    }

    getFieldLabel(field) {
        const labels = {
            firstName: 'First Name',
            lastName: 'Last Name',
            email: 'Email Address',
            phone: 'Phone Number',
            mailingAddress: 'Mailing Address',
            city: 'City',
            state: 'State',
            postalCode: 'ZIP/Postal Code',
            dateOfBirth: 'Date of Birth',
            serviceStatus: 'Service Status',
            servicesBranch: 'Branch of Service',
            serviceStartDate: 'Service Start Date',
            emergencyContactName: 'Emergency Contact Name',
            emergencyContactRelationship: 'Emergency Contact Relationship',
            emergencyContactPhone: 'Emergency Contact Phone',
            membershipLevel: 'Membership Level'
        };
        
        return labels[field] || field;
    }

    clearFieldErrors(field) {
        // Remove any errors related to this field
        this.errors = this.errors.filter(error => 
            !error.toLowerCase().includes(this.getFieldLabel(field).toLowerCase())
        );
    }

    moveToNextStep() {
        const steps = ['personal', 'military', 'emergency', 'documents'];
        const currentIndex = steps.indexOf(this.currentStep);
        
        if (currentIndex < steps.length - 1) {
            this.currentStep = steps[currentIndex + 1];
        }
    }

    moveToPreviousStep() {
        const steps = ['personal', 'military', 'emergency', 'documents'];
        const currentIndex = steps.indexOf(this.currentStep);
        
        if (currentIndex > 0) {
            this.currentStep = steps[currentIndex - 1];
        }
    }

    resetForm() {
        this.currentStep = 'personal';
        this.application = {
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
            mailingAddress: '',
            city: '',
            state: '',
            postalCode: '',
            dateOfBirth: '',
            roadName: '',
            serviceStatus: '',
            servicesBranch: '',
            militaryOccupation: '',
            serviceStartDate: '',
            serviceEndDate: '',
            deployments: '',
            awards: '',
            isCombatVeteran: false,
            emergencyContactName: '',
            emergencyContactRelationship: '',
            emergencyContactPhone: '',
            emergencyContactEmail: '',
            membershipLevel: '',
            dd214Uploaded: false,
            termsAccepted: false
        };
        this.errors = [];
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}