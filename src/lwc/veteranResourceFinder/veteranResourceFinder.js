import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import IS_GUEST from '@salesforce/user/isGuest';
import getVeteranOrganizations from '@salesforce/apex/CVMAVeteranResourcesController.getVeteranOrganizations';
import checkEligibility from '@salesforce/apex/CVMAVeteranResourcesController.checkEligibility';

export default class VeteranResourceFinder extends LightningElement {
    @api guestAccess = true;
    @api requireAuthentication = false;
    @api title = 'Veteran Resources Finder';
    @api maxResults = 20;
    @track searchTerm = '';
    @track selectedCategory = 'All';
    @track selectedState = '';
    @track veteranData = {};
    @track organizations = [];
    @track filteredOrganizations = [];
    @track isLoading = false;
    @track showEligibilityModal = false;
    @track selectedOrganization = null;
    @track eligibilityResults = [];
    @track isGuestUser = IS_GUEST;
    @track userContext = {
        isAuthenticated: false,
        isMember: false,
        isGuest: IS_GUEST
    };

    categoryOptions = [
        { label: 'All Categories', value: 'All' },
        { label: 'Service Dogs', value: 'Service Dogs' },
        { label: 'Housing & Financial', value: 'Housing' },
        { label: 'Wounded Warrior Support', value: 'Wounded Warrior' },
        { label: 'Employment & Career', value: 'Employment' },
        { label: 'Emergency Response', value: 'Emergency' },
        { label: 'Mental Health', value: 'Mental Health' },
        { label: 'Education & Training', value: 'Education' },
        { label: 'Legal Services', value: 'Legal' }
    ];

    stateOptions = [
        { label: 'All States', value: '' },
        { label: 'Alabama', value: 'AL' },
        { label: 'Alaska', value: 'AK' },
        { label: 'Arizona', value: 'AZ' },
        { label: 'Arkansas', value: 'AR' },
        { label: 'California', value: 'CA' },
        { label: 'Colorado', value: 'CO' },
        { label: 'Connecticut', value: 'CT' },
        { label: 'Delaware', value: 'DE' },
        { label: 'Florida', value: 'FL' },
        { label: 'Georgia', value: 'GA' }
        // Add remaining states as needed
    ];

    @wire(getVeteranOrganizations)
    wiredOrganizations({ error, data }) {
        if (data) {
            this.organizations = data.map(org => ({
                ...org,
                logoUrl: org.logoUrl || '/resource/veteranOrgLogos/' + org.organizationName.replace(/\s+/g, '_').toLowerCase() + '_logo.png',
                eligibilityHighlights: this.parseEligibilityText(org.eligibilityCriteria)
            }));
            this.filterOrganizations();
        } else if (error) {
            this.showToast('Error', 'Failed to load veteran organizations: ' + error.body.message, 'error');
        }
    }

    connectedCallback() {
        // Initialize user context and member data
        this.initializeUserContext();
        this.loadMemberContext();
    }

    initializeUserContext() {
        this.userContext = {
            isAuthenticated: !IS_GUEST,
            isMember: !IS_GUEST, // Will be refined based on user record
            isGuest: IS_GUEST
        };

        // If guest access is disabled and user is guest, show authentication prompt
        if (!this.guestAccess && IS_GUEST) {
            this.showAuthenticationPrompt();
        }
    }

    loadMemberContext() {
        if (IS_GUEST) {
            // For guest users, provide generic veteran profile
            this.veteranData = {
                serviceConnectedDisability: null,
                disabilityRating: null,
                branch: 'Unknown',
                combatVeteran: null,
                state: '',
                needs: []
            };
        } else {
            // For authenticated users, get member profile data
            // This would integrate with CVMAMemberProfileController
            this.veteranData = {
                serviceConnectedDisability: true,
                disabilityRating: 70,
                branch: 'Army',
                combatVeteran: true,
                state: 'FL',
                needs: ['Housing', 'Service Dogs', 'Mental Health']
            };
        }
    }

    showAuthenticationPrompt() {
        this.showToast(
            'Authentication Required',
            'Please log in to access personalized veteran resources and eligibility checking.',
            'info'
        );
    }

    parseEligibilityText(criteria) {
        if (!criteria) return [];
        return criteria.split(',').map(item => item.trim()).slice(0, 3);
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.filterOrganizations();
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.filterOrganizations();
    }

    handleStateChange(event) {
        this.selectedState = event.detail.value;
        this.filterOrganizations();
    }

