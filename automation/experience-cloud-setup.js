/**
 * CVMA Experience Cloud Training Platform Setup Script
 * Automates the configuration of four Experience Cloud sites for training platform
 *
 * This script provides the configuration metadata for:
 * 1. CEB Officer Training Site
 * 2. Member Training Portal
 * 3. Help Center
 * 4. Technical Documentation Site
 */

const CVMA_EXPERIENCE_CLOUD_CONFIGURATION = {

    // Site 1: CEB Officer Training
    ceb_training: {
        siteName: 'CEB',
        url: 'https://cvma20-7-dev-ed.develop.my.site.com/ceb',
        audience: 'Chapter Executive Board Officers',
        primaryComponent: 'cvmaCebTrainingHub',
        configuration: {
            pageTitle: 'CEB Officer Training Hub',
            componentProperties: {
                displayMode: 'dashboard',
                showQuickActions: true,
                defaultCategory: 'all'
            },
            navigation: {
                primaryTabs: [
                    { label: 'Dashboard', href: '/ceb' },
                    { label: 'Training Modules', href: '/ceb/training' },
                    { label: 'Quick Reference', href: '/ceb/reference' },
                    { label: 'Member Portal', href: '/' }
                ]
            },
            features: [
                'Quick action buttons (Emergency Procedures, Daily Checklist, Member Support)',
                'Training modules by category (Daily Ops, Member Services, Financial, Events)',
                'PDF generation for officer materials',
                'Survey integration for training feedback'
            ]
        }
    },

    // Site 2: Member Training Portal
    member_training: {
        siteName: 'Combat Veterans Motorcycle Association',
        url: 'https://cvma20-7-dev-ed.develop.my.site.com',
        audience: 'CVMA Members',
        primaryComponent: 'cvmaVeteranKnowledgeBase',
        configuration: {
            pageTitle: 'Member Training Portal',
            componentProperties: {
                displayMode: 'article',
                enableSearch: true,
                showCategories: true,
                showFeaturedArticles: true,
                maxSearchResults: 10
            },
            navigation: {
                primaryTabs: [
                    { label: 'Home', href: '/' },
                    { label: 'Training', href: '/training' },
                    { label: 'Resources', href: '/resources' },
                    { label: 'Help Center', href: '/defaulthelpcenter12Jun' },
                    { label: 'Officer Portal', href: '/ceb' }
                ]
            },
            features: [
                'Self-service learning paths',
                'Progress tracking',
                'Veteran resources integration',
                'Survey feedback on articles',
                'Mobile-optimized experience'
            ]
        }
    },

    // Site 3: Help Center
    help_center: {
        siteName: 'Default Help Center',
        url: 'https://cvma20-7-dev-ed.develop.my.site.com/defaulthelpcenter12Jun',
        audience: 'All users seeking support',
        primaryComponent: 'cvmaVeteranKnowledgeBase',
        configuration: {
            pageTitle: 'CVMA Help Center',
            componentProperties: {
                displayMode: 'search',
                enableSearch: true,
                showCategories: false,
                showFeaturedArticles: true,
                maxSearchResults: 15
            },
            navigation: {
                primaryTabs: [
                    { label: 'Search Help', href: '/defaulthelpcenter12Jun' },
                    { label: 'Common Solutions', href: '/defaulthelpcenter12Jun/solutions' },
                    { label: 'Contact Support', href: '/defaulthelpcenter12Jun/contact' },
                    { label: 'Back to Portal', href: '/' }
                ]
            },
            features: [
                'Search-first interface',
                'Quick solutions (password reset, contact support)',
                'Accessibility-optimized',
                'Knowledge article search and feedback'
            ]
        }
    },

    // Site 4: Technical Documentation
    technical_docs: {
        siteName: 'Technical Documentation',
        url: 'https://cvma20-7-dev-ed.develop.my.site.com/technical',
        audience: 'Technical staff and developers',
        primaryComponent: 'cvmaVeteranKnowledgeBase',
        configuration: {
            pageTitle: 'Technical Documentation Hub',
            componentProperties: {
                displayMode: 'category',
                enableSearch: true,
                showCategories: true,
                showFeaturedArticles: false,
                maxSearchResults: 20
            },
            navigation: {
                primaryTabs: [
                    { label: 'Documentation', href: '/technical' },
                    { label: 'API Reference', href: '/technical/api' },
                    { label: 'Code Examples', href: '/technical/examples' },
                    { label: 'Main Portal', href: '/' }
                ]
            },
            features: [
                'Advanced filtering and search',
                'Code examples integration',
                'API documentation',
                'Technical feedback surveys'
            ]
        }
    },

    // Shared Configuration
    shared: {
        branding: {
            primaryColor: '#1B4F72', // CVMA Blue
            secondaryColor: '#D4AF37', // Gold
            logo: '/resource/CVMALogo',
            favicon: '/resource/CVMAFavicon'
        },
        accessibility: {
            wcagCompliance: 'AA',
            features: [
                'Screen reader optimization',
                'Keyboard navigation support',
                'High contrast mode support',
                'Mobile-first responsive design',
                'Alt text for all images',
                'Focus indicators',
                'Skip links'
            ]
        },
        survey_integration: {
            enabled: true,
            types: [
                'Knowledge Article Feedback',
                'Training Module Rating',
                'Site Usability Survey',
                'Content Effectiveness Survey'
            ],
            defaultSurvey: 'Knowledge Article Feedback'
        },
        mobile_optimization: {
            responsive: true,
            pwa_enabled: false,
            touch_optimized: true,
            offline_content: false
        }
    }
};

