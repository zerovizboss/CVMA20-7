import { LightningElement, track, api } from 'lwc';

export default class TemplateManager extends LightningElement {

    // Configuration
    @track isTrialMode = false; // Controls which templates are available

    // State
    @track searchTerm = '';
    @track activeCategory = 'All';
    @track filteredTemplates = [];
    @track showPreviewModal = false;
    @track showApplyConfirmation = false;
    @track selectedTemplate = null;
    @track templateToApply = null;

    // Timeout for search debouncing
    searchTimeout = null;

    // ===========================================
    // TEMPLATE DATA - SINGLE SOURCE OF TRUTH
    // ===========================================

    get allTemplates() {
        return [
            // TRIAL TEMPLATES (2-query templates)
            {
                id: 'basic_sales_analysis',
                name: 'Basic Sales Analysis',
                category: 'Sales',
                complexity: 'Beginner',
                description: 'Simple sales analysis using Accounts and Opportunities. Perfect for getting started with sales reporting.',
                icon: 'utility:opportunity',
                features: [
                    'Account and opportunity analysis',
                    'Revenue calculations',
                    'Win rate tracking',
                    'Industry breakdown'
                ],
                queryCount: 2,
                chartCount: 2,
                tableCount: 1,
                objectsUsed: 'Account, Opportunity',
                estimatedRuntime: '3-5 seconds',
                bestFor: 'Sales managers and beginners',
                isTrialCompatible: true,
                queries: [
                    {
                        id: 'accounts_basic',
                        index: 1,
                        description: 'Basic account information with revenue',
                        soql: `SELECT Id, Name, Industry, AnnualRevenue, BillingState, OwnerId, Owner.Name
FROM Account
WHERE AnnualRevenue != null
ORDER BY AnnualRevenue DESC
LIMIT 100`
                    },
                    {
                        id: 'opportunities_basic',
                        index: 2,
                        description: 'Opportunity data with stages and amounts',
                        soql: `SELECT Id, Name, Amount, StageName, AccountId, Account.Name, Account.Industry,
CloseDate, CreatedDate, OwnerId, Owner.Name
FROM Opportunity
WHERE Amount != null
ORDER BY CreatedDate DESC
LIMIT 150`
                    }
                ],
                processor: {
                    description: 'Basic analytics for accounts and opportunities with simple calculations',
                    javascript: `function processData(query1Results, query2Results) {
    // Basic Sales Analysis - 2-Query Version
    const accounts = query1Results || [];
    const opportunities = query2Results || [];
    
    // Basic calculations
    const totalRevenue = accounts.reduce((sum, acc) => sum + (acc.AnnualRevenue || 0), 0);
    const totalOpportunityValue = opportunities.reduce((sum, opp) => sum + (opp.Amount || 0), 0);
    const avgAccountRevenue = accounts.length > 0 ? totalRevenue / accounts.length : 0;
    
    // Industry breakdown
    const industryStats = {};
    accounts.forEach(account => {
        const industry = account.Industry || 'Unknown';
        if (!industryStats[industry]) {
            industryStats[industry] = { accounts: 0, revenue: 0 };
        }
        industryStats[industry].accounts++;
        industryStats[industry].revenue += account.AnnualRevenue || 0;
    });
    
    // Opportunity stage breakdown for CHART
    const stageStats = {};
    opportunities.forEach(opp => {
        const stage = opp.StageName || 'Unknown';
        stageStats[stage] = (stageStats[stage] || 0) + (opp.Amount || 0);
    });
    
    // Top accounts by revenue
    const topAccounts = accounts
        .sort((a, b) => (b.AnnualRevenue || 0) - (a.AnnualRevenue || 0))
        .slice(0, 10);
    
    const result = {
        summary: {
            "Total Accounts": accounts.length,
            "Total Opportunities": opportunities.length,
            "Account Revenue": \`$\${Math.round(totalRevenue/1000)}K\`,
            "Opportunity Value": \`$\${Math.round(totalOpportunityValue/1000)}K\`,
            "Avg Account Revenue": \`$\${Math.round(avgAccountRevenue/1000)}K\`
        },
        
        industryBreakdown: Object.entries(industryStats).map(([industry, stats]) => ({
            Industry: industry,
            'Account Count': stats.accounts,
            'Total Revenue': Math.round(stats.revenue),
            'Avg Revenue': Math.round(stats.revenue / stats.accounts),
            'Revenue (K)': \`$\${Math.round(stats.revenue/1000)}K\`
        })),
        
        opportunityStages: Object.fromEntries(
            Object.entries(stageStats).map(([stage, value]) => [
                stage, Math.round(value/1000)
            ])
        ),
        
        topAccounts: topAccounts.map(acc => ({
            'Account Name': acc.Name,
            Industry: acc.Industry || 'Unknown',
            'Annual Revenue': Math.round(acc.AnnualRevenue || 0),
            'Revenue (K)': \`$\${Math.round((acc.AnnualRevenue || 0)/1000)}K\`,
            Owner: acc.Owner?.Name || 'Unassigned',
            State: acc.BillingState || 'Unknown'
        })),
        
        insights: [
            \`Analyzed \${accounts.length} accounts with total revenue of $\${Math.round(totalRevenue / 1000)}K\`,
            \`\${opportunities.length} opportunities worth $\${Math.round(totalOpportunityValue / 1000)}K in pipeline\`,
            \`Top industry: \${Object.keys(industryStats)[0] || 'Unknown'} with \${industryStats[Object.keys(industryStats)[0]]?.accounts || 0} accounts\`,
            \`Highest revenue account: \${topAccounts[0]?.Name || 'N/A'} with $\${Math.round((topAccounts[0]?.AnnualRevenue || 0)/1000)}K\`
        ],
        
        recommendations: [
            'Focus on top-performing industries for growth opportunities',
            'Review opportunity stages for potential bottlenecks',
            'Engage with high-revenue accounts for upselling potential',
            'Develop strategies for underperforming industry segments'
        ]
    };
    
    return JSON.parse(JSON.stringify(result));
}`
                },
                expectedOutput: [
                    { type: 'Summary Metrics', icon: 'utility:number_input', description: 'Key sales performance indicators' },
                    { type: 'Industry Table', icon: 'utility:table', description: 'Revenue breakdown by industry' },
                    { type: 'Stages Chart', icon: 'utility:chart', description: 'Opportunity pipeline visualization' },
                    { type: 'Top Accounts Table', icon: 'utility:table', description: 'Highest revenue accounts' },
                    { type: 'Insights List', icon: 'utility:list', description: 'Automated insights and recommendations' }
                ]
            },

            {
                id: 'contact_engagement',
                name: 'Contact Engagement Analysis',
                category: 'Sales',
                complexity: 'Beginner',
                description: 'Analyze contact engagement by linking accounts and contacts to understand relationship strength.',
                icon: 'utility:people',
                features: [
                    'Contact-to-account ratios',
                    'Engagement scoring',
                    'Title analysis',
                    'Account coverage'
                ],
                queryCount: 2,
                chartCount: 1,
                tableCount: 2,
                objectsUsed: 'Account, Contact',
                estimatedRuntime: '2-4 seconds',
                bestFor: 'Sales development and account management',
                isTrialCompatible: true,
                queries: [
                    {
                        id: 'accounts_contacts',
                        index: 1,
                        description: 'Account information for contact analysis',
                        soql: `SELECT Id, Name, Industry, NumberOfEmployees, BillingState
FROM Account
WHERE Id IN (SELECT AccountId FROM Contact WHERE AccountId != null)
LIMIT 100`
                    },
                    {
                        id: 'contacts_detailed',
                        index: 2,
                        description: 'Contact details with account relationships',
                        soql: `SELECT Id, Name, Title, Email, Phone, AccountId, Account.Name, Account.Industry,
CreatedDate, LastActivityDate
FROM Contact
WHERE AccountId != null
ORDER BY CreatedDate DESC
LIMIT 200`
                    }
                ],
                processor: {
                    description: 'Contact engagement analytics with account relationship scoring',
                    javascript: `function processData(query1Results, query2Results) {
    // Contact Engagement Analysis - 2-Query Version
    const accounts = query1Results || [];
    const contacts = query2Results || [];
    
    const accountMap = new Map();
    accounts.forEach(acc => accountMap.set(acc.Id, acc));
    
    const accountEngagement = {};
    contacts.forEach(contact => {
        const accountId = contact.AccountId;
        if (!accountEngagement[accountId]) {
            const account = accountMap.get(accountId);
            accountEngagement[accountId] = {
                accountName: account?.Name || 'Unknown',
                industry: account?.Industry || 'Unknown',
                contactCount: 0,
                contacts: []
            };
        }
        accountEngagement[accountId].contactCount++;
        accountEngagement[accountId].contacts.push(contact);
    });
    
    const titleStats = {};
    contacts.forEach(contact => {
        const title = contact.Title || 'Unknown';
        const normalizedTitle = title.toLowerCase();
        let category = 'Other';
        
        if (normalizedTitle.includes('ceo') || normalizedTitle.includes('president')) {
            category = 'Executive';
        } else if (normalizedTitle.includes('director') || normalizedTitle.includes('vp')) {
            category = 'Director';
        } else if (normalizedTitle.includes('manager')) {
            category = 'Manager';
        } else if (normalizedTitle.includes('sales')) {
            category = 'Sales';
        }
        
        titleStats[category] = (titleStats[category] || 0) + 1;
    });
    
    const engagementScores = Object.values(accountEngagement).map(acc => {
        let score = acc.contactCount * 10;
        if (acc.contactCount > 2) score += 20;
        if (acc.contactCount > 5) score += 30;
        
        const titles = new Set(acc.contacts.map(c => c.Title?.toLowerCase()));
        score += titles.size * 5;
        
        return {
            ...acc,
            engagementScore: Math.min(score, 100)
        };
    }).sort((a, b) => b.engagementScore - a.engagementScore);
    
    const result = {
        summary: {
            "Total Accounts": accounts.length,
            "Total Contacts": contacts.length,
            "Avg Contacts per Account": accounts.length > 0 ? Math.round(contacts.length / accounts.length * 10) / 10 : 0,
            "Well-Covered Accounts": engagementScores.filter(acc => acc.contactCount >= 3).length,
            "Single Contact Accounts": engagementScores.filter(acc => acc.contactCount === 1).length
        },
        
        titleDistribution: titleStats,
        
        topEngagementAccounts: engagementScores.slice(0, 15).map(acc => ({
            'Account Name': acc.accountName,
            Industry: acc.industry,
            'Contact Count': acc.contactCount,
            'Engagement Score': acc.engagementScore,
            Status: acc.contactCount >= 3 ? 'Well Covered' : acc.contactCount === 1 ? 'Single Contact' : 'Moderate'
        })),
        
        insights: [
            \`\${contacts.length} contacts across \${accounts.length} accounts\`,
            \`Average \${Math.round(contacts.length / accounts.length * 10) / 10} contacts per account\`,
            \`\${engagementScores.filter(acc => acc.contactCount === 1).length} accounts have only one contact\`,
            \`Top engagement: \${engagementScores[0]?.accountName || 'N/A'} with \${engagementScores[0]?.contactCount || 0} contacts\`
        ],
        
        recommendations: [
            'Focus on single-contact accounts for relationship expansion',
            'Target executive-level contacts in key accounts',
            'Increase contact coverage in underrepresented industries',
            'Develop multi-threading strategies for better account penetration'
        ]
    };
    
    return JSON.parse(JSON.stringify(result));
}`
                },
                expectedOutput: [
                    { type: 'Engagement Metrics', icon: 'utility:number_input', description: 'Contact coverage and engagement statistics' },
                    { type: 'Title Chart', icon: 'utility:chart', description: 'Contact titles distribution' },
                    { type: 'Account Engagement Table', icon: 'utility:table', description: 'Account-level engagement analysis' }
                ]
            },

            // FULL TEMPLATES (4-query templates)
            {
                id: 'sales_performance_analysis',
                name: 'Sales Performance Analysis',
                category: 'Sales',
                complexity: 'Intermediate',
                description: 'Comprehensive analysis of sales performance across accounts, opportunities, and activities. Includes win rate calculations, pipeline analysis, and territory performance.',
                icon: 'utility:opportunity',
                features: [
                    'Multi-object analysis',
                    'Win rate calculations',
                    'Pipeline forecasting',
                    'Territory comparisons'
                ],
                queryCount: 4,
                chartCount: 3,
                tableCount: 2,
                objectsUsed: 'Account, Contact, Opportunity, Task',
                estimatedRuntime: '5-8 seconds',
                bestFor: 'Sales managers and executives',
                isTrialCompatible: false,
                queries: [
                    {
                        id: 'accounts_query',
                        index: 1,
                        description: 'Retrieve account data with industry and revenue information',
                        soql: `SELECT Id, Name, Industry, BillingState, AnnualRevenue, NumberOfEmployees, OwnerId, Owner.Name
FROM Account
WHERE Industry != null AND AnnualRevenue != null
ORDER BY AnnualRevenue DESC
LIMIT 100`
                    },
                    {
                        id: 'opportunities_query',
                        index: 2,
                        description: 'Fetch opportunity data with stage and amount information',
                        soql: `SELECT Id, Name, Amount, StageName, AccountId, Account.Name, Account.Industry,
CloseDate, CreatedDate, OwnerId, Owner.Name
FROM Opportunity
WHERE Amount != null AND StageName != null
ORDER BY CreatedDate DESC
LIMIT 200`
                    },
                    {
                        id: 'contacts_query',
                        index: 3,
                        description: 'Get contact information linked to accounts',
                        soql: `SELECT Id, Name, Title, AccountId, Account.Name, Account.Industry,
Email, Phone, CreatedDate
FROM Contact
WHERE AccountId != null
ORDER BY CreatedDate DESC
LIMIT 150`
                    },
                    {
                        id: 'activities_query',
                        index: 4,
                        description: 'Recent sales activities and tasks',
                        soql: `SELECT Id, Subject, Status, ActivityDate, WhoId, WhatId,
CreatedDate, OwnerId, Owner.Name
FROM Task
WHERE CreatedDate = LAST_30_DAYS AND Status != null
ORDER BY CreatedDate DESC
LIMIT 100`
                    }
                ],
                processor: {
                    description: 'Advanced analytics processor that calculates win rates, pipeline metrics, and performance by territory and industry',
                    javascript: `function processData(query1Results, query2Results, query3Results, query4Results) {
    // Sales Performance Analysis - 4-Query Version
    const accounts = Array.isArray(query1Results) ? query1Results : [];
    const opportunities = Array.isArray(query2Results) ? query2Results : [];
    const contacts = Array.isArray(query3Results) ? query3Results : [];
    const activities = Array.isArray(query4Results) ? query4Results : [];
    
    console.log('Processing sales performance data:', {
        accounts: accounts.length,
        opportunities: opportunities.length,
        contacts: contacts.length,
        activities: activities.length
    });
    
    const groupBy = (array, keyFn) => 
        array.reduce((groups, item) => {
            const key = keyFn(item);
            groups[key] = groups[key] || [];
            groups[key].push(item);
            return groups;
        }, {});
    
    const totalRevenue = opportunities
        .filter(opp => opp.StageName === 'Closed Won')
        .reduce((sum, opp) => sum + (opp.Amount || 0), 0);
    
    const totalPipeline = opportunities
        .filter(opp => opp.StageName && !opp.StageName.includes('Closed'))
        .reduce((sum, opp) => sum + (opp.Amount || 0), 0);
    
    const wonOpps = opportunities.filter(opp => opp.StageName === 'Closed Won');
    const winRate = opportunities.length > 0 ? 
        Math.round((wonOpps.length / opportunities.length) * 100) : 0;
    
    const accountsByIndustry = groupBy(accounts, acc => acc.Industry || 'Unknown');
    const industryAnalysis = Object.entries(accountsByIndustry).map(([industry, accs]) => {
        const industryOpps = opportunities.filter(opp => {
            const account = accounts.find(acc => acc.Id === opp.AccountId);
            return account && account.Industry === industry;
        });
        
        const industryRevenue = industryOpps
            .filter(opp => opp.StageName === 'Closed Won')
            .reduce((sum, opp) => sum + (opp.Amount || 0), 0);
        
        return {
            industry,
            accountCount: accs.length,
            opportunityCount: industryOpps.length,
            revenue: industryRevenue,
            avgRevenue: accs.length > 0 ? industryRevenue / accs.length : 0
        };
    }).sort((a, b) => b.revenue - a.revenue);
    
    const pipelineByStage = opportunities.reduce((stages, opp) => {
        const stage = opp.StageName || 'Unknown';
        stages[stage] = (stages[stage] || 0) + (opp.Amount || 0);
        return stages;
    }, {});
    
    const completedActivities = activities.filter(act => act.Status === 'Completed').length;
    const activityCompletionRate = activities.length > 0 ? 
        Math.round((completedActivities / activities.length) * 100) : 0;
    
    return {
        salesMetrics: {
            "Total Accounts": accounts.length,
            "Total Opportunities": opportunities.length,
            "Total Revenue": Math.round(totalRevenue / 1000) + 'K',
            "Pipeline Value": Math.round(totalPipeline / 1000) + 'K',
            "Win Rate": winRate + '%',
            "Total Contacts": contacts.length,
            "Activity Completion": activityCompletionRate + '%'
        },
        
        industryPerformance: industryAnalysis,
        pipelineBreakdown: pipelineByStage,
        
        insights: [
            \`Analyzed \${accounts.length} accounts with \${opportunities.length} opportunities\`,
            \`Win rate of \${winRate}% indicates \${winRate > 30 ? 'strong' : 'improving'} sales performance\`,
            \`Top industry: \${industryAnalysis[0]?.industry || 'N/A'} with $\${Math.round((industryAnalysis[0]?.revenue || 0) / 1000)}K revenue\`,
            \`\${completedActivities} of \${activities.length} recent activities completed (\${activityCompletionRate}%)\`
        ],
        
        recommendations: [
            winRate < 25 ? 'Focus on improving qualification and sales process' : 'Maintain current sales methodology',
            totalPipeline > totalRevenue ? 'Strong pipeline indicates good future potential' : 'Increase prospecting activities',
            activityCompletionRate < 70 ? 'Improve activity follow-through and task completion' : 'Good activity execution',
            \`Focus on top performing industries: \${industryAnalysis.slice(0, 3).map(i => i.industry).join(', ')}\`
        ]
    };
}`
                },
                expectedOutput: [
                    { type: 'Metrics Cards', icon: 'utility:number_input', description: 'Key performance indicators and summary statistics' },
                    { type: 'Performance Table', icon: 'utility:table', description: 'Detailed breakdown by territory, industry, or owner' },
                    { type: 'Trend Charts', icon: 'utility:chart', description: 'Visual representation of sales trends over time' },
                    { type: 'Insights List', icon: 'utility:list', description: 'Automated insights and recommendations' }
                ]
            },

            {
                id: 'customer_health_scorecard',
                name: 'Customer Health Scorecard',
                category: 'Customer Success',
                complexity: 'Advanced',
                description: 'Comprehensive customer health analysis including case resolution, engagement levels, and risk assessment.',
                icon: 'utility:heart',
                features: [
                    'Health score calculation',
                    'Risk assessment',
                    'Case analysis',
                    'Engagement tracking'
                ],
                queryCount: 4,
                chartCount: 2,
                tableCount: 3,
                objectsUsed: 'Account, Case, Contact, Opportunity',
                estimatedRuntime: '6-10 seconds',
                bestFor: 'Customer success managers',
                isTrialCompatible: false,
                queries: [
                    {
                        id: 'accounts_health',
                        index: 1,
                        description: 'Account data for health score calculation',
                        soql: `SELECT Id, Name, Industry, Type, AnnualRevenue, LastActivityDate, CreatedDate
FROM Account
WHERE Type IN ('Customer', 'Customer - Direct', 'Customer - Channel')
LIMIT 100`
                    },
                    {
                        id: 'cases_analysis',
                        index: 2,
                        description: 'Case data for support metrics',
                        soql: `SELECT Id, CaseNumber, AccountId, Status, Priority, CreatedDate, ClosedDate, IsClosed
FROM Case
WHERE AccountId != null AND CreatedDate = LAST_180_DAYS
LIMIT 200`
                    },
                    {
                        id: 'contacts_engagement',
                        index: 3,
                        description: 'Contact engagement data',
                        soql: `SELECT Id, Name, AccountId, LastActivityDate, CreatedDate, Email
FROM Contact
WHERE AccountId != null
LIMIT 150`
                    },
                    {
                        id: 'opportunities_pipeline',
                        index: 4,
                        description: 'Opportunity pipeline for account growth',
                        soql: `SELECT Id, Name, AccountId, Amount, StageName, CreatedDate, Type
FROM Opportunity
WHERE AccountId != null AND CreatedDate = LAST_180_DAYS
LIMIT 100`
                    }
                ],
                processor: {
                    description: 'Health score calculation engine with risk assessment and automated recommendations',
                    javascript: `function processData(query1Results, query2Results, query3Results, query4Results) {
    // Customer Health Scorecard - 4-Query Version
    const accounts = Array.isArray(query1Results) ? query1Results : [];
    const cases = Array.isArray(query2Results) ? query2Results : [];
    const contacts = Array.isArray(query3Results) ? query3Results : [];
    const opportunities = Array.isArray(query4Results) ? query4Results : [];
    
    const daysBetween = (date1, date2) => {
        const diffTime = Math.abs(new Date(date2) - new Date(date1));
        return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    };
    
    const groupBy = (array, keyFn) => 
        array.reduce((groups, item) => {
            const key = keyFn(item);
            groups[key] = groups[key] || [];
            groups[key].push(item);
            return groups;
        }, {});
    
    const casesByAccount = groupBy(cases, c => c.AccountId);
    const contactsByAccount = groupBy(contacts, c => c.AccountId);
    const oppsByAccount = groupBy(opportunities, o => o.AccountId);
    
    const accountHealth = accounts.map(account => {
        const accountCases = casesByAccount[account.Id] || [];
        const accountContacts = contactsByAccount[account.Id] || [];
        const accountOpps = oppsByAccount[account.Id] || [];
        
        const openCases = accountCases.filter(c => !c.IsClosed).length;
        const highPriorityCases = accountCases.filter(c => c.Priority === 'High' && !c.IsClosed).length;
        const lastActivityDays = account.LastActivityDate ? 
            daysBetween(account.LastActivityDate, new Date()) : 999;
        const recentOpps = accountOpps.filter(opp => 
            daysBetween(opp.CreatedDate, new Date()) <= 90).length;
        
        let healthScore = 100;
        healthScore -= (openCases * 10);
        healthScore -= (highPriorityCases * 20);
        healthScore -= (lastActivityDays > 90 ? 25 : 0);
        healthScore -= (recentOpps === 0 ? 15 : 0);
        healthScore -= (accountContacts.length < 2 ? 10 : 0);
        
        healthScore = Math.max(0, Math.min(100, healthScore));
        
        const status = healthScore >= 80 ? 'Excellent' :
                      healthScore >= 60 ? 'Good' :
                      healthScore >= 40 ? 'At Risk' : 'Critical';
        
        return {
            accountName: account.Name,
            industry: account.Industry || 'Unknown',
            healthScore,
            status,
            openCases,
            highPriorityCases,
            lastActivityDays,
            contactCount: accountContacts.length,
            recentOpportunities: recentOpps
        };
    }).sort((a, b) => a.healthScore - b.healthScore);
    
    const healthDistribution = {
        "Excellent (80-100)": accountHealth.filter(a => a.healthScore >= 80).length,
        "Good (60-79)": accountHealth.filter(a => a.healthScore >= 60 && a.healthScore < 80).length,
        "At Risk (40-59)": accountHealth.filter(a => a.healthScore >= 40 && a.healthScore < 60).length,
        "Critical (0-39)": accountHealth.filter(a => a.healthScore < 40).length
    };
    
    const atRiskCustomers = accountHealth.filter(a => a.healthScore < 60);
    const avgHealthScore = accountHealth.length > 0 ? 
        Math.round(accountHealth.reduce((sum, a) => sum + a.healthScore, 0) / accountHealth.length) : 0;
    
    return {
        healthOverview: {
            "Total Customers": accounts.length,
            "Average Health Score": avgHealthScore,
            "At Risk Customers": atRiskCustomers.length,
            "Open Cases": cases.filter(c => !c.IsClosed).length,
            "High Priority Cases": cases.filter(c => c.Priority === 'High' && !c.IsClosed).length
        },
        
        customerHealthDetails: accountHealth.slice(0, 20),
        healthDistribution: healthDistribution,
        
        insights: [
            \`\${atRiskCustomers.length} customers are at risk and need immediate attention\`,
            \`Average health score is \${avgHealthScore}/100 across all customers\`,
            \`\${cases.filter(c => !c.IsClosed).length} open cases require resolution\`,
            \`\${accountHealth.filter(a => a.lastActivityDays > 90).length} customers with no recent activity\`
        ],
        
        recommendations: [
            atRiskCustomers.length > 0 ? 
                \`Prioritize outreach to \${Math.min(5, atRiskCustomers.length)} lowest-scoring customers\` : 
                'Customer health levels are generally good',
            'Implement regular health score monitoring',
            cases.filter(c => c.Priority === 'High' && !c.IsClosed).length > 0 ? 
                'Address high-priority cases immediately' : 
                'Maintain current support levels'
        ]
    };
}`
                },
                expectedOutput: [
                    { type: 'Health Metrics', icon: 'utility:heart', description: 'Overall customer health statistics' },
                    { type: 'Risk Assessment', icon: 'utility:warning', description: 'At-risk account identification' },
                    { type: 'Health Trends', icon: 'utility:trending', description: 'Health score trends over time' }
                ]
            }
        ];
    }

