import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import IS_GUEST from '@salesforce/user/isGuest';

export default class CvmaInAppGuidance extends LightningElement {
    @api guidanceContext = 'veteran-resources';
    @api showOnFirstVisit;
    @api enableVoiceCommands;
    @api highContrastMode = false;
    @api reducedMotion = false;

    @track currentStep = 1;
    @track totalSteps = 4;
    @track isVisible = false;
    @track isMinimized = false;
    @track userPreferences = {
        hasCompletedTour: false,
        prefersAudio: false,
        prefersHighContrast: false,
        prefersReducedMotion: false,
        lastVisited: null
    };
    @track voiceSupported = false;
    @track speechSynthesis = null;
    @track recognition = null;

    guidanceSteps = {
        'veteran-resources': [
            {
                step: 1,
                title: 'Welcome to Veteran Resources',
                content: 'This portal provides access to 50+ veteran service organizations and VA benefits. You can browse anonymously or log in for personalized recommendations.',
                audioText: 'Welcome to the Veteran Resources portal. This page helps you find support from fifty plus veteran organizations and VA benefits. You can browse without logging in, or sign in for personal recommendations.',
                focusElement: '.veteran-resource-finder',
                nextLabel: 'Show Me How to Search',
                emergency: false
            },
            {
                step: 2,
                title: 'Finding the Right Resources',
                content: 'Use the search bar and filters to find organizations by service type, location, or specific needs. Categories include housing, employment, mental health, and emergency assistance.',
                audioText: 'To find the right resources, use the search box and filters to look for organizations by service type, location, or your specific needs. We have categories for housing, jobs, mental health, and emergency help.',
                focusElement: '.search-input',
                nextLabel: 'How to Check Eligibility',
                emergency: false
            },
            {
                step: 3,
                title: 'Checking Your Eligibility',
                content: 'Click "Check Eligibility" on any organization to see if you qualify for their programs. This feature provides instant assessment based on your service history.',
                audioText: 'Click check eligibility on any organization to see if you qualify for their programs. This gives you instant results based on your military service.',
                focusElement: '.action-button[variant="brand"]',
                nextLabel: 'Emergency Resources',
                emergency: false
            },
            {
                step: 4,
                title: 'Emergency Support Always Available',
                content: 'Need immediate help? Crisis support is always accessible. Call 988 for the Crisis Lifeline or text 838255. These resources are available 24/7.',
                audioText: 'If you need immediate help, crisis support is always available. Call nine eight eight for the Crisis Lifeline, or text eight three eight two five five. These resources are available twenty four seven.',
                focusElement: '.emergency-resources',
                nextLabel: 'Complete Tour',
                emergency: true
            }
        ],
        'va-services': [
            {
                step: 1,
                title: 'VA Services Integration',
                content: 'Access real VA forms, find nearby facilities, and validate your address for accurate VA correspondence.',
                audioText: 'Access real VA forms, find nearby VA facilities, and check your address for accurate VA mail.',
                focusElement: '.va-services-integration',
                nextLabel: 'Continue',
                emergency: false
            }
        ]
    };

    connectedCallback() {
        this.initializeAccessibility();
        this.loadUserPreferences();
        this.checkFirstVisit();
        this.setupVoiceCommands();
    }

    initializeAccessibility() {
        // Detect user's accessibility preferences
        if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            this.reducedMotion = true;
        }

        if (window.matchMedia && window.matchMedia('(prefers-contrast: high)').matches) {
            this.highContrastMode = true;
        }

