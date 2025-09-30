import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateTrainingPDF from '@salesforce/apex/CVMADocumentSharingController.generateTrainingPDF';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

/**
 * CEB Training Hub - Optimized for CEB Site Experience
 * Purpose: Task-oriented training interface for Chapter Executive Board Officers
 * Site: https://cvma20-7-dev-ed.develop.my.site.com/ceb
 */
export default class CvmaCebTrainingHub extends LightningElement {
    @api displayMode = 'dashboard';
    @api showQuickActions = false;
    @api defaultCategory = 'all';

    @track trainingModules = [];
    @track selectedModule = '';
    @track isLoading = false;

    // Training modules optimized for CEB officer workflows
    cebTrainingModules = [
        {
            id: 'officer-dashboard',
            title: 'Officer Dashboard Mastery',
            description: 'Complete guide to officer dashboard usage and daily workflows',
            icon: 'standard:dashboard',
            category: 'Daily Operations',
            estimatedTime: '15 min',
            documents: [
                'CEB Officer Dashboard Guide',
                'Daily Task Checklist',
                'Dashboard Navigation Tips'
            ]
        },
        {
            id: 'member-management',
            title: 'Member Lifecycle Management',
            description: 'Comprehensive member management from onboarding to retention',
            icon: 'standard:people',
            category: 'Member Services',
            estimatedTime: '25 min',
            documents: [
                'Member Management Procedures',
                'New Member Onboarding',
                'Retention Strategies'
            ]
        },
        {
            id: 'financial-oversight',
            title: 'Financial Oversight Excellence',
            description: 'Financial management, reporting, and compliance training',
            icon: 'standard:currency',
            category: 'Financial Management',
            estimatedTime: '30 min',
            documents: [
                'Financial Oversight Training',
                'Budget Management',
                'Compliance Reporting'
            ]
        },
        {
            id: 'event-coordination',
            title: 'Event Coordination Mastery',
            description: 'End-to-end event planning, execution, and follow-up',
            icon: 'standard:event',
            category: 'Event Management',
            estimatedTime: '20 min',
            documents: [
                'Event Coordination Guide',
                'RSVP Management',
                'Post-Event Procedures'
            ]
        }
    ];

    connectedCallback() {
        this.trainingModules = this.cebTrainingModules;
    }

    // Handle training module selection
    handleModuleSelect(event) {
        const moduleId = event.currentTarget.dataset.moduleId;
        this.selectedModule = moduleId;

        // Dispatch custom event for Experience Builder integration
        this.dispatchEvent(new CustomEvent('moduleselected', {
            detail: { moduleId: moduleId },
            bubbles: true
        }));
    }

    // Quick access to specific training
    handleQuickAction(event) {
        const action = event.currentTarget.dataset.action;

        switch(action) {
            case 'daily-checklist':
                this.openTrainingDocument('Daily Officer Checklist');
                break;
            case 'emergency-procedures':
                this.openTrainingDocument('Emergency Response Procedures');
                break;
            case 'member-support':
                this.openTrainingDocument('Member Support Guidelines');
                break;
        }
    }

    // Open training document using existing PDF generation system
    async openTrainingDocument(documentName) {
        try {
            this.isLoading = true;

            // Get document content from Knowledge Articles or markdown
            const markdownContent = await this.getDocumentContent(documentName);

            // Generate PDF using existing CVMADocumentSharingController
            const contentDocumentId = await generateTrainingPDF({
                documentName: documentName,
                markdownContent: markdownContent,
                targetAudience: 'CEB_Officers'
            });

            // Open the generated PDF
            this.openContentDocument(contentDocumentId);

            this.showToast('Success', `${documentName} opened successfully`, 'success');

        } catch (error) {
            console.error('Error opening training document:', error);
            this.showToast('Error', 'Failed to open training document', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Get document content (integrate with Knowledge Articles)
    async getDocumentContent(documentName) {
        // Mock content - in real implementation, this would query Knowledge Articles
        const mockContent = `# ${documentName}

## Combat Veterans Motorcycle Association
### Chapter 20-7 - Jacksonville, FL

This training document provides comprehensive guidance for CEB officers on ${documentName.toLowerCase()}.

### Key Responsibilities
- Daily operations management
- Member support and guidance
- Chapter compliance and reporting

### Emergency Procedures
For immediate assistance, contact the Chapter Commander or visit the emergency procedures section.

---
**🏍️ Vets Serving Vets**`;

        return mockContent;
    }

    // Open content document in new tab
    openContentDocument(contentDocumentId) {
        const baseUrl = window.location.origin;
        const documentUrl = `${baseUrl}/sfc/servlet.shepherd/document/download/${contentDocumentId}`;
        window.open(documentUrl, '_blank');
    }

    // Search functionality
    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();

        if (searchTerm) {
            this.trainingModules = this.cebTrainingModules.filter(module =>
                module.title.toLowerCase().includes(searchTerm) ||
                module.description.toLowerCase().includes(searchTerm) ||
                module.category.toLowerCase().includes(searchTerm)
            );
        } else {
            this.trainingModules = this.cebTrainingModules;
        }
    }

    // Get module by category for organized display
    get operationsModules() {
        return this.trainingModules.filter(module => module.category === 'Daily Operations');
    }

    get memberServiceModules() {
        return this.trainingModules.filter(module => module.category === 'Member Services');
    }

    get financialModules() {
        return this.trainingModules.filter(module => module.category === 'Financial Management');
    }

    get eventModules() {
        return this.trainingModules.filter(module => module.category === 'Event Management');
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
}
