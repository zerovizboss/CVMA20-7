import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import MILITARY_AWARDS_CSS from '@salesforce/resourceUrl/cvmaMilitaryAwardsCSS';

/**
 * CVMA Crisis Support Component - SLDS Compliant
 * Focused component for veteran crisis support and emergency contacts
 * Follows Lightning Design System patterns with military awards styling
 * Priority: Emergency support for veteran welfare
 */
export default class CvmaCrisisSupport extends LightningElement {
    @api cardTitle = 'Crisis Support';
    @api showPhoneNumbers = false;
    @api showTextSupport = false;
    @api showChatSupport = false;
    @api showChapterContact = false;

    connectedCallback() {
        this.loadMilitaryAwardsCSS();
    }

    async loadMilitaryAwardsCSS() {
        try {
            await loadStyle(this, MILITARY_AWARDS_CSS);
        } catch (error) {
            console.error('Error loading Military Awards CSS:', error);
        }
    }

    // Emergency contact handlers
    handleCrisisLineCall() {
        // Direct dial Veterans Crisis Line
        window.open('tel:1-800-273-8255', '_self');
        this.dispatchAnalyticsEvent('Crisis Line Called');

        this.showToast(
            'Crisis Support',
            'Connecting to Veterans Crisis Line - You are not alone',
            'info'
        );
    }

    handleCrisisLineText() {
        // Text Veterans Crisis Line
        window.open('sms:838255', '_self');
        this.dispatchAnalyticsEvent('Crisis Text Initiated');

        this.showToast(
            'Text Support',
            'Text message to 838255 initiated - Help is on the way',
            'info'
        );
    }

    handleCrisisChat() {
        // Open Veterans Crisis Line chat in new tab
        window.open('https://www.veteranscrisisline.net/get-help/chat', '_blank');
        this.dispatchAnalyticsEvent('Crisis Chat Opened');

        this.showToast(
            'Online Support',
            'Opening crisis chat - Confidential help available',
            'info'
        );
    }

    handleChapterEmergency() {
        // Dispatch event for chapter emergency contact
        this.dispatchEvent(new CustomEvent('chapteremergency', {
            detail: {
                type: 'emergency_contact',
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));

        this.dispatchAnalyticsEvent('Chapter Emergency Contact');

        this.showToast(
            'Chapter Support',
            'Connecting you with Chapter emergency support...',
            'info'
        );
    }

    // Analytics event dispatcher
    dispatchAnalyticsEvent(action) {
        this.dispatchEvent(new CustomEvent('crisisanalytics', {
            detail: {
                component: 'cvmaCrisisSupport',
                action: action,
                timestamp: new Date().toISOString()
            },
            bubbles: true
        }));
    }

    // Utility toast method
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
        console.error('CVMA Crisis Support Error:', error);
        this.showToast(
            'Crisis Support Error',
            'If you need immediate help, please call 911 or 1-800-273-8255',
            'error'
        );
    }
}
