/**
 * CVMA CareerOneStop Controller - Military Career Translation Platform
 * Integrates with Department of Labor CareerOneStop APIs to provide comprehensive
 * military-to-civilian career translation and job matching services for CVMA veterans
 *
 * APIs Integrated:
 * 1. Veterans Job Matcher API - Military occupation code translation
 * 2. Skills Matcher API - Skills-based career matching
 * 3. Occupation Details API - Detailed civilian occupation information
 * 4. Job Listings API - Real job postings with application links
 */
public with sharing class CVMACareerOneStopController {

    // Constants for API endpoints and cache keys
    private static final String CACHE_PREFIX = 'CVMA_COS_';
    private static final Integer DEFAULT_CACHE_TTL = 1440; // 24 hours in minutes
    private static final Integer JOB_CACHE_TTL = 60; // 1 hour for job listings
    private static final String DEFAULT_USER_ID = 'CVMA_VET_SERVICES';

    // Rate limiting tracking
    private static Map<String, RateLimitTracker> rateLimitTrackers = new Map<String, RateLimitTracker>();

    /**
     * Translate military occupation code to civilian careers
     * Supports all service branches: Army MOS, Navy Rating, Air Force AFSC, Marine MOS, Space Force AFSC, Coast Guard Rating
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> translateMilitaryOccupation(String militaryCode, String location) {
        String methodName = 'translateMilitaryOccupation';
        Map<String, Object> context = new Map<String, Object>{
            'militaryCode' => militaryCode,
            'location' => location,
            'userId' => UserInfo.getUserId()
        };

        try {
            // Input validation and sanitization
            if (String.isBlank(militaryCode)) {
                throw new CVMAErrorHandler.ValidationException('Military code is required');
            }

            militaryCode = CVMAErrorHandler.sanitizeInput(militaryCode);
            location = String.isNotBlank(location) ? CVMAErrorHandler.sanitizeInput(location) : 'US';

            // Security validation - prevent guest user access to detailed career data
            if (UserInfo.getUserType() == 'Guest') {
                throw new CVMAErrorHandler.SecurityException('Guest users have limited access to career translation services');
            }

            // Check cache first
            String cacheKey = CACHE_PREFIX + 'TRANSLATE_' + militaryCode + '_' + location;
            Map<String, Object> cachedResult = getCachedResult(cacheKey);
            if (cachedResult != null) {
                return cachedResult;
            }

            // Get API configuration
            CVMA_CareerOneStop_API_Config__mdt apiConfig = getAPIConfiguration('Veterans_Job_Matcher');
            if (apiConfig == null || !apiConfig.Is_Active__c) {
                throw new CVMAErrorHandler.IntegrationException('Veterans Job Matcher API is not available');
            }

            // Check rate limits
            if (!checkRateLimit(apiConfig)) {
                throw new CVMAErrorHandler.IntegrationException('API rate limit exceeded. Please try again later.');
            }

            // Make API call
            Map<String, Object> result;
            if (apiConfig.Use_Mock_API__c) {
                result = getMockMilitaryTranslation(militaryCode, location);
            } else {
                result = callVeteransJobMatcherAPI(militaryCode, location, apiConfig);
            }

            // Cache successful results
            if (result != null && !result.isEmpty()) {
                setCachedResult(cacheKey, result, (Integer) apiConfig.Cache_TTL_Minutes__c);
            }

            // Track API usage
            trackAPIUsage(apiConfig, true);

            return result;

        } catch (Exception ex) {
            String errorMessage = CVMAErrorHandler.handleException(
                ex,
                'CVMACareerOneStopController',
                methodName,
                CVMAErrorHandler.Severity.MEDIUM,
                CVMAErrorHandler.Category.INTEGRATION,
                context
            );
            throw new AuraHandledException(errorMessage);
        }
    }

    /**
     * Get career recommendations based on veteran skills
     * Skills-based matching independent of specific military occupation codes
     */
    @AuraEnabled(cacheable=true)
    public static List<CareerMatch> getCareerRecommendations(String skills, String location) {
        String methodName = 'getCareerRecommendations';
        Map<String, Object> context = new Map<String, Object>{
            'skills' => skills,
            'location' => location,
            'userId' => UserInfo.getUserId()
        };

        try {
            // Input validation
            if (String.isBlank(skills)) {
                throw new CVMAErrorHandler.ValidationException('Skills description is required');
            }

            skills = CVMAErrorHandler.sanitizeInput(skills);
            location = String.isNotBlank(location) ? CVMAErrorHandler.sanitizeInput(location) : 'US';

            // Check cache
            String cacheKey = CACHE_PREFIX + 'SKILLS_' + skills.hashCode() + '_' + location;
            List<CareerMatch> cachedResult = (List<CareerMatch>) getCachedResult(cacheKey);
            if (cachedResult != null) {
                return cachedResult;
            }

            // Get API configuration
            CVMA_CareerOneStop_API_Config__mdt apiConfig = getAPIConfiguration('Skills_Matcher');
            if (apiConfig == null || !apiConfig.Is_Active__c) {
                throw new CVMAErrorHandler.IntegrationException('Skills Matcher API is not available');
            }

            // Check rate limits
            if (!checkRateLimit(apiConfig)) {
                throw new CVMAErrorHandler.IntegrationException('API rate limit exceeded. Please try again later.');
            }

            // Make API call
            List<CareerMatch> result;
            if (apiConfig.Use_Mock_API__c) {
                result = getMockSkillsMatching(skills, location);
            } else {
                result = callSkillsMatcherAPI(skills, location, apiConfig);
            }

            // Cache and track usage
            if (result != null && !result.isEmpty()) {
                setCachedResult(cacheKey, result, (Integer) apiConfig.Cache_TTL_Minutes__c);
            }
            trackAPIUsage(apiConfig, true);

            return result;

        } catch (Exception ex) {
            String errorMessage = CVMAErrorHandler.handleException(
                ex,
                'CVMACareerOneStopController',
                methodName,
                CVMAErrorHandler.Severity.MEDIUM,
                CVMAErrorHandler.Category.INTEGRATION,
                context
            );
            throw new AuraHandledException(errorMessage);
        }
    }

    /**
     * Get detailed information about specific civilian occupations
     * Includes salary ranges, job outlook, and education requirements
     */
    @AuraEnabled(cacheable=true)
    public static OccupationDetail getOccupationDetails(String occupation, String location) {
        String methodName = 'getOccupationDetails';
        Map<String, Object> context = new Map<String, Object>{
            'occupation' => occupation,
            'location' => location,
            'userId' => UserInfo.getUserId()
        };

        try {
            // Input validation
            if (String.isBlank(occupation)) {
                throw new CVMAErrorHandler.ValidationException('Occupation name is required');
            }

            occupation = CVMAErrorHandler.sanitizeInput(occupation);
            location = String.isNotBlank(location) ? CVMAErrorHandler.sanitizeInput(location) : 'US';

            // Check cache
            String cacheKey = CACHE_PREFIX + 'OCCUPATION_' + occupation.hashCode() + '_' + location;
            OccupationDetail cachedResult = (OccupationDetail) getCachedResult(cacheKey);
            if (cachedResult != null) {
                return cachedResult;
            }

            // Get API configuration
            CVMA_CareerOneStop_API_Config__mdt apiConfig = getAPIConfiguration('Occupation_Details');
            if (apiConfig == null || !apiConfig.Is_Active__c) {
                throw new CVMAErrorHandler.IntegrationException('Occupation Details API is not available');
            }

            // Check rate limits
            if (!checkRateLimit(apiConfig)) {
                throw new CVMAErrorHandler.IntegrationException('API rate limit exceeded. Please try again later.');
            }

            // Make API call
            OccupationDetail result;
            if (apiConfig.Use_Mock_API__c) {
                result = getMockOccupationDetails(occupation, location);
            } else {
                result = callOccupationDetailsAPI(occupation, location, apiConfig);
            }

            // Cache and track usage
            if (result != null) {
                setCachedResult(cacheKey, result, (Integer) apiConfig.Cache_TTL_Minutes__c);
            }
            trackAPIUsage(apiConfig, true);

            return result;

        } catch (Exception ex) {
            String errorMessage = CVMAErrorHandler.handleException(
                ex,
                'CVMACareerOneStopController',
                methodName,
                CVMAErrorHandler.Severity.MEDIUM,
                CVMAErrorHandler.Category.INTEGRATION,
                context
            );
            throw new AuraHandledException(errorMessage);
        }
    }

    /**
     * Find real job postings for specified occupation and location
     * Returns current job openings with direct application links
     */
    @AuraEnabled(cacheable=true)
    public static List<JobOpportunity> findLocalJobs(String occupation, String location, Integer maxResults) {
        String methodName = 'findLocalJobs';
        Map<String, Object> context = new Map<String, Object>{
            'occupation' => occupation,
            'location' => location,
            'maxResults' => maxResults,
            'userId' => UserInfo.getUserId()
        };

        try {
            // Input validation
            if (String.isBlank(occupation)) {
                throw new CVMAErrorHandler.ValidationException('Occupation name is required');
            }

            occupation = CVMAErrorHandler.sanitizeInput(occupation);
            location = String.isNotBlank(location) ? CVMAErrorHandler.sanitizeInput(location) : 'US';
            maxResults = maxResults != null ? maxResults : 50;

            // Limit results to prevent abuse
            if (maxResults > 100) {
                maxResults = 100;
            }

            // Check cache (shorter TTL for job listings)
            String cacheKey = CACHE_PREFIX + 'JOBS_' + occupation.hashCode() + '_' + location + '_' + maxResults;
            List<JobOpportunity> cachedResult = (List<JobOpportunity>) getCachedResult(cacheKey);
            if (cachedResult != null) {
                return cachedResult;
            }

            // Get API configuration
            CVMA_CareerOneStop_API_Config__mdt apiConfig = getAPIConfiguration('Job_Listings');
            if (apiConfig == null || !apiConfig.Is_Active__c) {
                throw new CVMAErrorHandler.IntegrationException('Job Listings API is not available');
            }

            // Check rate limits
            if (!checkRateLimit(apiConfig)) {
                throw new CVMAErrorHandler.IntegrationException('API rate limit exceeded. Please try again later.');
            }

            // Make API call
            List<JobOpportunity> result;
            if (apiConfig.Use_Mock_API__c) {
                result = getMockJobListings(occupation, location, maxResults);
            } else {
                result = callJobListingsAPI(occupation, location, maxResults, apiConfig);
            }

            // Cache with shorter TTL for job listings
            if (result != null && !result.isEmpty()) {
                setCachedResult(cacheKey, result, JOB_CACHE_TTL);
            }
            trackAPIUsage(apiConfig, true);

            return result;

        } catch (Exception ex) {
            String errorMessage = CVMAErrorHandler.handleException(
                ex,
                'CVMACareerOneStopController',
                methodName,
                CVMAErrorHandler.Severity.MEDIUM,
                CVMAErrorHandler.Category.INTEGRATION,
                context
            );
            throw new AuraHandledException(errorMessage);
        }
    }

    /**
     * Get comprehensive career transition package for a veteran
     * Combines military translation, skills matching, and local jobs
     */
    @AuraEnabled(cacheable=true)
    public static CareerTransitionPackage getCareerTransitionPackage(String militaryCode, String skills, String location) {
        String methodName = 'getCareerTransitionPackage';
        Map<String, Object> context = new Map<String, Object>{
            'militaryCode' => militaryCode,
            'skills' => skills,
            'location' => location,
            'userId' => UserInfo.getUserId()
        };

        try {
            CareerTransitionPackage package = new CareerTransitionPackage();

            // Get military occupation translation
            if (String.isNotBlank(militaryCode)) {
                package.militaryTranslation = translateMilitaryOccupation(militaryCode, location);
            }

            // Get skills-based recommendations
            if (String.isNotBlank(skills)) {
                package.skillsMatches = getCareerRecommendations(skills, location);
            }

            // Get local jobs for top recommended occupations
            if (package.skillsMatches != null && !package.skillsMatches.isEmpty()) {
                String topOccupation = package.skillsMatches[0].occupationTitle;
                package.localJobs = findLocalJobs(topOccupation, location, 10);
                package.occupationDetails = getOccupationDetails(topOccupation, location);
            }

            package.generatedDate = DateTime.now();
            package.veteranLocation = location;

            return package;

        } catch (Exception ex) {
            String errorMessage = CVMAErrorHandler.handleException(
                ex,
                'CVMACareerOneStopController',
                methodName,
                CVMAErrorHandler.Severity.HIGH,
                CVMAErrorHandler.Category.INTEGRATION,
                context
            );
            throw new AuraHandledException(errorMessage);
        }
    }

    // Private helper methods for API calls

    private static Map<String, Object> callVeteransJobMatcherAPI(String militaryCode, String location, CVMA_CareerOneStop_API_Config__mdt config) {
        CVMA_CareerOneStop_API_Keys__c apiKeys = getAPIKeys(config.Environment__c);
        String endpoint = config.API_Endpoint_URL__c + '/' + apiKeys.User_ID__c + '/' + militaryCode;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + apiKeys.API_Key__c);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout((Integer) (config.Timeout_Seconds__c * 1000));

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        } else {
            throw new CVMAErrorHandler.IntegrationException('API call failed with status: ' + response.getStatusCode());
        }
    }

    private static List<CareerMatch> callSkillsMatcherAPI(String skills, String location, CVMA_CareerOneStop_API_Config__mdt config) {
        CVMA_CareerOneStop_API_Keys__c apiKeys = getAPIKeys(config.Environment__c);
        String endpoint = config.API_Endpoint_URL__c + '/' + apiKeys.User_ID__c;

        Map<String, Object> requestBody = new Map<String, Object>{
            'skills' => skills,
            'location' => location
        };

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + apiKeys.API_Key__c);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(requestBody));
        request.setTimeout((Integer) (config.Timeout_Seconds__c * 1000));

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            List<Object> responseData = (List<Object>) JSON.deserializeUntyped(response.getBody());
            return parseCareerMatches(responseData);
        } else {
            throw new CVMAErrorHandler.IntegrationException('API call failed with status: ' + response.getStatusCode());
        }
    }

    private static OccupationDetail callOccupationDetailsAPI(String occupation, String location, CVMA_CareerOneStop_API_Config__mdt config) {
        CVMA_CareerOneStop_API_Keys__c apiKeys = getAPIKeys(config.Environment__c);
        String endpoint = config.API_Endpoint_URL__c + '/' + apiKeys.User_ID__c + '/' +
                         EncodingUtil.urlEncode(occupation, 'UTF-8') + '/' + location;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + apiKeys.API_Key__c);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout((Integer) (config.Timeout_Seconds__c * 1000));

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return parseOccupationDetail(responseData);
        } else {
            throw new CVMAErrorHandler.IntegrationException('API call failed with status: ' + response.getStatusCode());
        }
    }

    private static List<JobOpportunity> callJobListingsAPI(String occupation, String location, Integer maxResults, CVMA_CareerOneStop_API_Config__mdt config) {
        CVMA_CareerOneStop_API_Keys__c apiKeys = getAPIKeys(config.Environment__c);
        String endpoint = config.API_Endpoint_URL__c + '/' + apiKeys.User_ID__c + '/' +
                         EncodingUtil.urlEncode(occupation, 'UTF-8') + '/' + location +
                         '?count=' + maxResults;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + apiKeys.API_Key__c);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout((Integer) (config.Timeout_Seconds__c * 1000));

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> jobs = (List<Object>) responseData.get('Jobs');
            return parseJobOpportunities(jobs);
        } else {
            throw new CVMAErrorHandler.IntegrationException('API call failed with status: ' + response.getStatusCode());
        }
    }

    // Mock data methods for testing and development

    private static Map<String, Object> getMockMilitaryTranslation(String militaryCode, String location) {
        Map<String, Object> mockResult = new Map<String, Object>();

        // Simulate realistic military code translation
        if (militaryCode.startsWith('11')) { // Infantry codes
            mockResult.put('civilianOccupations', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'title' => 'Security Guard',
                    'onetCode' => '33-9032.00',
                    'medianSalary' => 31050,
                    'outlook' => 'Average',
                    'matchScore' => 85
                },
                new Map<String, Object>{
                    'title' => 'Police Officer',
                    'onetCode' => '33-3051.00',
                    'medianSalary' => 67600,
                    'outlook' => 'Average',
                    'matchScore' => 80
                }
            });
        } else if (militaryCode.startsWith('25')) { // Signal/IT codes
            mockResult.put('civilianOccupations', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'title' => 'Network Administrator',
                    'onetCode' => '15-1244.00',
                    'medianSalary' => 89500,
                    'outlook' => 'Much Faster than Average',
                    'matchScore' => 90
                },
                new Map<String, Object>{
                    'title' => 'IT Support Specialist',
                    'onetCode' => '15-1232.00',
                    'medianSalary' => 59800,
                    'outlook' => 'Faster than Average',
                    'matchScore' => 85
                }
            });
        } else {
            // Generic response for other codes
            mockResult.put('civilianOccupations', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'title' => 'Operations Manager',
                    'onetCode' => '11-1021.00',
                    'medianSalary' => 103650,
                    'outlook' => 'Average',
                    'matchScore' => 75
                }
            });
        }

        mockResult.put('militaryCode', militaryCode);
        mockResult.put('location', location);
        mockResult.put('generatedDate', DateTime.now().format());

        return mockResult;
    }

    private static List<CareerMatch> getMockSkillsMatching(String skills, String location) {
        List<CareerMatch> matches = new List<CareerMatch>();

        // Generate realistic career matches based on skills keywords
        if (skills.toLowerCase().contains('leadership') || skills.toLowerCase().contains('management')) {
            matches.add(new CareerMatch('Operations Manager', '11-1021.00', 103650, 'Average', 85, 'Strong leadership and organizational skills match'));
            matches.add(new CareerMatch('Project Manager', '11-9039.00', 118930, 'Faster than Average', 82, 'Leadership and coordination skills transfer well'));
        }

        if (skills.toLowerCase().contains('technical') || skills.toLowerCase().contains('maintenance')) {
            matches.add(new CareerMatch('Industrial Machinery Mechanic', '49-9041.00', 60000, 'Average', 88, 'Technical maintenance skills directly applicable'));
            matches.add(new CareerMatch('Maintenance Worker', '37-2011.00', 40850, 'Average', 85, 'Hands-on technical skills transfer'));
        }

        if (skills.toLowerCase().contains('communication') || skills.toLowerCase().contains('training')) {
            matches.add(new CareerMatch('Training Specialist', '13-1151.00', 66240, 'Faster than Average', 80, 'Training and communication experience valuable'));
        }

        // Always include a few generic matches
        matches.add(new CareerMatch('Administrative Assistant', '43-6011.00', 41000, 'Average', 70, 'Organizational and administrative skills'));

        return matches;
    }

    private static OccupationDetail getMockOccupationDetails(String occupation, String location) {
        OccupationDetail detail = new OccupationDetail();
        detail.title = occupation;
        detail.onetCode = '11-1021.00';
        detail.description = 'Plan, direct, or coordinate the operations of public or private sector organizations, overseeing multiple departments or locations.';
        detail.medianSalary = 103650;
        detail.salaryRange = '$65,000 - $165,000';
        detail.jobOutlook = 'Average (4% growth)';
        detail.educationRequired = 'Bachelor\'s degree';
        detail.workEnvironment = 'Office setting with occasional travel';
        detail.keySkills = new List<String>{'Leadership', 'Communication', 'Strategic Planning', 'Problem Solving'};
        detail.relatedOccupations = new List<String>{'General Manager', 'Executive', 'Director'};
        detail.location = location;
        detail.lastUpdated = DateTime.now();

        return detail;
    }

    private static List<JobOpportunity> getMockJobListings(String occupation, String location, Integer maxResults) {
        List<JobOpportunity> jobs = new List<JobOpportunity>();

        for (Integer i = 1; i <= Math.min(maxResults, 10); i++) {
            JobOpportunity job = new JobOpportunity();
            job.title = occupation + ' - Position ' + i;
            job.company = 'Company ' + i;
            job.location = location;
            job.salaryRange = '$' + (50000 + (i * 5000)) + ' - $' + (80000 + (i * 5000));
            job.description = 'Excellent opportunity for experienced ' + occupation.toLowerCase() + ' professional. We offer competitive compensation and benefits.';
            job.applicationUrl = 'https://careers.company' + i + '.com/job-' + i;
            job.postedDate = Date.today().addDays(-i);
            job.employmentType = i <= 3 ? 'Full-time' : (i <= 6 ? 'Part-time' : 'Contract');
            job.remote = Math.mod(i, 3) == 0;

            jobs.add(job);
        }

        return jobs;
    }

    // Helper methods for configuration, caching, and rate limiting

    private static CVMA_CareerOneStop_API_Config__mdt getAPIConfiguration(String apiName) {
        try {
            List<CVMA_CareerOneStop_API_Config__mdt> configs = [
                SELECT API_Endpoint_URL__c, API_Version__c, API_Key_Name__c, User_ID__c,
                       Is_Active__c, Max_Retry_Attempts__c, Timeout_Seconds__c,
                       Rate_Limit_Per_Hour__c, Rate_Limit_Per_Minute__c, Environment__c,
                       Cache_TTL_Minutes__c, Use_Mock_API__c, Enable_Caching__c,
                       Enable_Rate_Limiting__c, Circuit_Breaker_Threshold__c
                FROM CVMA_CareerOneStop_API_Config__mdt
                WHERE DeveloperName = :apiName
                AND Is_Active__c = TRUE
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            return configs.isEmpty() ? null : configs[0];
        } catch (QueryException ex) {
            CVMAErrorHandler.logError(ex, 'CVMACareerOneStopController', 'getAPIConfiguration',
                                    CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.INTEGRATION);
            return null;
        }
    }

    private static CVMA_CareerOneStop_API_Keys__c getAPIKeys(String environment) {
        try {
            CVMA_CareerOneStop_API_Keys__c keys = CVMA_CareerOneStop_API_Keys__c.getInstance(environment);
            if (keys == null) {
                keys = CVMA_CareerOneStop_API_Keys__c.getOrgDefaults();
            }

            if (keys == null || String.isBlank(keys.API_Key__c)) {
                throw new CVMAErrorHandler.IntegrationException('API keys not configured for environment: ' + environment);
            }

            return keys;
        } catch (Exception ex) {
            throw new CVMAErrorHandler.IntegrationException('Failed to retrieve API keys: ' + ex.getMessage());
        }
    }

    private static Boolean checkRateLimit(CVMA_CareerOneStop_API_Config__mdt config) {
        if (!config.Enable_Rate_Limiting__c) {
            return true;
        }

        String trackerId = config.DeveloperName;
        RateLimitTracker tracker = rateLimitTrackers.get(trackerId);

        if (tracker == null) {
            tracker = new RateLimitTracker();
            tracker.hourlyLimit = (Integer) config.Rate_Limit_Per_Hour__c;
            tracker.minuteLimit = (Integer) config.Rate_Limit_Per_Minute__c;
            tracker.hourlyResetTime = DateTime.now().addHours(1);
            tracker.minuteResetTime = DateTime.now().addMinutes(1);
            rateLimitTrackers.put(trackerId, tracker);
        }

        DateTime now = DateTime.now();

        // Reset counters if time windows have expired
        if (now >= tracker.hourlyResetTime) {
            tracker.hourlyCount = 0;
            tracker.hourlyResetTime = now.addHours(1);
        }

        if (now >= tracker.minuteResetTime) {
            tracker.minuteCount = 0;
            tracker.minuteResetTime = now.addMinutes(1);
        }

        // Check limits
        if (tracker.hourlyCount >= tracker.hourlyLimit || tracker.minuteCount >= tracker.minuteLimit) {
            return false;
        }

        // Increment counters
        tracker.hourlyCount++;
        tracker.minuteCount++;

        return true;
    }

    private static void trackAPIUsage(CVMA_CareerOneStop_API_Config__mdt config, Boolean success) {
        // Update API usage statistics
        if (config.Enable_Analytics__c) {
            // This could be expanded to write to a custom object for analytics
            System.debug('API Usage tracked for: ' + config.DeveloperName + ', Success: ' + success);
        }
    }

    private static Object getCachedResult(String cacheKey) {
        if (Cache.Org.contains(cacheKey)) {
            return Cache.Org.get(cacheKey);
        }
        return null;
    }

    private static void setCachedResult(String cacheKey, Object result, Integer ttlMinutes) {
        if (ttlMinutes == null) {
            ttlMinutes = DEFAULT_CACHE_TTL;
        }
        Cache.Org.put(cacheKey, result, ttlMinutes * 60); // Convert to seconds
    }

    // Parser methods for API responses

    private static List<CareerMatch> parseCareerMatches(List<Object> responseData) {
        List<CareerMatch> matches = new List<CareerMatch>();

        for (Object item : responseData) {
            Map<String, Object> matchData = (Map<String, Object>) item;
            CareerMatch match = new CareerMatch();
            match.occupationTitle = (String) matchData.get('title');
            match.onetCode = (String) matchData.get('onetCode');
            match.medianSalary = (Decimal) matchData.get('medianSalary');
            match.jobOutlook = (String) matchData.get('outlook');
            match.matchScore = (Integer) matchData.get('matchScore');
            match.matchReason = (String) matchData.get('reason');
            matches.add(match);
        }

        return matches;
    }

    private static OccupationDetail parseOccupationDetail(Map<String, Object> responseData) {
        OccupationDetail detail = new OccupationDetail();
        detail.title = (String) responseData.get('title');
        detail.onetCode = (String) responseData.get('onetCode');
        detail.description = (String) responseData.get('description');
        detail.medianSalary = (Decimal) responseData.get('medianSalary');
        detail.salaryRange = (String) responseData.get('salaryRange');
        detail.jobOutlook = (String) responseData.get('jobOutlook');
        detail.educationRequired = (String) responseData.get('education');
        detail.workEnvironment = (String) responseData.get('workEnvironment');
        detail.keySkills = (List<String>) responseData.get('skills');
        detail.relatedOccupations = (List<String>) responseData.get('relatedOccupations');
        detail.lastUpdated = DateTime.now();

        return detail;
    }

    private static List<JobOpportunity> parseJobOpportunities(List<Object> jobsData) {
        List<JobOpportunity> opportunities = new List<JobOpportunity>();

        for (Object item : jobsData) {
            Map<String, Object> jobData = (Map<String, Object>) item;
            JobOpportunity job = new JobOpportunity();
            job.title = (String) jobData.get('title');
            job.company = (String) jobData.get('company');
            job.location = (String) jobData.get('location');
            job.salaryRange = (String) jobData.get('salary');
            job.description = (String) jobData.get('description');
            job.applicationUrl = (String) jobData.get('applicationUrl');
            job.postedDate = Date.valueOf((String) jobData.get('postedDate'));
            job.employmentType = (String) jobData.get('employmentType');
            job.remote = (Boolean) jobData.get('remote');
            opportunities.add(job);
        }

        return opportunities;
    }

    // Data classes for structured responses

    public class CareerMatch {
        @AuraEnabled public String occupationTitle { get; set; }
        @AuraEnabled public String onetCode { get; set; }
        @AuraEnabled public Decimal medianSalary { get; set; }
        @AuraEnabled public String jobOutlook { get; set; }
        @AuraEnabled public Integer matchScore { get; set; }
        @AuraEnabled public String matchReason { get; set; }

        public CareerMatch() {}

        public CareerMatch(String title, String code, Decimal salary, String outlook, Integer score, String reason) {
            this.occupationTitle = title;
            this.onetCode = code;
            this.medianSalary = salary;
            this.jobOutlook = outlook;
            this.matchScore = score;
            this.matchReason = reason;
        }
    }

    public class OccupationDetail {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String onetCode { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Decimal medianSalary { get; set; }
        @AuraEnabled public String salaryRange { get; set; }
        @AuraEnabled public String jobOutlook { get; set; }
        @AuraEnabled public String educationRequired { get; set; }
        @AuraEnabled public String workEnvironment { get; set; }
        @AuraEnabled public List<String> keySkills { get; set; }
        @AuraEnabled public List<String> relatedOccupations { get; set; }
        @AuraEnabled public String location { get; set; }
        @AuraEnabled public DateTime lastUpdated { get; set; }
    }

    public class JobOpportunity {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String company { get; set; }
        @AuraEnabled public String location { get; set; }
        @AuraEnabled public String salaryRange { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String applicationUrl { get; set; }
        @AuraEnabled public Date postedDate { get; set; }
        @AuraEnabled public String employmentType { get; set; }
        @AuraEnabled public Boolean remote { get; set; }
    }

    public class CareerTransitionPackage {
        @AuraEnabled public Map<String, Object> militaryTranslation { get; set; }
        @AuraEnabled public List<CareerMatch> skillsMatches { get; set; }
        @AuraEnabled public List<JobOpportunity> localJobs { get; set; }
        @AuraEnabled public OccupationDetail occupationDetails { get; set; }
        @AuraEnabled public DateTime generatedDate { get; set; }
        @AuraEnabled public String veteranLocation { get; set; }
    }

    private class RateLimitTracker {
        public Integer hourlyLimit { get; set; }
        public Integer minuteLimit { get; set; }
        public Integer hourlyCount { get; set; }
        public Integer minuteCount { get; set; }
        public DateTime hourlyResetTime { get; set; }
        public DateTime minuteResetTime { get; set; }

        public RateLimitTracker() {
            this.hourlyCount = 0;
            this.minuteCount = 0;
        }
    }
}
