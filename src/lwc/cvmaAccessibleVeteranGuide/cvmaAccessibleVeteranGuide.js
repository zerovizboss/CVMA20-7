import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * CVMA Accessible Veteran Guide Component
 * 508-Compliant veteran assistance system with PTSD-friendly design
 * Designed for Chapter 20-7 veterans with accessibility needs
 */
export default class CvmaAccessibleVeteranGuide extends LightningElement {
    @api guidanceMode = 'landing'; // landing, guided, emergency
    @api enableVoiceNavigation = false;
    @api highContrastMode = false;
    @api reducedMotion = false;
    @api largeTextMode = false;

    @track currentStep = 1;
    @track totalSteps = 3;
    @track selectedResourceType = '';
    @track isVoiceActive = false;
    @track accessibilitySettings = {
        screenReaderActive: false,
        keyboardNavigation: true,
        highContrast: false,
        largeText: false,
        reducedMotion: false
    };

    // Emergency crisis resources - always accessible without authentication
    emergencyResources = [
        {
            id: 'crisis-lifeline',
            name: 'Crisis Lifeline',
            number: '988',
            description: 'National Suicide Prevention Lifeline - 24/7 support',
            iconClass: 'emergency-icon',
            type: 'phone'
        },
        {
            id: 'veterans-crisis',
            name: 'Veterans Crisis Line',
            number: '1-800-273-8255',
            description: 'Press 1 for Veterans Crisis Line - specialized support',
            iconClass: 'veteran-icon',
            type: 'phone'
        },
        {
            id: 'text-support',
            name: 'Crisis Text Line',
            number: '838255',
            description: 'Text HOME to 838255 for crisis support',
            iconClass: 'text-icon',
            type: 'text'
        },
        {
            id: 'chat-support',
            name: 'Online Chat',
            url: 'https://www.veteranscrisisline.net/get-help/chat',
            description: 'Start confidential online chat',
            iconClass: 'chat-icon',
            type: 'web'
        }
    ];

    // Veteran resource categories with accessibility metadata
    resourceCategories = [
        {
            id: 'va-benefits',
            title: 'VA Benefits',
            description: 'Disability, healthcare, education benefits',
            steps: ['Check eligibility', 'Gather documents', 'Apply online'],
            estimatedTime: '15-30 minutes',
            difficulty: 'Easy',
            accessibilitySupport: true,
            iconName: 'standard:opportunity'
        },
        {
            id: 'housing-support',
            title: 'Housing Assistance',
            description: 'Emergency housing and home loans',
            steps: ['Find local programs', 'Complete application', 'Schedule interview'],
            estimatedTime: '45-60 minutes',
            difficulty: 'Medium',
            accessibilitySupport: true,
            iconName: 'standard:home'
        },
        {
            id: 'mental-health',
            title: 'Mental Health Support',
            description: 'PTSD counseling and peer support',
            steps: ['Crisis assessment', 'Find providers', 'Schedule appointment'],
            estimatedTime: 'Immediate - 24 hours',
            difficulty: 'Easy',
            accessibilitySupport: true,
            iconName: 'standard:person_account'
        },
        {
            id: 'financial-aid',
            title: 'Financial Assistance',
            description: 'Emergency funds and financial counseling',
            steps: ['Document expenses', 'Apply for aid', 'Budget planning'],
            estimatedTime: '30-45 minutes',
            difficulty: 'Medium',
            accessibilitySupport: true,
            iconName: 'standard:currency'
        }
    ];

    connectedCallback() {
        // Add computed IDs for aria-describedby attributes
        this.resourceCategories = this.resourceCategories.map(cat => ({
            ...cat,
            descId: `${cat.id}-desc`
        }));

        this.emergencyResources = this.emergencyResources.map(res => ({
            ...res,
            helpId: `${res.id}-help`
        }));

        this.detectAccessibilityNeeds();
        this.setupKeyboardNavigation();
        this.checkVoiceSupport();
    }

    // Accessibility detection and setup
    detectAccessibilityNeeds() {
        // Detect screen reader
        this.accessibilitySettings.screenReaderActive = window.navigator.userAgent.includes('NVDA') ||
                                                      window.navigator.userAgent.includes('JAWS') ||
                                                      window.speechSynthesis !== undefined;

        // Detect reduced motion preference
        if (window.matchMedia) {
            const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
            this.accessibilitySettings.reducedMotion = prefersReducedMotion.matches;
            this.reducedMotion = prefersReducedMotion.matches;
        }

        // Detect high contrast preference
        if (window.matchMedia) {
            const prefersHighContrast = window.matchMedia('(prefers-contrast: high)');
            this.accessibilitySettings.highContrast = prefersHighContrast.matches;
            this.highContrastMode = prefersHighContrast.matches;
        }

        // Apply accessibility settings
        this.applyAccessibilitySettings();
    }

