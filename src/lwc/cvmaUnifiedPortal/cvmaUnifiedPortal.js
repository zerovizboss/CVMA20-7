import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import USER_ID from '@salesforce/user/Id';
import USER_PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import USER_CONTACT_ID from '@salesforce/schema/User.ContactId';
import CONTACT_MEMBER_LEVEL from '@salesforce/schema/Contact.CVMA_Member_Level__c';
import MILITARY_AWARDS_CSS from '@salesforce/resourceUrl/cvmaMilitaryAwardsCSS';

/**
 * CVMA Unified Portal - Single-Site Architecture
 * Consolidates all site-specific components into role-based unified experience
 * Military Awards & Ribbons branding integrated throughout
 * Supports: Officers, Members, Guests with appropriate content filtering
 */
export default class CvmaUnifiedPortal extends LightningElement {
    @api portalMode = 'unified'; // unified, officer, member, guest
    @api enableCrisisSupport = true;
    @api showQuickActions = true;

    @track showOfficerSection = false;
    @track showTrainingSection = true;
    @track showKnowledgeSection = true;
    @track showDocumentSection = true;
    @track isLoading = false;

    // User context properties
    userRole = 'Guest';
    isOfficer = false;
    isMember = false;
    enableSearch = true;
    crisisSupportEnabled = true;
    audienceFilter = 'all';

