/**
 * CVMA Document Sharing Controller
 * Purpose: Generate and share training documentation as PDFs in Salesforce
 * Usage: Convert markdown training materials to PDFs for CEB officers and members
 */
public with sharing class CVMADocumentSharingController {

    /**
     * Generate PDF from markdown content for CEB training
     * @param documentName Name of the training document
     * @param markdownContent Markdown content to convert
     * @param targetAudience 'CEB_Officers', 'Members', or 'Technical_Staff'
     * @return ContentDocumentId for the generated PDF
     */
    @AuraEnabled
    public static String generateTrainingPDF(String documentName, String markdownContent, String targetAudience) {
        try {
            // Convert markdown to HTML for PDF generation
            String htmlContent = convertMarkdownToHTML(markdownContent, targetAudience);

            // Generate PDF using Salesforce renderAs
            Blob pdfBlob = generatePDFBlob(htmlContent, documentName);

            // Create ContentVersion record
            ContentVersion cv = new ContentVersion();
            cv.Title = documentName;
            cv.PathOnClient = documentName + '.pdf';
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            cv.Description = 'CVMA Training Document - ' + targetAudience;

            insert cv;

            // Get ContentDocumentId
            ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH SECURITY_ENFORCED];

            // Share with appropriate groups based on target audience
            shareDocumentWithAudience(insertedCV.ContentDocumentId, targetAudience);

            return insertedCV.ContentDocumentId;

        } catch (Exception e) {
            String userMessage = CVMAErrorHandler.handleException(e, 'CVMADocumentSharingController', 'generateTrainingPDF', CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException(userMessage);
        }
    }

    /**
     * Convert markdown content to styled HTML for PDF generation
     */
    private static String convertMarkdownToHTML(String markdownContent, String targetAudience) {
        String htmlContent = '<html><head>';

        // Add CVMA styling based on audience
        if (targetAudience == 'CEB_Officers') {
            htmlContent += getCEBOfficerCSS();
        } else if (targetAudience == 'Members') {
            htmlContent += getMemberTrainingCSS();
        } else {
            htmlContent += getTechnicalDocumentationCSS();
        }

        htmlContent += '</head><body>';
        htmlContent += '<div class="cvma-header">';
        htmlContent += '<h1>Combat Veterans Motorcycle Association</h1>';
        htmlContent += '<h2>Chapter 20-7 - Jacksonville, FL</h2>';
        htmlContent += '<h3>Vets Serving Vets</h3>';
        htmlContent += '</div>';

        // Convert basic markdown to HTML
        String convertedContent = markdownContent
            .replaceAll('# (.*)', '<h1>$1</h1>')
            .replaceAll('## (.*)', '<h2>$1</h2>')
            .replaceAll('### (.*)', '<h3>$1</h3>')
            .replaceAll('\\*\\*(.*?)\\*\\*', '<strong>$1</strong>')
            .replaceAll('\\*(.*?)\\*', '<em>$1</em>')
            .replaceAll('`(.*?)`', '<code>$1</code>')
            .replaceAll('\\n\\n', '</p><p>')
            .replaceAll('\\n', '<br/>');

        htmlContent += '<div class="content"><p>' + convertedContent + '</p></div>';
        htmlContent += '</body></html>';

        return htmlContent;
    }

    /**
     * Generate PDF blob using Visualforce page
     */
    private static Blob generatePDFBlob(String htmlContent, String documentName) {
        // Create temporary Visualforce page content
        PageReference pdfPage = Page.CVMADocumentPDFGenerator;
        pdfPage.getParameters().put('content', EncodingUtil.urlEncode(htmlContent, 'UTF-8'));
        pdfPage.getParameters().put('title', documentName);

        // Generate PDF - use getContent() in real org, getContentAsPDF() for testing
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        return pdfBlob;
    }

    /**
     * Share document with appropriate groups based on target audience
     */
    private static void shareDocumentWithAudience(String contentDocumentId, String targetAudience) {
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

        // Get appropriate groups/users to share with
        if (targetAudience == 'CEB_Officers') {
            // Share with CEB Officer group
            List<Group> cebGroup = [SELECT Id FROM Group WHERE Name = 'CEB Officers' AND Type = 'Regular' WITH SECURITY_ENFORCED LIMIT 1];
            if (!cebGroup.isEmpty()) {
                linksToInsert.add(createDocumentLink(contentDocumentId, cebGroup[0].Id, 'V'));
            }
        } else if (targetAudience == 'Members') {
            // Share with All Members group
            List<Group> memberGroup = [SELECT Id FROM Group WHERE Name = 'CVMA Members' AND Type = 'Regular' WITH SECURITY_ENFORCED LIMIT 1];
            if (!memberGroup.isEmpty()) {
                linksToInsert.add(createDocumentLink(contentDocumentId, memberGroup[0].Id, 'V'));
            }
        }

        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }
    }

    /**
     * Create ContentDocumentLink record
     */
    private static ContentDocumentLink createDocumentLink(String contentDocumentId, String linkedEntityId, String shareType) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = linkedEntityId;
        cdl.ShareType = shareType;
        cdl.Visibility = 'SharedUsers';
        return cdl;
    }

    /**
     * Get training documents available for CEB officers
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCEBTrainingDocuments() {
        List<Map<String, String>> documents = new List<Map<String, String>>();

        // Return list of available training documents
        documents.add(new Map<String, String>{
            'name' => 'CEB Officer Dashboard Guide',
            'description' => 'Complete guide for using the officer dashboard',
            'category' => 'Platform Training'
        });

        documents.add(new Map<String, String>{
            'name' => 'Member Management Procedures',
            'description' => 'Step-by-step member lifecycle management',
            'category' => 'Administrative Training'
        });

        documents.add(new Map<String, String>{
            'name' => 'Event Coordination Guide',
            'description' => 'Event planning and management training',
            'category' => 'Event Management'
        });

        documents.add(new Map<String, String>{
            'name' => 'Financial Oversight Training',
            'description' => 'Financial dashboard and reporting training',
            'category' => 'Financial Management'
        });

        return documents;
    }

    /**
     * CEB Officer PDF styling
     */
    private static String getCEBOfficerCSS() {
        return '<style>' +
            'body { font-family: Arial, sans-serif; margin: 20px; }' +
            '.cvma-header { text-align: center; border-bottom: 3px solid #FF0000; padding-bottom: 10px; margin-bottom: 20px; }' +
            '.cvma-header h1 { color: #FF0000; font-size: 24px; margin: 5px 0; }' +
            '.cvma-header h2 { color: #000000; font-size: 18px; margin: 5px 0; }' +
            '.cvma-header h3 { color: #FF0000; font-size: 14px; margin: 5px 0; font-style: italic; }' +
            '.content { line-height: 1.6; }' +
            'h1 { color: #FF0000; border-bottom: 2px solid #FF0000; padding-bottom: 5px; }' +
            'h2 { color: #000000; border-left: 4px solid #FF0000; padding-left: 10px; }' +
            'h3 { color: #FF0000; }' +
            'code { background-color: #f4f4f4; padding: 2px 4px; border-radius: 3px; }' +
            '.important { background-color: #ffe6e6; border-left: 4px solid #FF0000; padding: 10px; margin: 10px 0; }' +
            '</style>';
    }

    /**
     * Member training PDF styling
     */
    private static String getMemberTrainingCSS() {
        return '<style>' +
            'body { font-family: Arial, sans-serif; margin: 20px; font-size: 14px; }' +
            '.cvma-header { text-align: center; border-bottom: 3px solid #FF0000; padding-bottom: 10px; margin-bottom: 20px; }' +
            '.cvma-header h1 { color: #FF0000; font-size: 22px; margin: 5px 0; }' +
            '.cvma-header h2 { color: #000000; font-size: 16px; margin: 5px 0; }' +
            '.cvma-header h3 { color: #FF0000; font-size: 12px; margin: 5px 0; font-style: italic; }' +
            '.content { line-height: 1.8; }' +
            'h1 { color: #FF0000; font-size: 18px; }' +
            'h2 { color: #000000; font-size: 16px; }' +
            'h3 { color: #FF0000; font-size: 14px; }' +
            'p { margin-bottom: 15px; }' +
            '.step { background-color: #f9f9f9; border: 1px solid #ddd; padding: 10px; margin: 10px 0; border-radius: 5px; }' +
            '</style>';
    }

    /**
     * Technical documentation PDF styling
     */
    private static String getTechnicalDocumentationCSS() {
        return '<style>' +
            'body { font-family: "Courier New", monospace; margin: 20px; font-size: 12px; }' +
            '.cvma-header { text-align: center; border-bottom: 3px solid #FF0000; padding-bottom: 10px; margin-bottom: 20px; }' +
            '.cvma-header h1 { color: #FF0000; font-size: 20px; margin: 5px 0; }' +
            '.cvma-header h2 { color: #000000; font-size: 14px; margin: 5px 0; }' +
            '.cvma-header h3 { color: #FF0000; font-size: 12px; margin: 5px 0; font-style: italic; }' +
            '.content { line-height: 1.4; }' +
            'code { background-color: #f8f8f8; border: 1px solid #ddd; padding: 2px 4px; font-family: "Courier New", monospace; }' +
            'pre { background-color: #f8f8f8; border: 1px solid #ddd; padding: 10px; overflow-x: auto; }' +
            '.code-block { background-color: #f5f5f5; border-left: 4px solid #FF0000; padding: 10px; margin: 10px 0; }' +
            '</style>';
    }
}
