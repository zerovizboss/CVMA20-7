import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCEBTrainingDocuments from '@salesforce/apex/CVMADocumentSharingController.getCEBTrainingDocuments';

/**
 * CEB Training Hub - Optimized for CEB Site Experience
 * Purpose: Task-oriented training interface for Chapter Executive Board Officers
 * Site: https://cvma20-7-dev-ed.develop.my.site.com/ceb
 */
export default class CvmaCebTrainingHub extends LightningElement {
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

    // Open training document
    openTrainingDocument(documentName) {
        // Integration with PDF generation
        this.dispatchEvent(new CustomEvent('opendocument', {
            detail: {
                documentName: documentName,
                targetAudience: 'CEB_Officers'
            },
            bubbles: true
        }));
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
