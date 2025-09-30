# Campaign Member Status Setup for RSVP System

## Required Manual Configuration in Salesforce

### 1. Campaign Member Status Values Setup
Navigate to: **Setup → Object Manager → Campaign → Fields & Relationships → Member Status**

#### Add the following Campaign Member Status values:

| **Status Value** | **Type** | **Default** | **Description** |
|------------------|----------|-------------|-----------------|
| Sent | Sent | ✅ Yes | Initial invite status (existing) |
| Responded - Yes | Responded | No | Confirmed attendance |
| Responded - No | Responded | No | Declined attendance |
| Responded - Maybe | Responded | No | Tentative attendance |
| Plus One - Yes | Responded | No | Attending with plus one |

### 2. Campaign Member Custom Fields
Navigate to: **Setup → Object Manager → Campaign Member → Fields & Relationships**

#### Create the following custom fields:

```xml
<!-- Plus One Checkbox -->
<CustomField>
    <fullName>CVMA_Plus_One__c</fullName>
    <defaultValue>false</defaultValue>
    <description>Indicates if member is bringing a plus one to the event</description>
    <label>Plus One</label>
    <type>Checkbox</type>
</CustomField>

<!-- Plus One Name -->
<CustomField>
    <fullName>CVMA_Plus_One_Name__c</fullName>
    <description>Name of the plus one guest</description>
    <label>Plus One Name</label>
    <length>100</length>
    <type>Text</type>
</CustomField>

<!-- RSVP Notes -->
<CustomField>
    <fullName>CVMA_RSVP_Notes__c</fullName>
    <description>Additional notes for the RSVP</description>
    <label>RSVP Notes</label>
    <length>1000</length>
    <type>LongTextArea</type>
    <visibleLines>3</visibleLines>
</CustomField>

<!-- Original RSVP Date -->
<CustomField>
    <fullName>CVMA_Original_RSVP_Date__c</fullName>
    <description>Original RSVP timestamp from migration</description>
    <label>Original RSVP Date</label>
    <type>DateTime</type>
</CustomField>
```

### 3. Status Mapping Configuration

| **Original RSVP Response** | **Campaign Member Status** | **Plus One Handling** |
|----------------------------|-----------------------------|------------------------|
| "Yes" (no plus one) | "Responded - Yes" | CVMA_Plus_One__c = false |
| "Yes" (with plus one) | "Plus One - Yes" | CVMA_Plus_One__c = true |
| "No" | "Responded - No" | CVMA_Plus_One__c = false |
| "Maybe" | "Responded - Maybe" | CVMA_Plus_One__c = false |

### 4. Permission Set Updates
Add field permissions for new Campaign Member fields to relevant permission sets:
- CVMA_Member (read access)
- CVMA_Officer (read/write access)
- CVMA_Treasurer (read access)

### 5. Page Layout Updates
Update Campaign Member page layouts to include new CVMA fields in appropriate sections.
