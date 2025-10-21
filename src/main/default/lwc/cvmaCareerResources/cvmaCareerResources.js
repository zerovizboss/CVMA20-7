import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCareerResources from '@salesforce/apex/CVMACareerResourcesController.getCareerResources';
import getResourceTypes from '@salesforce/apex/CVMACareerResourcesController.getResourceTypes';
import IS_GUEST from '@salesforce/user/isGuest';

export default class CvmaCareerResources extends LightningElement {
    @track selectedType = '';
    @track resources = [];
    @track resourceTypes = [];
    @track isLoading = true;
    @track error;

    isGuestUser = IS_GUEST;

    get showResources() {
        return !this.isGuestUser;
    }

    get guestMessage() {
        return 'Career resource access requires CVMA membership. Please log in or contact your chapter to join.';
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
            this.handleError('Error loading resource types', error);
        }
    }

    @wire(getCareerResources, { resourceType: '$selectedType' })
    wiredResources({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.resources = data;
            this.error = undefined;
        } else if (error) {
            this.handleError('Error loading career resources', error);
        }
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
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