    filterOrganizations() {
        let filtered = [...this.organizations];

        // Filter by search term
        if (this.searchTerm) {
            const searchLower = this.searchTerm.toLowerCase();
            filtered = filtered.filter(org =>
                org.organizationName.toLowerCase().includes(searchLower) ||
                org.description.toLowerCase().includes(searchLower) ||
                org.serviceCategory.toLowerCase().includes(searchLower)
            );
        }

        // Filter by category
        if (this.selectedCategory && this.selectedCategory !== 'All') {
            filtered = filtered.filter(org => org.serviceCategory === this.selectedCategory);
        }

        // Filter by state
        if (this.selectedState) {
            filtered = filtered.filter(org =>
                !org.statesCovered ||
                org.statesCovered.includes(this.selectedState) ||
                org.statesCovered === 'National'
            );
        }

        // Sort by relevance to member needs
        filtered = this.sortByRelevance(filtered);

        this.filteredOrganizations = filtered;
    }

    sortByRelevance(organizations) {
        if (!this.veteranData.needs) return organizations;

        return organizations.sort((a, b) => {
            const aRelevance = this.calculateRelevance(a);
            const bRelevance = this.calculateRelevance(b);
            return bRelevance - aRelevance;
        });
    }

    calculateRelevance(organization) {
        let score = 0;

        // Higher score for organizations matching member needs
        if (this.veteranData.needs.includes(organization.serviceCategory)) {
            score += 10;
        }

        // Preference for local organizations
        if (organization.statesCovered && organization.statesCovered.includes(this.veteranData.state)) {
            score += 5;
        }

        // Preference for combat veteran specific programs
        if (this.veteranData.combatVeteran && organization.combatVeteranFocus) {
            score += 3;
        }

        // Preference for disability-specific programs
        if (this.veteranData.serviceConnectedDisability && organization.disabilityFocus) {
            score += 3;
        }

        return score;
    }

    handleCheckEligibility(event) {
        const organizationId = event.currentTarget.dataset.id;
        this.selectedOrganization = this.filteredOrganizations.find(org => org.id === organizationId);

        // Check if guest user access is restricted for eligibility checking
        if (IS_GUEST && this.requireAuthentication) {
            this.showToast(
                'Login Required',
                'Please log in to check eligibility for veteran programs. Guest users can view organization information but eligibility checking requires authentication.',
                'warning'
            );
            return;
        }

        this.performEligibilityCheck();
    }

    performEligibilityCheck() {
        this.isLoading = true;

        // For guest users, provide limited eligibility information
        if (IS_GUEST) {
            this.eligibilityResults = [{
                program: 'General Information',
                programName: this.selectedOrganization.organizationName + ' General Information',
                eligibilityStatus: 'Contact Organization',
                statusVariant: 'warning',
                requirements: 'As a guest user, please contact the organization directly for detailed eligibility requirements. Log in for personalized eligibility checking.'
            }];
            this.showEligibilityModal = true;
            this.isLoading = false;
            return;
        }

        checkEligibility({
            organizationId: this.selectedOrganization.id,
            veteranData: this.veteranData
        })
        .then(result => {
            this.eligibilityResults = result;
            this.showEligibilityModal = true;
        })
        .catch(error => {
            this.showToast('Error', 'Failed to check eligibility: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleCloseModal() {
        this.showEligibilityModal = false;
        this.selectedOrganization = null;
        this.eligibilityResults = [];
    }

    handleApplyNow(event) {
        const organizationId = event.currentTarget.dataset.id;
        const organization = this.filteredOrganizations.find(org => org.id === organizationId);

        // Navigate to application assistance or external link
        if (organization.applicationUrl) {
            window.open(organization.applicationUrl, '_blank');
        } else {
            // Navigate to internal application assistance
            this.dispatchEvent(new CustomEvent('navigatetoapp', {
                detail: { organizationId: organizationId }
            }));
        }
    }

    handleLearnMore(event) {
        const organizationId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('navigatetodetail', {
            detail: { organizationId: organizationId }
        }));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get hasResults() {
        return this.filteredOrganizations && this.filteredOrganizations.length > 0;
    }

    get noResultsMessage() {
        return `No organizations found matching your criteria. Try adjusting your search terms or category filters.`;
    }

    get eligibilityModalTitle() {
        return this.selectedOrganization ?
            `Eligibility Check - ${this.selectedOrganization.organizationName}` :
            'Eligibility Check';
    }
}
