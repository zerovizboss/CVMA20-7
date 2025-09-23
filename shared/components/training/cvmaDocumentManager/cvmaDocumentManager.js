import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateTrainingPDF from '@salesforce/apex/CVMADocumentSharingController.generateTrainingPDF';
import getCEBTrainingDocuments from '@salesforce/apex/CVMADocumentSharingController.getCEBTrainingDocuments';

/**
 * CVMA Document Manager LWC
 * Purpose: Interface for CEB officers to generate and share training PDFs
 */
export default class CvmaDocumentManager extends LightningElement {
    @api mode = 'full'; // Component display mode: full, compact, minimal
    @api audienceFilter = ''; // Filter documents by target audience

    @track availableDocuments = [];
    @track selectedDocument = '';
    @track isGenerating = false;
    @track targetAudience = 'CEB_Officers';

    // Audience options for document sharing
    audienceOptions = [
        { label: 'CEB Officers', value: 'CEB_Officers' },
        { label: 'Chapter Members', value: 'Members' },
        { label: 'Technical Staff', value: 'Technical_Staff' }
    ];

    // Wire method to get available training documents
    @wire(getCEBTrainingDocuments)
    wiredDocuments({ error, data }) {
        if (data) {
            this.availableDocuments = data.map(doc => ({
                label: doc.name,
                value: doc.name,
                description: doc.description,
                category: doc.category
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load training documents', 'error');
        }
    }

    // Handle document selection change
    handleDocumentChange(event) {
        this.selectedDocument = event.detail.value;
    }

    // Handle audience selection change
    handleAudienceChange(event) {
        this.targetAudience = event.detail.value;
    }

    // Generate PDF for selected document
    async handleGeneratePDF() {
        if (!this.selectedDocument) {
            this.showToast('Warning', 'Please select a document to generate', 'warning');
            return;
        }

        this.isGenerating = true;

        try {
            // Get markdown content for selected document
            const markdownContent = await this.getDocumentContent(this.selectedDocument);

            // Generate PDF
            const contentDocumentId = await generateTrainingPDF({
                documentName: this.selectedDocument,
                markdownContent: markdownContent,
                targetAudience: this.targetAudience
            });

            this.showToast(
                'Success',
                `PDF generated successfully and shared with ${this.getAudienceLabel()}`,
                'success'
            );

            // Open the generated PDF
            this.openDocument(contentDocumentId);

        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to generate PDF', 'error');
        } finally {
            this.isGenerating = false;
        }
    }

    // Get document content based on selection
    async getDocumentContent(documentName) {
        // In a real implementation, this would fetch the actual markdown content
        // For demo purposes, we'll return sample content
        const documentContentMap = {
            'CEB Officer Dashboard Guide': this.getCEBDashboardGuide(),
            'Member Management Procedures': this.getMemberManagementGuide(),
            'Event Coordination Guide': this.getEventCoordinationGuide(),
            'Financial Oversight Training': this.getFinancialOversightGuide()
        };

        return documentContentMap[documentName] || this.getDefaultContent(documentName);
    }

    // Sample content methods
    getCEBDashboardGuide() {
        return `# CEB Officer Dashboard Guide

## Accessing Your Dashboard
Your dashboard provides a comprehensive view of chapter operations.

### Key Features:
- **Member Overview**: Current membership metrics
- **Event Management**: Upcoming events and RSVP tracking
- **Financial Summary**: Revenue and expense tracking
- **Communication Hub**: Member outreach tools

### Daily Checklist:
1. Review new member applications
2. Check event attendance updates
3. Monitor financial transactions
4. Respond to member communications

## Navigation Tips:
- Use the main menu for quick access to all features
- Mobile-responsive design works on all devices
- Bookmark frequently used reports
- Set up notifications for important updates`;
    }

    getMemberManagementGuide() {
        return `# Member Management Procedures

## New Member Onboarding
Streamlined process for welcoming new CVMA members.

### Application Review:
1. **Initial Review**: Validate application completeness
2. **Background Check**: Coordinate verification process
3. **Welcome Sequence**: Automated member onboarding
4. **Mentorship**: Connect with experienced members

## Member Lifecycle:
- **Status Management**: Active, inactive, suspended members
- **Dues Tracking**: Payment monitoring and follow-up
- **Engagement**: Track participation and involvement
- **Recognition**: Awards and achievement tracking

## Special Situations:
- **Deployment Support**: Automatic dues suspension
- **Hardship Assistance**: Benevolent fund coordination
- **Retention**: Early intervention strategies`;
    }

    getEventCoordinationGuide() {
        return `# Event Coordination Guide

## Event Planning Process
Comprehensive guide for organizing successful chapter events.

### Event Creation:
1. **Setup**: Create event in platform
2. **Details**: Add location, date, requirements
3. **RSVP**: Enable member response tracking
4. **Communications**: Send invitations and updates

## Event Types:
- **Chapter Meetings**: Monthly business meetings
- **Social Events**: Rides and community gatherings
- **Fundraisers**: Charity and revenue events
- **Memorial Services**: Honor fallen veterans

## Post-Event:
- Record attendance and participation
- Process financial transactions
- Collect member feedback
- Archive photos and documentation`;
    }

    getFinancialOversightGuide() {
        return `# Financial Oversight Training

## Dashboard Overview
Monitor chapter financial health and compliance.

### Key Metrics:
- **Revenue**: Dues, donations, fundraising
- **Expenses**: Operating costs and expenditures
- **Budget**: Actual vs. planned comparison
- **Compliance**: Regulatory requirement tracking

## Monthly Responsibilities:
1. **Review**: Analyze financial statements
2. **Approvals**: Process expense requests
3. **Reporting**: Generate required reports
4. **Transparency**: Maintain member access

## Emergency Procedures:
- Benevolent fund request processing
- Crisis financial decision-making
- Fraud prevention and monitoring
- Audit preparation and compliance`;
    }

    getDefaultContent(documentName) {
        return `# ${documentName}

## CVMA Chapter 20-7 Training Document

This training document provides essential information for ${this.getAudienceLabel()}.

### Key Topics:
- Platform navigation and usage
- Best practices and procedures
- Troubleshooting and support
- Resources and references

### Contact Information:
For questions about this training material, contact your CEB training coordinator.

**Combat Veterans Motorcycle Association**
**Chapter 20-7 - Jacksonville, FL**
**Vets Serving Vets**`;
    }

    // Get audience label for display
    getAudienceLabel() {
        const audienceMap = {
            'CEB_Officers': 'CEB Officers',
            'Members': 'Chapter Members',
            'Technical_Staff': 'Technical Staff'
        };
        return audienceMap[this.targetAudience] || 'Selected Audience';
    }

    // Open generated document
    openDocument(contentDocumentId) {
        // Navigate to the document
        window.open(`/lightning/r/ContentDocument/${contentDocumentId}/view`, '_blank');
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

    // Computed properties
    get hasDocuments() {
        return this.availableDocuments && this.availableDocuments.length > 0;
    }

    get generateButtonLabel() {
        return this.isGenerating ? 'Generating...' : 'Generate PDF';
    }
}
