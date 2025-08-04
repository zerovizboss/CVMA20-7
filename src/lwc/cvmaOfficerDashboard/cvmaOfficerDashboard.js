import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMemberDashboardData from '@salesforce/apex/CVMAOfficerDashboardController.getMemberDashboardData';
import exportMemberData from '@salesforce/apex/CVMAOfficerDashboardController.exportMemberData';
import sendRenewalReminders from '@salesforce/apex/CVMAOfficerDashboardController.sendRenewalReminders';

export default class CvmaOfficerDashboard extends LightningElement {
    @track isLoading = false;
    @track dashboardData = {};
    @track members = [];
    @track filteredMembers = [];
    @track searchTerm = '';
    @track statusFilter = 'All';
    @track selectedMembers = [];
    @track showExportModal = false;
    @track showReminderModal = false;

    // Status filter options
    statusOptions = [
        { label: 'All Members', value: 'All' },
        { label: 'Active', value: 'Active' },
        { label: 'Renewal Due (30 days)', value: 'Due30' },
        { label: 'Renewal Due (60 days)', value: 'Due60' },
        { label: 'Renewal Due (90 days)', value: 'Due90' },
        { label: 'Expired', value: 'Expired' },
        { label: 'New Members (90 days)', value: 'New' }
    ];

    // Columns for member data table
    columns = [
        { 
            label: 'Member Name', 
            fieldName: 'memberUrl', 
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'fullName' },
                target: '_blank'
            },
            sortable: true
        },
        { label: 'Membership ID', fieldName: 'membershipId', type: 'text', sortable: true },
        { label: 'Level', fieldName: 'level', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'status', type: 'text', sortable: true },
        { label: 'Join Date', fieldName: 'joinDate', type: 'date', sortable: true },
        { label: 'End Date', fieldName: 'endDate', type: 'date', sortable: true },
        { label: 'Days to Renewal', fieldName: 'daysToRenewal', type: 'number', sortable: true },
        { label: 'Email', fieldName: 'email', type: 'email' },
        { label: 'Phone', fieldName: 'phone', type: 'phone' }
    ];

    @wire(getMemberDashboardData)
    wiredDashboardData({ error, data }) {
        if (data) {
            this.dashboardData = data.dashboardStats;
            this.members = data.members.map(member => ({
                ...member,
                memberUrl: `/lightning/r/Contact/${member.contactId}/view`,
                fullName: `${member.firstName} ${member.lastName}`.trim()
            }));
            this.filterMembers();
        } else if (error) {
            this.showToast('Error', 'Error loading dashboard data: ' + error.body.message, 'error');
        }
    }

    get dashboardStats() {
        return [
            { label: 'Total Members', value: this.dashboardData.totalMembers || 0, variant: 'base' },
            { label: 'Active Members', value: this.dashboardData.activeMembers || 0, variant: 'base' },
            { label: 'Due in 30 Days', value: this.dashboardData.due30Days || 0, variant: 'warning' },
            { label: 'Due in 60 Days', value: this.dashboardData.due60Days || 0, variant: 'warning' },
            { label: 'Expired', value: this.dashboardData.expiredMembers || 0, variant: 'error' },
            { label: 'New Members', value: this.dashboardData.newMembers || 0, variant: 'success' }
        ];
    }

    get hasMembers() {
        return this.filteredMembers && this.filteredMembers.length > 0;
    }

    get selectedMembersCount() {
        return this.selectedMembers.length;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterMembers();
    }

    handleStatusFilter(event) {
        this.statusFilter = event.detail.value;
        this.filterMembers();
    }

    filterMembers() {
        let filtered = [...this.members];

        // Apply search filter
        if (this.searchTerm) {
            filtered = filtered.filter(member => 
                member.fullName.toLowerCase().includes(this.searchTerm) ||
                member.membershipId.toLowerCase().includes(this.searchTerm) ||
                member.email.toLowerCase().includes(this.searchTerm)
            );
        }

        // Apply status filter
        if (this.statusFilter !== 'All') {
            filtered = filtered.filter(member => {
                switch (this.statusFilter) {
                    case 'Active':
                        return member.status === 'Active';
                    case 'Due30':
                        return member.daysToRenewal <= 30 && member.daysToRenewal > 0;
                    case 'Due60':
                        return member.daysToRenewal <= 60 && member.daysToRenewal > 0;
                    case 'Due90':
                        return member.daysToRenewal <= 90 && member.daysToRenewal > 0;
                    case 'Expired':
                        return member.status === 'Expired';
                    case 'New':
                        return member.daysSinceJoin <= 90;
                    default:
                        return true;
                }
            });
        }

        this.filteredMembers = filtered;
    }

    handleRowSelection(event) {
        this.selectedMembers = event.detail.selectedRows;
    }

    handleExportMembers() {
        if (this.filteredMembers.length === 0) {
            this.showToast('Warning', 'No members to export with current filters', 'warning');
            return;
        }
        this.showExportModal = true;
    }

    handleExportConfirm() {
        this.isLoading = true;
        const memberIds = this.filteredMembers.map(member => member.contactId);
        
        exportMemberData({ memberIds: memberIds })
            .then(result => {
                // Create and download CSV file
                const csvContent = result;
                const element = document.createElement('a');
                element.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent));
                element.setAttribute('download', `CVMA_Members_${new Date().toISOString().split('T')[0]}.csv`);
                element.style.display = 'none';
                document.body.appendChild(element);
                element.click();
                document.body.removeChild(element);
                
                this.showToast('Success', 'Member data exported successfully', 'success');
                this.showExportModal = false;
            })
            .catch(error => {
                this.showToast('Error', 'Error exporting member data: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSendReminders() {
        const renewalDueMembers = this.members.filter(member => 
            member.daysToRenewal <= 90 && member.daysToRenewal > 0
        );
        
        if (renewalDueMembers.length === 0) {
            this.showToast('Warning', 'No members found with upcoming renewals', 'warning');
            return;
        }
        this.showReminderModal = true;
    }

    handleReminderConfirm() {
        this.isLoading = true;
        const memberIds = this.members
            .filter(member => member.daysToRenewal <= 90 && member.daysToRenewal > 0)
            .map(member => member.contactId);

        sendRenewalReminders({ memberIds: memberIds })
            .then(result => {
                this.showToast('Success', `Renewal reminders sent to ${result} members`, 'success');
                this.showReminderModal = false;
            })
            .catch(error => {
                this.showToast('Error', 'Error sending reminders: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCloseModal() {
        this.showExportModal = false;
        this.showReminderModal = false;
    }

    handleRefresh() {
        // Refresh the wire service data
        return refreshApex(this.wiredDashboardData);
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}