/**
 * Experience Builder Page Configurations
 * These are the page layouts that need to be created in Experience Builder
 */
const EXPERIENCE_BUILDER_PAGES = {

    // CEB Training Hub Pages
    ceb_dashboard: {
        site: 'CEB',
        pageName: 'Officer Dashboard',
        route: '/',
        template: 'Standard Page',
        components: [
            {
                type: 'cvmaCebTrainingHub',
                region: 'main',
                properties: {
                    displayMode: 'dashboard',
                    showQuickActions: true,
                    defaultCategory: 'all'
                }
            },
            {
                type: 'Navigation',
                region: 'header',
                properties: {
                    navigationDevName: 'Default_Navigation'
                }
            }
        ]
    },

    ceb_training_modules: {
        site: 'CEB',
        pageName: 'Training Modules',
        route: '/training',
        template: 'Standard Page',
        components: [
            {
                type: 'cvmaCebTrainingHub',
                region: 'main',
                properties: {
                    displayMode: 'compact',
                    showQuickActions: false,
                    defaultCategory: 'Daily Operations'
                }
            }
        ]
    },

    // Member Portal Pages
    member_home: {
        site: 'Combat Veterans Motorcycle Association',
        pageName: 'Member Home',
        route: '/',
        template: 'Home Page',
        components: [
            {
                type: 'cvmaVeteranKnowledgeBase',
                region: 'main',
                properties: {
                    displayMode: 'article',
                    enableSearch: true,
                    showCategories: true,
                    showFeaturedArticles: true,
                    maxSearchResults: 10
                }
            }
        ]
    },

    member_training: {
        site: 'Combat Veterans Motorcycle Association',
        pageName: 'Member Training',
        route: '/training',
        template: 'Standard Page',
        components: [
            {
                type: 'cvmaVeteranKnowledgeBase',
                region: 'main',
                properties: {
                    displayMode: 'category',
                    enableSearch: true,
                    showCategories: true,
                    showFeaturedArticles: false,
                    maxSearchResults: 15
                }
            }
        ]
    },

    // Help Center Pages
    help_search: {
        site: 'Default Help Center',
        pageName: 'Help Search',
        route: '/',
        template: 'Search Page',
        components: [
            {
                type: 'cvmaVeteranKnowledgeBase',
                region: 'main',
                properties: {
                    displayMode: 'search',
                    enableSearch: true,
                    showCategories: false,
                    showFeaturedArticles: true,
                    maxSearchResults: 15
                }
            }
        ]
    },

    // Technical Documentation Pages
    tech_docs_home: {
        site: 'Technical Documentation',
        pageName: 'Documentation Home',
        route: '/',
        template: 'Standard Page',
        components: [
            {
                type: 'cvmaVeteranKnowledgeBase',
                region: 'main',
                properties: {
                    displayMode: 'category',
                    enableSearch: true,
                    showCategories: true,
                    showFeaturedArticles: false,
                    maxSearchResults: 20
                }
            }
        ]
    }
};

/**
 * Survey Integration Configuration
 */