    // Wire user record to determine role and permissions
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_PROFILE_NAME, USER_CONTACT_ID]
    })
    wiredUser({ error, data }) {
        if (data) {
            this.determineUserRole(data);
        } else if (error) {
            console.error('Error loading user data:', error);
            this.userRole = 'Guest';
        }
    }

    // Wire contact record for member-specific data
    @wire(getRecord, {
        recordId: '$contactId',
        fields: [CONTACT_MEMBER_LEVEL]
    })
    wiredContact({ error, data }) {
        if (data) {
            this.determineMemberLevel(data);
        } else if (error && this.contactId) {
            console.error('Error loading contact data:', error);
        }
    }

    // Load military awards CSS styling
    connectedCallback() {
        this.loadMilitaryAwardsCSS();
        this.initializePortalSections();
    }

    async loadMilitaryAwardsCSS() {
        try {
            await loadStyle(this, MILITARY_AWARDS_CSS);
            console.log('CVMA Military Awards CSS loaded successfully');
        } catch (error) {
            console.error('Error loading Military Awards CSS:', error);
            this.showToast('Warning', 'Military branding styles may not display correctly', 'warning');
        }
    }

    // Determine user role and configure portal sections
    determineUserRole(userData) {
        const profileName = getFieldValue(userData, USER_PROFILE_NAME);
        this.contactId = getFieldValue(userData, USER_CONTACT_ID);

        // Role determination logic
        if (profileName && profileName.includes('System Administrator')) {
            this.userRole = 'System Administrator';
            this.isOfficer = true;
            this.showOfficerSection = true;
        } else if (this.contactId) {
            // Member with contact record
            this.userRole = 'Member';
            this.isMember = true;
            this.audienceFilter = 'member';
        } else {
            // Guest user
            this.userRole = 'Guest';
            this.audienceFilter = 'guest';
            this.showOfficerSection = false;
        }

        this.configurePortalForRole();
    }

    // Determine member level from contact record
    determineMemberLevel(contactData) {
        const memberLevel = getFieldValue(contactData, CONTACT_MEMBER_LEVEL);

        if (memberLevel) {
            if (memberLevel.includes('Officer') || memberLevel.includes('Commander') ||
                memberLevel.includes('Executive') || memberLevel.includes('Board')) {
                this.userRole = `CEB ${memberLevel}`;
                this.isOfficer = true;
                this.showOfficerSection = true;
                this.audienceFilter = 'officer';
            } else {
                this.userRole = memberLevel;
                this.audienceFilter = 'member';
            }
        }

        this.configurePortalForRole();
    }

    // Configure portal sections based on user role
    configurePortalForRole() {
        switch (this.audienceFilter) {
            case 'officer':
                this.showOfficerSection = true;
                this.showTrainingSection = true;
                this.showKnowledgeSection = true;
                this.showDocumentSection = true;
                break;
            case 'member':
                this.showOfficerSection = false;
                this.showTrainingSection = true;
                this.showKnowledgeSection = true;
                this.showDocumentSection = true;
                break;
            case 'guest':
                this.showOfficerSection = false;
                this.showTrainingSection = false;
                this.showKnowledgeSection = true;
                this.showDocumentSection = false;
                break;
            default:
                this.initializePortalSections();
        }
    }

    // Initialize default portal section visibility
    initializePortalSections() {
        this.showOfficerSection = this.isOfficer;
        this.showTrainingSection = true;
        this.showKnowledgeSection = true;
        this.showDocumentSection = this.isMember || this.isOfficer;
    }

    // Section toggle handlers
    toggleOfficerSection() {
        this.showOfficerSection = !this.showOfficerSection;
        this.trackPortalUsage('Officer Section Toggle');
    }

    toggleTrainingSection() {
        this.showTrainingSection = !this.showTrainingSection;
        this.trackPortalUsage('Training Section Toggle');
    }

    toggleKnowledgeSection() {
        this.showKnowledgeSection = !this.showKnowledgeSection;
        this.trackPortalUsage('Knowledge Section Toggle');
    }

    toggleDocumentSection() {
        this.showDocumentSection = !this.showDocumentSection;
        this.trackPortalUsage('Document Section Toggle');
    }

    // Training content handlers
    openMemberOrientation() {
        this.openTrainingModule('Member Orientation', 'member-orientation');
    }

    openChapterProtocols() {
        this.openTrainingModule('Chapter Protocols', 'chapter-protocols');
    }

    openSafetyTraining() {
        this.openTrainingModule('Safety Training', 'safety-training');
    }

    // Document management handlers
    openBylaws() {
        this.openDocument('CVMA Bylaws', 'cvma-bylaws', 'Knowledge Article');
    }

    openSOPs() {
        this.openDocument('Standard Operating Procedures', 'cvma-sops', 'Knowledge Article');
    }

    openForms() {
        this.openDocument('Forms & Templates', 'cvma-forms', 'ContentDocument');
    }

    // Crisis support handlers
    contactCrisisLine() {
        // Open Veterans Crisis Line in new tab
        window.open('tel:1-800-273-8255', '_blank');
        this.trackPortalUsage('Crisis Line Contact');

        this.showToast(
            'Crisis Support',
            'Veterans Crisis Line: 1-800-273-8255 - You are not alone',
            'info'
        );
    }

    contactChapterEmergency() {
        // Dispatch event for chapter emergency contact
        this.dispatchEvent(new CustomEvent('chapteremergency', {
            detail: {
                type: 'emergency_contact',
                userRole: this.userRole,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));

        this.showToast(
            'Chapter Support',
            'Connecting you with Chapter emergency support...',
            'info'
        );
    }

    // Generic training module opener
    openTrainingModule(moduleName, moduleId) {
        try {
            // Dispatch event to parent components
            this.dispatchEvent(new CustomEvent('trainingmoduleopen', {
                detail: {
                    moduleName: moduleName,
                    moduleId: moduleId,
                    userRole: this.userRole,
                    audienceFilter: this.audienceFilter
                },
                bubbles: true
            }));

            this.trackPortalUsage(`Training Module: ${moduleName}`);

            this.showToast(
                'Training Module',
                `Opening ${moduleName}...`,
                'success'
            );
        } catch (error) {
            console.error('Error opening training module:', error);
            this.showToast('Error', 'Failed to open training module', 'error');
        }
    }

    // Generic document opener with type support
    openDocument(documentName, documentId, documentType) {
        try {
            // Dispatch event for document access
            this.dispatchEvent(new CustomEvent('documentopen', {
                detail: {
                    documentName: documentName,
                    documentId: documentId,
                    documentType: documentType,
                    userRole: this.userRole,
                    audienceFilter: this.audienceFilter
                },
                bubbles: true
            }));

            this.trackPortalUsage(`Document Access: ${documentName}`);

            this.showToast(
                'Document Access',
                `Opening ${documentName}...`,
                'success'
            );
        } catch (error) {
            console.error('Error opening document:', error);
            this.showToast('Error', 'Failed to open document', 'error');
        }
    }

    // Portal usage analytics
    trackPortalUsage(action) {
        try {
            // Create analytics event
            const analyticsEvent = new CustomEvent('portalanalytics', {
                detail: {
                    action: action,
                    userRole: this.userRole,
                    audienceFilter: this.audienceFilter,
                    timestamp: new Date().toISOString(),
                    portalMode: this.portalMode
                },
                bubbles: true
            });

            this.dispatchEvent(analyticsEvent);
        } catch (error) {
            console.error('Error tracking portal usage:', error);
        }
    }

    // Utility methods
    get contactId() {
        return this._contactId;
    }

    set contactId(value) {
        this._contactId = value;
    }

    get portalTitle() {
        return `CVMA Portal - ${this.userRole}`;
    }

    get welcomeMessage() {
        const timeOfDay = this.getTimeOfDay();
        return `Good ${timeOfDay}, ${this.userRole}`;
    }

    getTimeOfDay() {
        const hour = new Date().getHours();
        if (hour < 12) return 'morning';
        if (hour < 17) return 'afternoon';
        return 'evening';
    }

    // Show toast notification
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Error boundary
    errorCallback(error, stack) {
        console.error('CVMA Unified Portal Error:', error);
        console.error('Stack:', stack);

        this.showToast(
            'Portal Error',
            'An error occurred in the portal. Please refresh and try again.',
            'error'
        );
    }
}
