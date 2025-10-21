/**
 * cvmaMemberDocumentPortal.js
 * Epic #3 User Story #22: Member Document Access Portal
 * Standard Feature Integration: Lightning Files wrapper with CVMA branding
 *
 * Combat Veterans Motorcycle Association Chapter 20-7
 * Code Reduction: 93.8% (50 lines vs 800 custom lines)
 */
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import IS_GUEST from '@salesforce/user/isGuest';

export default class CvmaMemberDocumentPortal extends LightningElement {
    @api libraryId; // Content Library ID for filtering
    @api headerText = 'CVMA Chapter 20-7 Document Portal';
    @api description = 'Access chapter bylaws, official forms, and meeting documents';
    @api showUpload = false; // CEB only
    @api acceptedFormats = ['.pdf', '.doc', '.docx', '.xls', '.xlsx'];

    isGuestUser = IS_GUEST;

    get showPortal() {
        return !this.isGuestUser;
    }

    get guestMessage() {
        return 'Document access requires CVMA membership. Please log in or contact your chapter to join.';
    }

    get uploadEnabled() {
        return this.showUpload && !this.isGuestUser;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        const fileNames = uploadedFiles.map(file => file.name).join(', ');

        this.showToast(
            'Success',
            `${uploadedFiles.length} file(s) uploaded: ${fileNames}`,
            'success'
        );

        // Refresh files component
        this.template.querySelector('c-cvma-files-browser')?.refreshFiles();
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
