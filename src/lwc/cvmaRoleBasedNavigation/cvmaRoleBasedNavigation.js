import { LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import USER_TYPE from '@salesforce/schema/User.UserType';

/**
 * CVMA Role-Based Navigation Component
 * Single-Site Architecture with Dynamic User Experience
 * Optimizes navigation for different user audiences
 */
export default class CvmaRoleBasedNavigation extends LightningElement {
    userId = Id;
    @track userRole = 'Guest';
    @track isOfficer = false;
    @track isMember = false;
    @track showQuickActions = false;
    @track navigationItems = [];

    // Wire user data
    @wire(getRecord, {
        recordId: '$userId',
        fields: [PROFILE_NAME, USER_TYPE]
    })
    wiredUser({ error, data }) {
        if (data) {
            this.determineUserRole(data);
            this.buildNavigationMenu();
        } else if (error) {
            console.error('Error loading user data:', error);
            this.userRole = 'Guest';
            this.buildNavigationMenu();
        }
    }

    // Determine user role and permissions
    determineUserRole(userData) {
        const profileName = getFieldValue(userData, PROFILE_NAME);
        const userType = getFieldValue(userData, USER_TYPE);

        // Role determination logic
        if (profileName && profileName.includes('System Administrator')) {
            this.userRole = 'System Admin';
            this.isOfficer = true;
            this.isMember = true;
        } else if (profileName && profileName.includes('CEB')) {
            this.userRole = 'CEB Officer';
            this.isOfficer = true;
            this.isMember = true;
        } else if (userType === 'Standard' || profileName.includes('CVMA')) {
            this.userRole = 'CVMA Member';
            this.isMember = true;
        } else {
            this.userRole = 'Guest';
        }

        this.showQuickActions = this.isMember;
    }

    // Build dynamic navigation menu based on user role
    buildNavigationMenu() {
        this.navigationItems = [];

        // Home - Available to all users
        this.navigationItems.push({
            id: 'home',
            label: 'Home',
            url: '/s/',
            icon: 'utility:home',
            buttonClass: 'cvma-btn-national-defense',
            visible: true,
            description: 'CVMA Chapter 20-7 Home'
        });

        // Member Portal - Members only
        if (this.isMember) {
            this.navigationItems.push({
                id: 'member-portal',
                label: 'Member Portal',
                url: '/s/member-portal',
                icon: 'utility:groups',
                buttonClass: 'cvma-btn-bronze-star',
                visible: true,
                description: 'Member profiles, events, and resources'
            });
        }

        // Officer Dashboard - Officers only
        if (this.isOfficer) {
            this.navigationItems.push({
                id: 'officer-dashboard',
                label: 'Officer Dashboard',
                url: '/s/ceb-training',
                icon: 'utility:strategy',
                buttonClass: 'cvma-btn-officer-commendation',
                visible: true,
                description: 'CEB training and administrative tools'
            });
        }

        // Training & Resources - Role-based content
        this.navigationItems.push({
            id: 'training',
            label: 'Training Center',
            url: '/s/training',
            icon: 'utility:education',
            buttonClass: 'cvma-btn-combat-action',
            visible: true,
            description: this.isMember ? 'Member training and resources' : 'Public training resources'
        });

        // Veterans Resources - Available to all
        this.navigationItems.push({
            id: 'veteran-resources',
            label: 'Veteran Resources',
            url: '/s/veteran-resources',
            icon: 'utility:priority',
            buttonClass: 'cvma-btn-purple-heart',
            visible: true,
            description: 'VA services, benefits, and support'
        });

        // Knowledge Base - Available to all
        this.navigationItems.push({
            id: 'knowledge',
            label: 'Knowledge Base',
            url: '/s/knowledge',
            icon: 'utility:knowledge_base',
            buttonClass: 'cvma-btn-gwot',
            visible: true,
            description: 'Articles, documentation, and support'
        });

        // Analytics - Officers and Admins only
        if (this.isOfficer || this.userRole === 'System Admin') {
            this.navigationItems.push({
                id: 'analytics',
                label: 'Analytics',
                url: '/s/analytics',
                icon: 'utility:chart',
                buttonClass: 'cvma-btn-meritorious-service',
                visible: true,
                description: 'Chapter performance and member engagement'
            });
        }
    }

    // Navigation click handlers
    handleNavigation(event) {
        const itemId = event.currentTarget.dataset.id;
        const item = this.navigationItems.find(nav => nav.id === itemId);

        if (item && item.url) {
            // Use Lightning Navigation for SPA routing
            window.location.href = item.url;
        }
    }

    // Quick action handlers for common tasks
    handleQuickAction(event) {
        const action = event.currentTarget.dataset.action;

        switch(action) {
            case 'create-event':
                this.navigateToEventCreation();
                break;
            case 'view-profile':
                this.navigateToProfile();
                break;
            case 'crisis-support':
                this.openCrisisSupport();
                break;
            case 'contact-chapter':
                this.openChapterContact();
                break;
        }
    }

    // Navigation helper methods
    navigateToEventCreation() {
        window.location.href = '/s/event-management?action=create';
    }

    navigateToProfile() {
        window.location.href = '/s/member-profile';
    }

    openCrisisSupport() {
        // Open crisis support modal or redirect
        window.open('tel:1-800-273-8255', '_self');
    }

    openChapterContact() {
        window.location.href = '/s/contact';
    }

    // Getters for template conditionals
    get isGuest() {
        return this.userRole === 'Guest';
    }

    get isSystemAdmin() {
        return this.userRole === 'System Admin';
    }

    get showOfficerItems() {
        return this.isOfficer;
    }

    get showMemberItems() {
        return this.isMember;
    }

    get userRoleLabel() {
        return this.userRole;
    }

    get welcomeMessage() {
        if (this.isGuest) {
            return 'Welcome to CVMA Chapter 20-7';
        }
        return `Welcome, ${this.userRole}`;
    }
}