        // Check for screen reader
        this.detectScreenReader();
    }

    detectScreenReader() {
        // Create a visually hidden element to test for screen reader
        const testElement = document.createElement('div');
        testElement.setAttribute('aria-live', 'polite');
        testElement.setAttribute('aria-atomic', 'true');
        testElement.style.position = 'absolute';
        testElement.style.left = '-10000px';
        testElement.style.width = '1px';
        testElement.style.height = '1px';
        testElement.style.overflow = 'hidden';
        testElement.textContent = 'Screen reader test';

        document.body.appendChild(testElement);

        setTimeout(() => {
            if (testElement.offsetHeight !== 0 || testElement.offsetWidth !== 0) {
                this.userPreferences.prefersAudio = true;
            }
            document.body.removeChild(testElement);
        }, 100);
    }

    loadUserPreferences() {
        try {
            const stored = localStorage.getItem('cvma-guidance-preferences');
            if (stored) {
                this.userPreferences = { ...this.userPreferences, ...JSON.parse(stored) };
            }
        } catch (error) {
            console.warn('Could not load user preferences:', error);
        }
    }

    saveUserPreferences() {
        try {
            localStorage.setItem('cvma-guidance-preferences', JSON.stringify(this.userPreferences));
        } catch (error) {
            console.warn('Could not save user preferences:', error);
        }
    }

    checkFirstVisit() {
        const now = new Date().toISOString();

        if (this.showOnFirstVisit && !this.userPreferences.hasCompletedTour) {
            // Show guidance on first visit
            setTimeout(() => {
                this.startGuidance();
            }, 2000); // Delay to let page load
        }

        this.userPreferences.lastVisited = now;
        this.saveUserPreferences();
    }

    setupVoiceCommands() {
        if (!this.enableVoiceCommands || !('webkitSpeechRecognition' in window || 'SpeechRecognition' in window)) {
            return;
        }

        try {
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            this.recognition = new SpeechRecognition();
            this.recognition.continuous = false;
            this.recognition.interimResults = false;
            this.recognition.lang = 'en-US';

            this.recognition.onresult = (event) => {
                const command = event.results[0][0].transcript.toLowerCase();
                this.processVoiceCommand(command);
            };

            this.recognition.onerror = (event) => {
                console.warn('Voice recognition error:', event.error);
            };

            this.voiceSupported = true;
        } catch (error) {
            console.warn('Voice commands not supported:', error);
        }

        // Setup speech synthesis
        if ('speechSynthesis' in window) {
            this.speechSynthesis = window.speechSynthesis;
        }
    }

    processVoiceCommand(command) {
        const commands = {
            'help': () => this.startGuidance(),
            'start tour': () => this.startGuidance(),
            'next step': () => this.nextStep(),
            'previous step': () => this.previousStep(),
            'close help': () => this.closeGuidance(),
            'emergency help': () => this.showEmergencyHelp(),
            'crisis support': () => this.showEmergencyHelp(),
            'read this': () => this.readCurrentStep(),
            'repeat': () => this.readCurrentStep()
        };

        for (const [phrase, action] of Object.entries(commands)) {
            if (command.includes(phrase)) {
                action();
                break;
            }
        }
    }

    @api startGuidance() {
        this.currentStep = 1;
        this.isVisible = true;
        this.isMinimized = false;

        // Focus management for accessibility
        setTimeout(() => {
            const guidanceElement = this.template.querySelector('.guidance-modal');
            if (guidanceElement) {
                guidanceElement.focus();
            }
        }, 100);

        this.announceToScreenReader('Guidance tour started. Use arrow keys to navigate or say voice commands.');

        if (this.userPreferences.prefersAudio) {
            this.readCurrentStep();
        }
    }

    nextStep() {
        if (this.currentStep < this.totalSteps) {
            this.currentStep++;
            this.highlightCurrentElement();

            if (this.userPreferences.prefersAudio) {
                this.readCurrentStep();
            }
        } else {
            this.completeGuidance();
        }
    }

    previousStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.highlightCurrentElement();

            if (this.userPreferences.prefersAudio) {
                this.readCurrentStep();
            }
        }
    }

    completeGuidance() {
        this.userPreferences.hasCompletedTour = true;
        this.saveUserPreferences();
        this.closeGuidance();

        this.showToast('Tour Complete', 'You can restart this tour anytime by clicking the help icon or saying "help".', 'success');
        this.announceToScreenReader('Guidance tour completed. You can restart the tour anytime by clicking the help icon.');
    }

    closeGuidance() {
        this.isVisible = false;
        this.clearHighlights();

        // Return focus to main content
        const mainContent = document.querySelector('main') || document.querySelector('.slds-scope');
        if (mainContent) {
            mainContent.focus();
        }
    }

    minimizeGuidance() {
        this.isMinimized = true;
    }

    maximizeGuidance() {
        this.isMinimized = false;
    }

    highlightCurrentElement() {
        this.clearHighlights();

        const step = this.currentStepData;
        if (step && step.focusElement) {
            const element = document.querySelector(step.focusElement);
            if (element) {
                element.classList.add('cvma-guidance-highlight');
                element.scrollIntoView({ behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'center' });

                // Add ARIA attributes for accessibility
                element.setAttribute('aria-describedby', 'cvma-guidance-current-step');
            }
        }
    }

    clearHighlights() {
        const highlighted = document.querySelectorAll('.cvma-guidance-highlight');
        highlighted.forEach(element => {
            element.classList.remove('cvma-guidance-highlight');
            element.removeAttribute('aria-describedby');
        });
    }

    readCurrentStep() {
        if (!this.speechSynthesis) return;

        const step = this.currentStepData;
        if (step) {
            this.speechSynthesis.cancel(); // Stop any current speech

            const utterance = new SpeechSynthesisUtterance(step.audioText || step.content);
            utterance.rate = 0.9;
            utterance.pitch = 1;
            utterance.volume = 0.8;

            this.speechSynthesis.speak(utterance);
        }
    }

    showEmergencyHelp() {
        const emergencyStep = this.guidanceSteps[this.guidanceContext].find(step => step.emergency);
        if (emergencyStep) {
            this.currentStep = emergencyStep.step;
            this.isVisible = true;
            this.isMinimized = false;
            this.readCurrentStep();
        }
    }

    handleKeyDown(event) {
        if (!this.isVisible) return;

        switch (event.key) {
            case 'Escape':
                this.closeGuidance();
                break;
            case 'ArrowRight':
            case 'ArrowDown':
                event.preventDefault();
                this.nextStep();
                break;
            case 'ArrowLeft':
            case 'ArrowUp':
                event.preventDefault();
                this.previousStep();
                break;
            case 'Home':
                event.preventDefault();
                this.currentStep = 1;
                this.highlightCurrentElement();
                break;
            case 'End':
                event.preventDefault();
                this.currentStep = this.totalSteps;
                this.highlightCurrentElement();
                break;
        }
    }

    startListening() {
        if (this.recognition && this.voiceSupported) {
            try {
                this.recognition.start();
                this.announceToScreenReader('Voice commands activated. Say help, next step, or emergency help.');
            } catch (error) {
                console.warn('Could not start voice recognition:', error);
            }
        }
    }

    toggleAccessibilityPreferences(event) {
        const preference = event.target.dataset.preference;

        switch (preference) {
            case 'audio':
                this.userPreferences.prefersAudio = !this.userPreferences.prefersAudio;
                break;
            case 'contrast':
                this.userPreferences.prefersHighContrast = !this.userPreferences.prefersHighContrast;
                this.highContrastMode = this.userPreferences.prefersHighContrast;
                break;
            case 'motion':
                this.userPreferences.prefersReducedMotion = !this.userPreferences.prefersReducedMotion;
                this.reducedMotion = this.userPreferences.prefersReducedMotion;
                break;
        }

        this.saveUserPreferences();
        this.dispatchEvent(new CustomEvent('accessibilitychange', {
            detail: this.userPreferences
        }));
    }

    announceToScreenReader(message) {
        const announcement = this.template.querySelector('.sr-announcement');
        if (announcement) {
            announcement.textContent = message;
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

    get currentStepData() {
        const steps = this.guidanceSteps[this.guidanceContext] || [];
        return steps.find(step => step.step === this.currentStep);
    }

    get progressPercent() {
        return Math.round((this.currentStep / this.totalSteps) * 100);
    }

    get isFirstStep() {
        return this.currentStep === 1;
    }

    get isLastStep() {
        return this.currentStep === this.totalSteps;
    }

    get guidanceClasses() {
        let classes = 'guidance-modal slds-modal slds-fade-in-open';
        if (this.highContrastMode) classes += ' high-contrast';
        if (this.reducedMotion) classes += ' reduced-motion';
        if (this.isMinimized) classes += ' minimized';
        return classes;
    }

    get voiceCommandsAvailable() {
        return this.voiceSupported && this.enableVoiceCommands;
    }

    get nextButtonLabel() {
        return this.isLastStep ? 'Complete Tour' : (this.currentStepData?.nextLabel || 'Next');
    }

    get nextButtonIcon() {
        return this.isLastStep ? 'utility:check' : 'utility:chevronright';
    }
}
