<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>DNBI__Send_Credit_Status_Change_Notification_Account</fullName>
        <description>Send Credit Status Change Notification for Account</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>DNBI__DNBI_email_Templates/DNBI__DNBI_Credit_Information_Update_for_Account</template>
    </alerts>
    <rules>
        <fullName>DNBI__Account Credit Status Change</fullName>
        <actions>
            <name>DNBI__Send_Credit_Status_Change_Notification_Account</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>Account Credit Status Change notification email</description>
        <formula>AND(ISCHANGED(DNBI__DnB_Application_Modified_Date__c),  $Setup.DNBI__EnableStatusEmailNotification1__c.DNBI__Enable_Email_Notification__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
