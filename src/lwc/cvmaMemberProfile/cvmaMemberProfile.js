import { LightningElement, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import CONTACT_ID_FIELD from '@salesforce/schema/User.ContactId';

// User fields
import USER_FIRSTNAME_FIELD from '@salesforce/schema/User.FirstName';
import USER_LASTNAME_FIELD from '@salesforce/schema/User.LastName';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import USER_PHONE_FIELD from '@salesforce/schema/User.Phone';
import USER_MOBILEPHONE_FIELD from '@salesforce/schema/User.MobilePhone';

// Contact fields
import CONTACT_PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import CONTACT_MOBILEPHONE_FIELD from '@salesforce/schema/Contact.MobilePhone';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_MAILINGSTREET_FIELD from '@salesforce/schema/Contact.MailingStreet';
import CONTACT_MAILINGCITY_FIELD from '@salesforce/schema/Contact.MailingCity';
import CONTACT_MAILINGSTATE_FIELD from '@salesforce/schema/Contact.MailingState';
import CONTACT_MAILINGPOSTALCODE_FIELD from '@salesforce/schema/Contact.MailingPostalCode';
import CONTACT_MAILINGCOUNTRY_FIELD from '@salesforce/schema/Contact.MailingCountry';
import CONTACT_MEMBERSHIP_ID_FIELD from '@salesforce/schema/Contact.Membership_Id__c';
import CONTACT_ROAD_NAME_FIELD from '@salesforce/schema/Contact.Road_Name__c';

const USER_FIELDS = [
    USER_FIRSTNAME_FIELD,
    USER_LASTNAME_FIELD,
    USER_EMAIL_FIELD,
    USER_PHONE_FIELD,
    USER_MOBILEPHONE_FIELD,
    CONTACT_ID_FIELD
];

const CONTACT_FIELDS = [
    CONTACT_PHONE_FIELD,
    CONTACT_MOBILEPHONE_FIELD,
    CONTACT_EMAIL_FIELD,
    CONTACT_MAILINGSTREET_FIELD,
    CONTACT_MAILINGCITY_FIELD,
    CONTACT_MAILINGSTATE_FIELD,
    CONTACT_MAILINGPOSTALCODE_FIELD,
    CONTACT_MAILINGCOUNTRY_FIELD,
    CONTACT_MEMBERSHIP_ID_FIELD,
    CONTACT_ROAD_NAME_FIELD
];

export default class CvmaMemberProfile extends LightningElement {
    @track isEditing = false;
    @track isLoading = false;
    @track userRecord = {};
    @track contactRecord = {};
    @track originalUserData = {};
    @track originalContactData = {};
    
    userId = Id;
    contactId;

    // Wire user record
    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.userRecord = {
                Id: data.id,
                FirstName: data.fields.FirstName.value,
                LastName: data.fields.LastName.value,
                Email: data.fields.Email.value,
                Phone: data.fields.Phone.value,
                MobilePhone: data.fields.MobilePhone.value
            };
            this.contactId = data.fields.ContactId.value;
            this.originalUserData = { ...this.userRecord };
        } else if (error) {
            this.showToast('Error', 'Error loading user profile: ' + error.body.message, 'error');
        }
    }

    // Wire contact record
    @wire(getRecord, { recordId: '$contactId', fields: CONTACT_FIELDS })
    wiredContact({ error, data }) {
        if (data) {
            this.contactRecord = {
                Id: data.id,
                Phone: data.fields.Phone.value,
                MobilePhone: data.fields.MobilePhone.value,
                Email: data.fields.Email.value,
                MailingStreet: data.fields.MailingStreet.value,
                MailingCity: data.fields.MailingCity.value,
                MailingState: data.fields.MailingState.value,
                MailingPostalCode: data.fields.MailingPostalCode.value,
                MailingCountry: data.fields.MailingCountry.value,
                Membership_Id__c: data.fields.Membership_Id__c.value,
                Road_Name__c: data.fields.Road_Name__c.value
            };
            this.originalContactData = { ...this.contactRecord };
        } else if (error) {
            this.showToast('Error', 'Error loading contact information: ' + error.body.message, 'error');
        }
    }

    get displayName() {
        return `${this.userRecord.FirstName || ''} ${this.userRecord.LastName || ''}`.trim();
    }

    get membershipId() {
        return this.contactRecord.Membership_Id__c || 'Not assigned';
    }

    get roadName() {
        return this.contactRecord.Road_Name__c || 'Not specified';
    }

    handleEdit() {
        this.isEditing = true;
    }

    handleCancel() {
        // Restore original data
        this.userRecord = { ...this.originalUserData };
        this.contactRecord = { ...this.originalContactData };
        this.isEditing = false;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        const recordType = event.target.dataset.recordType;

        if (recordType === 'user') {
            this.userRecord = { ...this.userRecord, [field]: value };
        } else if (recordType === 'contact') {
            this.contactRecord = { ...this.contactRecord, [field]: value };
        }
    }

    async handleSave() {
        this.isLoading = true;
        
        try {
            // Validate required fields
            if (!this.userRecord.FirstName || !this.userRecord.LastName || !this.userRecord.Email) {
                throw new Error('First Name, Last Name, and Email are required fields.');
            }

            // Update User record
            const userFields = {
                Id: this.userRecord.Id,
                FirstName: this.userRecord.FirstName,
                LastName: this.userRecord.LastName,
                Email: this.userRecord.Email,
                Phone: this.userRecord.Phone,
                MobilePhone: this.userRecord.MobilePhone
            };

            await updateRecord({ fields: userFields });

            // Update Contact record
            const contactFields = {
                Id: this.contactRecord.Id,
                Phone: this.contactRecord.Phone,
                MobilePhone: this.contactRecord.MobilePhone,
                Email: this.contactRecord.Email,
                MailingStreet: this.contactRecord.MailingStreet,
                MailingCity: this.contactRecord.MailingCity,
                MailingState: this.contactRecord.MailingState,
                MailingPostalCode: this.contactRecord.MailingPostalCode,
                MailingCountry: this.contactRecord.MailingCountry
            };

            await updateRecord({ fields: contactFields });

            // Update original data for future comparisons
            this.originalUserData = { ...this.userRecord };
            this.originalContactData = { ...this.contactRecord };

            this.isEditing = false;
            this.showToast('Success', 'Your profile has been updated successfully!', 'success');

        } catch (error) {
            this.showToast('Error', 'Error updating profile: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
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