    // Get templates based on current mode
    get availableTemplates() {
        if (this.isTrialMode) {
            return this.allTemplates.filter(template => template.isTrialCompatible);
        }
        return this.allTemplates;
    }

    // ===========================================
    // LIFECYCLE METHODS
    // ===========================================

    connectedCallback() {
        this.initializeTemplates();
        console.log('🎯 Template Manager connected:', {
            mode: this.isTrialMode ? 'Trial' : 'Full',
            available: this.availableTemplates.length,
            total: this.allTemplates.length
        });
    }

    initializeTemplates() {
        this.filteredTemplates = [...this.availableTemplates];
        this.applyFilters();
    }

    // ===========================================
    // PUBLIC API METHODS
    // ===========================================

    @api
    setTrialMode(isTrialMode) {
        this.isTrialMode = isTrialMode;
        this.initializeTemplates();
        console.log('🔄 Template mode changed:', {
            mode: this.isTrialMode ? 'Trial' : 'Full',
            available: this.availableTemplates.length
        });
    }

    @api
    getTemplateById(templateId) {
        return this.availableTemplates.find(t => t.id === templateId);
    }

    @api
    getTemplatesByCategory(category) {
        return this.availableTemplates.filter(t => t.category === category);
    }

    @api
    refreshTemplates() {
        this.initializeTemplates();
        this.dispatchEvent(new CustomEvent('templaterefresh', {
            detail: { message: 'Templates refreshed successfully' }
        }));
    }

