import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Member Training Portal - Optimized for Main Member Site
 * Purpose: Self-service training interface for CVMA Chapter 20-7 members
 * Site: https://cvma20-7-dev-ed.develop.my.site.com
 */
export default class CvmaMemberTrainingPortal extends LightningElement {
    @api displayMode = 'full'; // full, compact, mobile
    @track selectedPath = '';
    @track currentStep = 0;

    // Member-focused learning paths
    memberLearningPaths = [
        {
            id: 'getting-started',
            title: 'Getting Started with CVMA Platform',
            description: 'Essential platform navigation and basic features for new members',
            icon: 'standard:setup_assistant_guide',
            level: 'Beginner',
            estimatedTime: '20 min',
            steps: [
                'Platform Overview',
                'Account Setup',
                'Navigation Basics',
                'Contact Information'
            ],
            color: 'success'
        },
        {
            id: 'self-service',
            title: 'Self-Service Member Tools',
            description: 'Manage your membership, update information, and access resources independently',
            icon: 'standard:record_update',
            level: 'Intermediate',
            estimatedTime: '25 min',
            steps: [
                'Profile Management',
                'Dues and Payments',
                'Document Upload',
                'Membership Services'
            ],
            color: 'brand'
        },
        {
            id: 'community-engagement',
            title: 'Community Engagement',
            description: 'Connect with fellow veterans, participate in events, and build community',
            icon: 'standard:groups',
            level: 'All Levels',
            estimatedTime: '15 min',
            steps: [
                'Member Directory',
                'Event Participation',
                'Communication Tools',
                'Community Guidelines'
            ],
            color: 'warning'
        },
        {
            id: 'accessibility',
            title: 'Accessibility Features',
            description: 'Learn about accessibility features and accommodations available',
            icon: 'standard:connected_apps',
            level: 'All Levels',
            estimatedTime: '10 min',
            steps: [
                'Accessibility Overview',
                'Screen Reader Support',
                'Keyboard Navigation',
                'Request Accommodations'
            ],
            color: 'info'
        }
    ];

    // Quick help topics for immediate assistance
    quickHelpTopics = [
        {
            id: 'password-reset',
            title: 'Reset Your Password',
            icon: 'standard:password',
            description: 'Step-by-step password reset instructions'
        },
        {
            id: 'update-contact',
            title: 'Update Contact Info',
            icon: 'standard:contact',
            description: 'How to update your contact information'
        },
        {
            id: 'event-rsvp',
            title: 'RSVP for Events',
            icon: 'standard:event',
            description: 'How to respond to event invitations'
        },
        {
            id: 'membership-status',
            title: 'Check Membership Status',
            icon: 'standard:record',
            description: 'View your current membership information'
        }
    ];

    connectedCallback() {
        // Set default path based on user profile or preferences
        this.initializeUserPath();
    }

    initializeUserPath() {
        // Logic to determine appropriate starting path based on user experience
        // This could integrate with user metadata or preference settings
        this.selectedPath = 'getting-started';
    }

    // Handle learning path selection
    handlePathSelect(event) {
        const pathId = event.currentTarget.dataset.pathId;
        this.selectedPath = pathId;
        this.currentStep = 0;

        // Track learning path selection for analytics
        this.dispatchEvent(new CustomEvent('pathselected', {
            detail: {
                pathId: pathId,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));

        this.showToast('Success', `Started learning path: ${this.getPathTitle(pathId)}`, 'success');
    }

    // Handle quick help selection
    handleQuickHelp(event) {
        const helpId = event.currentTarget.dataset.helpId;

        // Open help content or navigate to specific help page
        this.dispatchEvent(new CustomEvent('quickhelp', {
            detail: {
                helpId: helpId,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));
    }

    // Progress through learning path steps
    handleStepProgress(event) {
        const direction = event.currentTarget.dataset.direction;
        const selectedPathData = this.memberLearningPaths.find(path => path.id === this.selectedPath);

        if (direction === 'next' && this.currentStep < selectedPathData.steps.length - 1) {
            this.currentStep++;
        } else if (direction === 'previous' && this.currentStep > 0) {
            this.currentStep--;
        }

        // Track progress for completion analytics
        this.trackProgress();
    }

    // Track user progress through training
    trackProgress() {
        const progressData = {
            pathId: this.selectedPath,
            currentStep: this.currentStep,
            timestamp: new Date().toISOString()
        };

        // Dispatch event for progress tracking
        this.dispatchEvent(new CustomEvent('progressupdate', {
            detail: progressData,
            bubbles: true
        }));
    }

    // Get path title by ID
    getPathTitle(pathId) {
        const path = this.memberLearningPaths.find(p => p.id === pathId);
        return path ? path.title : '';
    }

    // Search functionality for training content
    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();

        // Implement search logic here
        // This could search through training content, help topics, etc.
        console.log('Searching for:', searchTerm);
    }

    // Computed properties
    get selectedPathData() {
        return this.memberLearningPaths.find(path => path.id === this.selectedPath);
    }

    get currentStepTitle() {
        if (this.selectedPathData && this.selectedPathData.steps[this.currentStep]) {
            return this.selectedPathData.steps[this.currentStep];
        }
        return '';
    }

    get progressPercentage() {
        if (this.selectedPathData) {
            return Math.round(((this.currentStep + 1) / this.selectedPathData.steps.length) * 100);
        }
        return 0;
    }

    get isFirstStep() {
        return this.currentStep === 0;
    }

    get isLastStep() {
        return this.selectedPathData && this.currentStep === this.selectedPathData.steps.length - 1;
    }

    get hasSelectedPath() {
        return this.selectedPath !== '';
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
