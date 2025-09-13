import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CvmaMembershipStatusPortal extends LightningElement {
    @track email = '';
    @track isLoading = false;
    @track applicationData = null;
    @track error = '';
    @track hasSearched = false;

    // Handle email input change
    handleEmailChange(event) {
        this.email = event.target.value;
        this.error = '';
        this.applicationData = null;
        this.hasSearched = false;
    }

    // Search for application status
    async handleSearchStatus() {
        if (!this.email || !this.email.includes('@')) {
            this.error = 'Please enter a valid email address';
            return;
        }

        this.isLoading = true;
        this.error = '';
        this.applicationData = null;
        this.hasSearched = false;

        try {
            // Standard Feature Integration: Query Membership_Application__c directly
            // This will be replaced by Flow Builder in production
            const result = await this.queryApplicationStatus(this.email);

            if (result.hasApplication) {
                this.applicationData = result.application;
            } else {
                this.error = 'No application found for this email address. You may apply for membership using the link below.';
            }

            this.hasSearched = true;

        } catch (error) {
            this.error = 'Error searching for application: ' + (error.body?.message || error.message);
            console.error('Application search error:', error);
        } finally {
            this.isLoading = false;
        }
    }

    // Simulate application status query (will be replaced by Flow Builder)
    async queryApplicationStatus(email) {
        // This simulates the SOQL query that would be handled by Flow Builder
        // In production, this component will integrate with Flow Builder's REST API
        return new Promise((resolve) => {
            setTimeout(() => {
                // Simulate different application states for demo purposes
                const applications = [
                    {
                        email: 'demo@cvma.org',
                        hasApplication: true,
                        application: {
                            applicationNumber: 'CVMA-25-0001',
                            firstName: 'John',
                            lastName: 'Veteran',
                            status: 'Under Review',
                            submissionDate: new Date('2025-09-01'),
                            reviewNotes: 'Application received and under officer review.',
                            serviceBranch: 'Army',
                            membershipLevel: 'Full Member'
                        }
                    },
                    {
                        email: 'pending@cvma.org',
                        hasApplication: true,
                        application: {
                            applicationNumber: 'CVMA-25-0002',
                            firstName: 'Jane',
                            lastName: 'Service',
                            status: 'Pending Documentation',
                            submissionDate: new Date('2025-09-05'),
                            reviewNotes: 'Please submit DD-214 documentation.',
                            serviceBranch: 'Marines',
                            membershipLevel: 'Full Member'
                        }
                    }
                ];

                const found = applications.find(app =>
                    app.email.toLowerCase() === email.toLowerCase()
                );

                if (found) {
                    resolve(found);
                } else {
                    resolve({ hasApplication: false });
                }
            }, 1000); // Simulate network delay
        });
    }

    // Handle new application button
    handleNewApplication() {
        // This will integrate with Flow Builder for new applications
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Membership Application',
                message: 'Redirecting to membership application form...',
                variant: 'info'
            })
        );

        // In production, this would launch the Flow Builder application flow
        // window.open('/membership-application-flow', '_blank');
    }

    // Computed properties
    get hasApplication() {
        return this.applicationData !== null;
    }

    get applicationStatus() {
        return this.applicationData ? this.applicationData.status : '';
    }

    get statusVariant() {
        if (!this.applicationData) return 'base';

        switch (this.applicationData.status) {
            case 'Approved':
                return 'success';
            case 'Under Review':
                return 'warning';
            case 'Pending Documentation':
                return 'warning';
            case 'Rejected':
                return 'error';
            default:
                return 'base';
        }
    }

    get statusIcon() {
        if (!this.applicationData) return 'utility:info';

        switch (this.applicationData.status) {
            case 'Approved':
                return 'utility:success';
            case 'Under Review':
                return 'utility:clock';
            case 'Pending Documentation':
                return 'utility:warning';
            case 'Rejected':
                return 'utility:error';
            default:
                return 'utility:info';
        }
    }

    get formattedSubmissionDate() {
        if (!this.applicationData || !this.applicationData.submissionDate) return '';

        return this.applicationData.submissionDate.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get showNewApplicationButton() {
        return this.hasSearched && !this.hasApplication;
    }

    get applicationDetails() {
        if (!this.applicationData) return [];

        return [
            {
                label: 'Application Number',
                value: this.applicationData.applicationNumber,
                key: 'number'
            },
            {
                label: 'Applicant Name',
                value: `${this.applicationData.firstName} ${this.applicationData.lastName}`,
                key: 'name'
            },
            {
                label: 'Service Branch',
                value: this.applicationData.serviceBranch,
                key: 'branch'
            },
            {
                label: 'Membership Level',
                value: this.applicationData.membershipLevel,
                key: 'level'
            },
            {
                label: 'Submission Date',
                value: this.formattedSubmissionDate,
                key: 'date'
            }
        ];
    }

    // Handle keyboard navigation
    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleSearchStatus();
        }
    }
}