    // ===========================================
    // COMPUTED PROPERTIES
    // ===========================================

    get categories() {
        const uniqueCategories = [...new Set(this.availableTemplates.map(t => t.category))];
        const categoryData = [
            {
                name: 'All',
                label: 'All Templates',
                count: this.availableTemplates.length,
                buttonClass: this.activeCategory === 'All' ? 'filter-tag active' : 'filter-tag'
            }
        ];

        uniqueCategories.forEach(category => {
            const count = this.availableTemplates.filter(t => t.category === category).length;
            categoryData.push({
                name: category,
                label: category,
                count: count,
                buttonClass: this.activeCategory === category ? 'filter-tag active' : 'filter-tag'
            });
        });

        return categoryData;
    }

    get hasFilteredTemplates() {
        return this.filteredTemplates && this.filteredTemplates.length > 0;
    }

    get modeLabel() {
        return this.isTrialMode ? 'Trial Mode' : 'Full Mode';
    }

    get templateCountText() {
        return `${this.filteredTemplates.length} of ${this.availableTemplates.length} templates`;
    }

    // ===========================================
    // FILTERING AND SEARCH
    // ===========================================

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.applyFilters();
    }

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.applyFilters();
        }, 300);
    }

    handleCategoryFilter(event) {
        this.activeCategory = event.target.dataset.category;
        this.applyFilters();
    }

    clearFilters() {
        this.searchTerm = '';
        this.activeCategory = 'All';
        this.applyFilters();

        const searchInput = this.template.querySelector('.search-input');
        if (searchInput) {
            searchInput.value = '';
        }
    }

    applyFilters() {
        let filtered = [...this.availableTemplates];

        // Apply category filter
        if (this.activeCategory !== 'All') {
            filtered = filtered.filter(template => template.category === this.activeCategory);
        }

        // Apply search filter
        if (this.searchTerm) {
            const searchLower = this.searchTerm.toLowerCase();
            filtered = filtered.filter(template =>
                template.name.toLowerCase().includes(searchLower) ||
                template.description.toLowerCase().includes(searchLower) ||
                template.category.toLowerCase().includes(searchLower) ||
                template.features.some(feature => feature.toLowerCase().includes(searchLower))
            );
        }

        this.filteredTemplates = filtered;
        console.log('🔍 Applied filters:', {
            category: this.activeCategory,
            search: this.searchTerm,
            results: filtered.length
        });
    }

    // ===========================================
    // TEMPLATE ACTIONS
    // ===========================================

    handlePreview(event) {
        const templateId = this.getTemplateIdFromEvent(event);
        console.log('👁️ Preview clicked, templateId:', templateId);

        if (templateId) {
            const template = this.getTemplateById(templateId);
            if (template) {
                this.selectedTemplate = template;
                this.showPreviewModal = true;
                console.log('✅ Template found for preview:', template.name);
            } else {
                console.error('❌ Template not found for preview with ID:', templateId);
            }
        } else {
            console.error('❌ No template ID found in preview event');
        }
    }

    handleApplyTemplate(event) {
        const templateId = this.getTemplateIdFromEvent(event);
        console.log('🚀 Apply template clicked, templateId:', templateId);

        if (templateId) {
            const template = this.getTemplateById(templateId);
            if (template) {
                this.templateToApply = template;
                this.showApplyConfirmation = true;
                console.log('✅ Template found and ready to apply:', template.name);
            } else {
                console.error('❌ Template not found with ID:', templateId);
            }
        } else {
            console.error('❌ No template ID found in event');
        }
    }

    handleApplyFromPreview() {
        if (this.selectedTemplate) {
            this.templateToApply = this.selectedTemplate;
            this.showPreviewModal = false;
            this.showApplyConfirmation = true;
            console.log('🚀 Applying template from preview:', this.selectedTemplate.name);
        }
    }

    confirmApplyTemplate() {
        console.log('🔥 CONFIRMING TEMPLATE APPLICATION:', this.templateToApply?.name);

        if (!this.templateToApply || !this.templateToApply.name) {
            console.error('❌ Cannot apply template - templateToApply is invalid:', this.templateToApply);
            return;
        }

        try {
            // Strip LWC Proxy wrappers using JSON serialization
            const cleanTemplate = JSON.parse(JSON.stringify(this.templateToApply));

            // Validate template data structure
            const { queries, processor } = cleanTemplate;

            if (!queries || !Array.isArray(queries)) {
                throw new Error('Template queries are missing or invalid');
            }

            if (!processor || !processor.javascript) {
                throw new Error('Template processor is missing or invalid');
            }

            console.log('✅ Template validation passed');

            // Create clean event detail
            const eventDetail = {
                template: {
                    id: cleanTemplate.id,
                    name: cleanTemplate.name,
                    category: cleanTemplate.category,
                    queryCount: cleanTemplate.queryCount
                },
                queries: cleanTemplate.queries,
                processor: cleanTemplate.processor.javascript
            };

            console.log('🚀 Dispatching templateapplied event');

            this.dispatchEvent(new CustomEvent('templateapplied', {
                detail: eventDetail,
                bubbles: true,
                composed: true
            }));

            console.log('✅ Template applied event dispatched successfully');
            this.closeApplyConfirmation();

            this.dispatchEvent(new CustomEvent('templatesuccess', {
                detail: {
                    message: `Template "${cleanTemplate.name}" applied successfully!`
                },
                bubbles: true,
                composed: true
            }));

        } catch (error) {
            console.error('❌ Error applying template:', error);

            this.dispatchEvent(new CustomEvent('templateerror', {
                detail: {
                    message: `Failed to apply template: ${error.message}`
                },
                bubbles: true,
                composed: true
            }));
        }
    }

    // ===========================================
    // HELPER METHODS
    // ===========================================

    getTemplateIdFromEvent(event) {
        return event.currentTarget.dataset.templateId ||
            event.target.dataset.templateId ||
            event.target.closest('[data-template-id]')?.dataset.templateId;
    }

    // ===========================================
    // MODAL MANAGEMENT
    // ===========================================

    closePreviewModal() {
        this.showPreviewModal = false;
        this.selectedTemplate = null;
    }

    closeApplyConfirmation() {
        this.showApplyConfirmation = false;
        this.templateToApply = null;
    }

    stopPropagation(event) {
        event.stopPropagation();
    }
}