    setupKeyboardNavigation() {
        // Set up keyboard event listeners for navigation
        this.template.addEventListener('keydown', this.handleKeyNavigation.bind(this));
    }

    checkVoiceSupport() {
        // Check if speech synthesis is available
        if ('speechSynthesis' in window && 'webkitSpeechRecognition' in window) {
            this.enableVoiceNavigation = true;
        }
    }

    // Event handlers for guided workflow
    handleResourceSelection(event) {
        this.selectedResourceType = event.currentTarget.dataset.resource;
        this.currentStep = 2;
        this.announceToScreenReader(`Selected ${this.selectedResourceType}. Moving to step 2 of 3.`);
        this.focusNextElement();
    }

    handleNextStep() {
        if (this.currentStep < this.totalSteps) {
            this.currentStep++;
            this.announceToScreenReader(`Moving to step ${this.currentStep} of ${this.totalSteps}`);
            this.focusNextElement();
        }
    }

    handlePreviousStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.announceToScreenReader(`Going back to step ${this.currentStep} of ${this.totalSteps}`);
            this.focusNextElement();
        }
    }

    handleEmergencyAccess(event) {
        const resource = event.currentTarget.dataset.resource;
        const emergencyResource = this.emergencyResources.find(r => r.id === resource);

        if (emergencyResource.type === 'phone') {
            window.open(`tel:${emergencyResource.number}`, '_self');
            this.announceToScreenReader(`Calling ${emergencyResource.name} at ${emergencyResource.number}`);
        } else if (emergencyResource.type === 'text') {
            // Open messaging app with pre-filled text
            window.open(`sms:${emergencyResource.number}?body=HOME`, '_self');
            this.announceToScreenReader(`Opening text message to ${emergencyResource.number}`);
        } else if (emergencyResource.type === 'web') {
            window.open(emergencyResource.url, '_blank', 'noopener,noreferrer');
            this.announceToScreenReader(`Opening ${emergencyResource.name} in new window`);
        }
    }

    // Accessibility control handlers
    handleAccessibilityToggle(event) {
        const setting = event.currentTarget.dataset.setting;

        switch(setting) {
            case 'highContrast':
                this.highContrastMode = !this.highContrastMode;
                this.accessibilitySettings.highContrast = this.highContrastMode;
                break;
            case 'largeText':
                this.largeTextMode = !this.largeTextMode;
                this.accessibilitySettings.largeText = this.largeTextMode;
                break;
            case 'reducedMotion':
                this.reducedMotion = !this.reducedMotion;
                this.accessibilitySettings.reducedMotion = this.reducedMotion;
                break;
            case 'voiceNavigation':
                this.toggleVoiceNavigation();
                break;
        }

        this.applyAccessibilitySettings();
        this.announceToScreenReader(`${setting} ${this[setting] ? 'enabled' : 'disabled'}`);
    }

    // Voice navigation
    toggleVoiceNavigation() {
        if (this.enableVoiceNavigation) {
            this.isVoiceActive = !this.isVoiceActive;
            if (this.isVoiceActive) {
                this.startVoiceRecognition();
            } else {
                this.stopVoiceRecognition();
            }
        }
    }

    startVoiceRecognition() {
        if ('webkitSpeechRecognition' in window) {
            const recognition = new webkitSpeechRecognition();
            recognition.continuous = true;
            recognition.interimResults = false;
            recognition.lang = 'en-US';

            recognition.onresult = (event) => {
                const command = event.results[event.results.length - 1][0].transcript.toLowerCase();
                this.processVoiceCommand(command);
            };

            recognition.start();
            this.announceToScreenReader('Voice navigation activated. Say commands like "next step", "previous step", "emergency help", or "VA benefits"');
        }
    }

    processVoiceCommand(command) {
        if (command.includes('next') || command.includes('continue')) {
            this.handleNextStep();
        } else if (command.includes('back') || command.includes('previous')) {
            this.handlePreviousStep();
        } else if (command.includes('emergency') || command.includes('crisis')) {
            this.guidanceMode = 'emergency';
            this.announceToScreenReader('Activating emergency resources');
        } else if (command.includes('va') || command.includes('benefits')) {
            this.selectedResourceType = 'va-benefits';
            this.handleResourceSelection({currentTarget: {dataset: {resource: 'va-benefits'}}});
        } else if (command.includes('housing')) {
            this.selectedResourceType = 'housing-support';
            this.handleResourceSelection({currentTarget: {dataset: {resource: 'housing-support'}}});
        } else if (command.includes('mental health') || command.includes('counseling')) {
            this.selectedResourceType = 'mental-health';
            this.handleResourceSelection({currentTarget: {dataset: {resource: 'mental-health'}}});
        }
    }

    // Keyboard navigation
    handleKeyNavigation(event) {
        const focusableElements = this.template.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        const focusedIndex = Array.from(focusableElements).indexOf(document.activeElement);

        switch(event.key) {
            case 'ArrowRight':
            case 'Tab':
                if (!event.shiftKey) {
                    event.preventDefault();
                    const nextIndex = (focusedIndex + 1) % focusableElements.length;
                    focusableElements[nextIndex].focus();
                }
                break;
            case 'ArrowLeft':
                if (event.shiftKey && event.key === 'Tab') {
                    event.preventDefault();
                    const prevIndex = focusedIndex === 0 ? focusableElements.length - 1 : focusedIndex - 1;
                    focusableElements[prevIndex].focus();
                }
                break;
            case 'Enter':
            case ' ':
                if (document.activeElement.tagName === 'BUTTON') {
                    event.preventDefault();
                    document.activeElement.click();
                }
                break;
            case 'Escape':
                if (this.guidanceMode === 'emergency') {
                    this.guidanceMode = 'landing';
                    this.announceToScreenReader('Exited emergency mode');
                }
                break;
        }
    }

    // Accessibility utility methods
    applyAccessibilitySettings() {
        const container = this.template.querySelector('.veteran-guide-container');
        if (container) {
            // Apply high contrast
            container.classList.toggle('high-contrast', this.highContrastMode);

            // Apply large text
            container.classList.toggle('large-text', this.largeTextMode);

            // Apply reduced motion
            container.classList.toggle('reduced-motion', this.reducedMotion);
        }
    }

    announceToScreenReader(message) {
        if (this.accessibilitySettings.screenReaderActive) {
            // Create temporary element for screen reader announcement
            const announcement = document.createElement('div');
            announcement.setAttribute('aria-live', 'polite');
            announcement.setAttribute('aria-atomic', 'true');
            announcement.classList.add('sr-only');
            announcement.textContent = message;

            this.template.appendChild(announcement);

            // Remove after announcement
            setTimeout(() => {
                if (announcement.parentNode) {
                    announcement.parentNode.removeChild(announcement);
                }
            }, 1000);
        }
    }

    focusNextElement() {
        // Focus management for seamless navigation
        setTimeout(() => {
            const nextFocusable = this.template.querySelector('[data-focus-target="true"]') ||
                                this.template.querySelector('.step-content button') ||
                                this.template.querySelector('button');
            if (nextFocusable) {
                nextFocusable.focus();
            }
        }, 100);
    }

    // Getters for template rendering
    get isLandingMode() {
        return this.guidanceMode === 'landing';
    }

    get isGuidedMode() {
        return this.guidanceMode === 'guided';
    }

    get isEmergencyMode() {
        return this.guidanceMode === 'emergency';
    }

    get isStep1() {
        return this.currentStep === 1;
    }

    get isStep2() {
        return this.currentStep === 2;
    }

    get isStep3() {
        return this.currentStep === 3;
    }

    get isFirstStep() {
        return this.currentStep === 1;
    }

    get isLastStep() {
        return this.currentStep === this.totalSteps;
    }

    get selectedCategory() {
        return this.resourceCategories.find(cat => cat.id === this.selectedResourceType);
    }

    get progressPercentage() {
        return (this.currentStep / this.totalSteps) * 100;
    }

    get progressBarStyle() {
        return `width: ${this.progressPercentage}%`;
    }

    get containerClass() {
        let classes = 'veteran-guide-container';
        if (this.highContrastMode) classes += ' high-contrast';
        if (this.largeTextMode) classes += ' large-text';
        if (this.reducedMotion) classes += ' reduced-motion';
        return classes;
    }

    get accessibilityControlsClass() {
        return 'accessibility-controls' + (this.accessibilitySettings.screenReaderActive ? ' screen-reader-active' : '');
    }

    get isVABenefitsSelected() {
        return this.selectedResourceType === 'va-benefits';
    }

    get isMentalHealthSelected() {
        return this.selectedResourceType === 'mental-health';
    }
}
