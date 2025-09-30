// CVMA Seed Data Creation Script
// Execute in Anonymous Apex to create test data for UAT

// Create sample CVMA Events (Campaigns)
List<Campaign> events = new List<Campaign>();

events.add(new Campaign(
    Name = 'Monthly Chapter Meeting - October',
    Type = 'CVMA Event',
    Status = 'Planned',
    StartDate = Date.today().addDays(7),
    EndDate = Date.today().addDays(7),
    Description = 'Monthly chapter meeting for all CVMA members',
    NumberSent = 50,
    IsActive = true
));

events.add(new Campaign(
    Name = 'Veterans Day Ride 2025',
    Type = 'CVMA Event',
    Status = 'Planned',
    StartDate = Date.today().addDays(30),
    EndDate = Date.today().addDays(30),
    Description = 'Annual Veterans Day memorial ride',
    NumberSent = 200,
    IsActive = true
));

events.add(new Campaign(
    Name = 'Charity Fundraiser Poker Run',
    Type = 'CVMA Event',
    Status = 'In Progress',
    StartDate = Date.today().addDays(-5),
    EndDate = Date.today().addDays(2),
    Description = 'Fundraising event for local veteran support',
    NumberSent = 75,
    IsActive = true
));

insert events;

// Create sample Contacts for Financial Dashboard
List<Contact> members = new List<Contact>();

members.add(new Contact(
    FirstName = 'John',
    LastName = 'Smith',
    Level__c = 'Full Member',
    Email = 'john.smith@cvma.org',
    Phone = '555-0101'
));

members.add(new Contact(
    FirstName = 'Sarah',
    LastName = 'Johnson',
    Level__c = 'Associate Member',
    Email = 'sarah.johnson@cvma.org',
    Phone = '555-0102'
));

members.add(new Contact(
    FirstName = 'Mike',
    LastName = 'Williams',
    Level__c = 'Prospect',
    Email = 'mike.williams@cvma.org',
    Phone = '555-0103'
));

insert members;

// Create sample Opportunities (NPSP Donations/Dues)
List<Opportunity> donations = new List<Opportunity>();

for(Contact member : members) {
    donations.add(new Opportunity(
        Name = member.FirstName + ' ' + member.LastName + ' - Annual Dues 2025',
        ContactId = member.Id,
        Amount = member.Level__c == 'Full Member' ? 120.00 :
                (member.Level__c == 'Associate Member' ? 60.00 : 30.00),
        CloseDate = Date.today().addDays(30),
        StageName = 'Pledged',
        Type = 'Dues Payment',
        Description = 'Annual chapter dues payment'
    ));
}

insert donations;

// Create sample NPSP Recurring Donations
List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();

for(Contact member : members) {
    recurringDonations.add(new npe03__Recurring_Donation__c(
        Name = member.FirstName + ' ' + member.LastName + ' - Monthly Dues',
        npe03__Contact__c = member.Id,
        npe03__Amount__c = member.Level__c == 'Full Member' ? 10.00 : 5.00,
        npe03__Installments__c = 12,
        npe03__Installment_Period__c = 'Monthly',
        npe03__Date_Established__c = Date.today().addDays(-30),
        npe03__Schedule_Type__c = 'Multiply By',
        npe03__Open_Ended_Status__c = 'Open'
    ));
}

insert recurringDonations;

System.debug('✅ CVMA Seed Data Created Successfully');
System.debug('- ' + events.size() + ' Campaign Events');
System.debug('- ' + members.size() + ' Member Contacts');
System.debug('- ' + donations.size() + ' Opportunities');
System.debug('- ' + recurringDonations.size() + ' Recurring Donations');