const SURVEY_CONFIGURATION = {
    knowledge_article_feedback: {
        surveyName: 'Knowledge Article Feedback',
        questions: [
            {
                type: 'rating',
                question: 'How helpful was this article?',
                scale: '1-5',
                required: true
            },
            {
                type: 'multiple_choice',
                question: 'What best describes your experience level?',
                choices: ['New Member', 'Experienced Member', 'Officer', 'Technical Staff'],
                required: true
            },
            {
                type: 'text',
                question: 'How can we improve this article?',
                required: false
            }
        ],
        placement: 'bottom_of_article',
        trigger: 'manual'
    },

    training_module_rating: {
        surveyName: 'Training Module Rating',
        questions: [
            {
                type: 'rating',
                question: 'Rate the effectiveness of this training module',
                scale: '1-5',
                required: true
            },
            {
                type: 'multiple_choice',
                question: 'Which aspect was most valuable?',
                choices: ['Content Quality', 'Practical Examples', 'Easy Navigation', 'PDF Resources'],
                required: true
            },
            {
                type: 'text',
                question: 'Suggestions for improvement',
                required: false
            }
        ],
        placement: 'end_of_module',
        trigger: 'completion'
    }
};

/**
 * Cross-Site Navigation Configuration
 */
const CROSS_SITE_NAVIGATION = {
    global_navigation: {
        type: 'utility_bar',
        items: [
            {
                label: 'Member Portal',
                url: 'https://cvma20-7-dev-ed.develop.my.site.com',
                access: ['all']
            },
            {
                label: 'Officer Portal',
                url: 'https://cvma20-7-dev-ed.develop.my.site.com/ceb',
                access: ['officers', 'admin']
            },
            {
                label: 'Help Center',
                url: 'https://cvma20-7-dev-ed.develop.my.site.com/defaulthelpcenter12Jun',
                access: ['all']
            },
            {
                label: 'Technical Docs',
                url: 'https://cvma20-7-dev-ed.develop.my.site.com/technical',
                access: ['technical', 'admin']
            }
        ]
    },

    contextual_links: {
        help_context: {
            from_training: '/defaulthelpcenter12Jun/training-help',
            from_officer: '/defaulthelpcenter12Jun/officer-help'
        },
        quick_links: {
            emergency_procedures: '/ceb/emergency',
            daily_checklist: '/ceb/checklist',
            member_support: '/member-support'
        }
    }
};

/**
 * Testing Configuration
 */
const TESTING_CONFIGURATION = {
    personas: [
        {
            name: 'New CVMA Member',
            access: ['member_training', 'help_center'],
            test_scenarios: [
                'First-time login and navigation',
                'Finding getting started resources',
                'Completing first training module',
                'Submitting feedback survey'
            ]
        },
        {
            name: 'CEB Officer',
            access: ['ceb_training', 'member_training', 'help_center'],
            test_scenarios: [
                'Accessing officer dashboard',
                'Using quick action buttons',
                'Generating training PDFs',
                'Cross-site navigation to member portal'
            ]
        },
        {
            name: 'Technical Staff',
            access: ['technical_docs', 'member_training', 'help_center'],
            test_scenarios: [
                'Searching technical documentation',
                'Filtering by category',
                'Accessing code examples',
                'Mobile responsiveness testing'
            ]
        },
        {
            name: 'Guest User',
            access: ['help_center'],
            test_scenarios: [
                'Accessing help without login',
                'Using search functionality',
                'Accessibility features testing',
                'Mobile experience validation'
            ]
        }
    ],

    accessibility_tests: [
        'Screen reader compatibility (NVDA, JAWS)',
        'Keyboard-only navigation',
        'High contrast mode',
        'Font size scaling',
        'Color contrast ratios',
        'Focus indicators',
        'Alt text validation',
        'ARIA label correctness'
    ],

    mobile_tests: [
        'Responsive design breakpoints',
        'Touch target sizes',
        'Performance on mobile networks',
        'Offline functionality',
        'App-like experience'
    ],

    performance_tests: [
        'Page load times',
        'Component rendering speed',
        'Search response times',
        'PDF generation performance',
        'Survey submission speed'
    ]
};

/**
 * Export configuration for use in deployment scripts
 */
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        CVMA_EXPERIENCE_CLOUD_CONFIGURATION,
        EXPERIENCE_BUILDER_PAGES,
        SURVEY_CONFIGURATION,
        CROSS_SITE_NAVIGATION,
        TESTING_CONFIGURATION
    };
}

console.log('CVMA Experience Cloud Training Platform Configuration Loaded');
console.log('Sites configured:', Object.keys(CVMA_EXPERIENCE_CLOUD_CONFIGURATION).filter(key => key !== 'shared').length);
console.log('Pages defined:', Object.keys(EXPERIENCE_BUILDER_PAGES).length);
console.log('Survey types:', Object.keys(SURVEY_CONFIGURATION).length);
console.log('Test personas:', TESTING_CONFIGURATION.personas.length);
