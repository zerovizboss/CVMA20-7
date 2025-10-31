/**
 * @description LWC component for displaying CVMA housing and financial assistance resources
 * User Story #74: Housing & Financial Assistance Resources
 *
 * @author CVMA Chapter 20-7
 * @date 2025-10-21
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHousingFinancialResources from '@salesforce/apex/CVMAHousingFinancialResourcesController.getHousingFinancialResources';
import getResourceTypes from '@salesforce/apex/CVMAHousingFinancialResourcesController.getResourceTypes';
import getEmergencyResources from '@salesforce/apex/CVMAHousingFinancialResourcesController.getEmergencyResources';
import IS_GUEST from '@salesforce/user/isGuest';

export default class CvmaHousingFinancialResources extends LightningElement {
    @track selectedType = '';
    @track resources = [];
    @track resourceTypes = [];
    @track isLoading = true;
    @track error;
    @track showEmergencyOnly = false;

    isGuestUser = IS_GUEST;

    get showResources() {
        return true; // Allow all users: Guests, Members, and CEB
    }

    get guestMessage() {
        return 'Housing and financial resource access requires CVMA membership. Please log in or contact your chapter to join.';
    }

    get hasResources() {
        return this.resources && this.resources.length > 0;
    }

    get typeOptions() {
        const options = [{ label: 'All Resources', value: '' }];
        if (this.resourceTypes) {
            this.resourceTypes.forEach(type => {
                options.push({ label: type, value: type });
            });
        }
        return options;
    }

    @wire(getResourceTypes)
    wiredTypes({ error, data }) {
        if (data) {
            this.resourceTypes = data;
        } else if (error) {
            // Guest users cannot query metadata types - gracefully degrade
            console.warn('Resource types unavailable for guest users:', error);
            this.resourceTypes = []; // Show all resources by default
        }
    }

    @wire(getHousingFinancialResources, { resourceType: '$selectedType' })
    wiredResources({ error, data }) {
        if (!this.showEmergencyOnly) {
            this.isLoading = false;
            if (data) {
                this.resources = data;
                this.error = undefined;
            } else if (error) {
                this.handleError('Error loading housing/financial resources', error);
            }
        }
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.showEmergencyOnly = false;
        this.isLoading = true;
    }

    handleShowEmergency() {
        this.showEmergencyOnly = true;
        this.isLoading = true;
        this.selectedType = '';

        getEmergencyResources()
            .then(data => {
                this.resources = data;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError('Error loading emergency resources', error);
                this.isLoading = false;
            });
    }

    handleShowAll() {
        this.showEmergencyOnly = false;
        this.selectedType = '';
        this.isLoading = true;
    }

    handleError(title, error) {
        this.error = error;
        this.resources = [];
        const errorMessage = error.body?.message || error.message || 'Unknown error';
        this.showToast(title, errorMessage, 'error');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}
