/**
 * Helper class for CVMA guest user appointment booking functionality
 * Provides business logic for ServiceAppointment creation and management
 */
public class CVMASchedulerBookingHelper {
    
    // Appointment status constants
    public static final String STATUS_SCHEDULED = 'Scheduled';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_CANCELED = 'Canceled';
    public static final String STATUS_PENDING = 'Pending';
    
    // Validation constants
    public static final Integer MAX_APPOINTMENT_DURATION_HOURS = 8;
    public static final Integer MIN_APPOINTMENT_DURATION_MINUTES = 15;
    public static final Integer ADVANCE_BOOKING_DAYS = 90;
    
    /**
     * Creates a new Service Appointment for guest users
     */
    public static Id createGuestAppointment(AppointmentRequest request) {
        if (!validateAppointmentRequest(request)) {
            throw new CVMASchedulerException('Invalid appointment request');
        }
        
        ServiceAppointment appointment = buildServiceAppointment(request);
        
        try {
            insert appointment;
            return appointment.Id;
        } catch (DmlException e) {
            throw new CVMASchedulerException('Failed to create appointment: ' + e.getMessage());
        }
    }
    
    /**
     * Updates an existing Service Appointment
     */
    public static Boolean updateGuestAppointment(Id appointmentId, AppointmentRequest request) {
        if (appointmentId == null || !validateAppointmentRequest(request)) {
            return false;
        }
        
        try {
            ServiceAppointment existing = [
                SELECT Id, Status, SchedStartTime 
                FROM ServiceAppointment 
                WHERE Id = :appointmentId 
                LIMIT 1
            ];
            
            if (!isAppointmentModifiable(existing)) {
                return false;
            }
            
            updateAppointmentFields(existing, request);
            update existing;
            return true;
            
        } catch (Exception e) {
            System.debug('Appointment update error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Validates if appointment can be booked in requested time slot
     */
    public static Boolean isTimeSlotAvailable(DateTime startTime, DateTime endTime, Id serviceTerritoryId) {
        if (startTime == null || endTime == null || serviceTerritoryId == null) {
            return false;
        }
        
        // Check for conflicts with existing appointments
        List<ServiceAppointment> conflicts = [
            SELECT Id, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE ServiceTerritoryId = :serviceTerritoryId
            AND Status != :STATUS_CANCELED
            AND ((SchedStartTime <= :startTime AND SchedEndTime > :startTime)
                OR (SchedStartTime < :endTime AND SchedEndTime >= :endTime)
                OR (SchedStartTime >= :startTime AND SchedEndTime <= :endTime))
        ];
        
        return conflicts.isEmpty();
    }
    
    /**
     * Gets available time slots for a given date and service territory
     */
    public static List<TimeSlot> getAvailableTimeSlots(Date appointmentDate, Id serviceTerritoryId) {
        List<TimeSlot> availableSlots = new List<TimeSlot>();
        
        if (appointmentDate == null || serviceTerritoryId == null) {
            return availableSlots;
        }
        
        // Get operating hours for the territory
        List<OperatingHours> opHours = getOperatingHours(serviceTerritoryId);
        if (opHours.isEmpty()) {
            return availableSlots;
        }
        
        // Generate time slots based on operating hours
        DateTime dayStart = DateTime.newInstance(appointmentDate, Time.newInstance(9, 0, 0, 0));
        DateTime dayEnd = DateTime.newInstance(appointmentDate, Time.newInstance(17, 0, 0, 0));
        
        // Create hourly slots
        DateTime currentSlot = dayStart;
        while (currentSlot < dayEnd) {
            DateTime slotEnd = currentSlot.addHours(1);
            
            if (isTimeSlotAvailable(currentSlot, slotEnd, serviceTerritoryId)) {
                availableSlots.add(new TimeSlot(currentSlot, slotEnd));
            }
            
            currentSlot = slotEnd;
        }
        
        return availableSlots;
    }
    
    /**
     * Cancels an appointment
     */
    public static Boolean cancelAppointment(Id appointmentId, String cancellationReason) {
        if (appointmentId == null) {
            return false;
        }
        
        try {
            ServiceAppointment appointment = [
                SELECT Id, Status, SchedStartTime
                FROM ServiceAppointment 
                WHERE Id = :appointmentId 
                LIMIT 1
            ];
            
            if (!isAppointmentCancellable(appointment)) {
                return false;
            }
            
            appointment.Status = STATUS_CANCELED;
            appointment.CancellationReason = cancellationReason;
            update appointment;
            
            return true;
        } catch (Exception e) {
            System.debug('Appointment cancellation error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Gets guest user's upcoming appointments
     */
    public static List<ServiceAppointment> getGuestAppointments(String guestEmail) {
        if (String.isBlank(guestEmail)) {
            return new List<ServiceAppointment>();
        }
        
        try {
            return [
                SELECT Id, Subject, SchedStartTime, SchedEndTime, Status, Description, Phone
                FROM ServiceAppointment
                WHERE Email = :guestEmail
                AND SchedStartTime >= :DateTime.now()
                AND Status != :STATUS_CANCELED
                ORDER BY SchedStartTime ASC
                LIMIT 10
            ];
        } catch (Exception e) {
            System.debug('Error retrieving guest appointments: ' + e.getMessage());
            return new List<ServiceAppointment>();
        }
    }
    
    // Private helper methods and inner classes
    
    /**
     * Validates appointment request
     */
    private static Boolean validateAppointmentRequest(AppointmentRequest request) {
        if (request == null) return false;
        if (String.isBlank(request.subject)) return false;
        if (request.startTime == null || request.endTime == null) return false;
        if (request.startTime >= request.endTime) return false;
        if (request.startTime < DateTime.now()) return false;
        
        // Check duration limits
        Long durationMinutes = (request.endTime.getTime() - request.startTime.getTime()) / (1000 * 60);
        if (durationMinutes < MIN_APPOINTMENT_DURATION_MINUTES) return false;
        if (durationMinutes > (MAX_APPOINTMENT_DURATION_HOURS * 60)) return false;
        
        // Check advance booking limit
        Date maxBookingDate = Date.today().addDays(ADVANCE_BOOKING_DAYS);
        if (request.startTime.date() > maxBookingDate) return false;
        
        return true;
    }
    
    /**
     * Builds ServiceAppointment from request
     */
    private static ServiceAppointment buildServiceAppointment(AppointmentRequest request) {
        ServiceAppointment appointment = new ServiceAppointment();
        appointment.Subject = request.subject;
        appointment.SchedStartTime = request.startTime;
        appointment.SchedEndTime = request.endTime;
        appointment.Status = STATUS_PENDING;
        appointment.Description = request.description;
        appointment.Email = request.email;
        appointment.Phone = request.phone;
        
        if (request.serviceTerritoryId != null) {
            appointment.ServiceTerritoryId = request.serviceTerritoryId;
        }
        
        if (request.workTypeId != null) {
            appointment.WorkTypeId = request.workTypeId;
        }
        
        if (request.contactId != null) {
            appointment.ContactId = request.contactId;
        }
        
        if (request.parentRecordId != null) {
            appointment.ParentRecordId = request.parentRecordId;
        }
        
        return appointment;
    }
    
    /**
     * Checks if appointment can be modified
     */
    private static Boolean isAppointmentModifiable(ServiceAppointment appointment) {
        if (appointment.Status == STATUS_COMPLETED || appointment.Status == STATUS_CANCELED) {
            return false;
        }
        
        // Can't modify appointments starting within 2 hours
        DateTime cutoffTime = DateTime.now().addHours(2);
        return appointment.SchedStartTime > cutoffTime;
    }
    
    /**
     * Checks if appointment can be cancelled
     */
    private static Boolean isAppointmentCancellable(ServiceAppointment appointment) {
        if (appointment.Status == STATUS_COMPLETED || appointment.Status == STATUS_CANCELED) {
            return false;
        }
        
        // Can cancel up to 1 hour before start time
        DateTime cutoffTime = DateTime.now().addHours(1);
        return appointment.SchedStartTime > cutoffTime;
    }
    
    /**
     * Updates appointment fields from request
     */
    private static void updateAppointmentFields(ServiceAppointment appointment, AppointmentRequest request) {
        appointment.Subject = request.subject;
        appointment.SchedStartTime = request.startTime;
        appointment.SchedEndTime = request.endTime;
        appointment.Description = request.description;
        appointment.Phone = request.phone;
    }
    
    /**
     * Gets operating hours for service territory
     */
    private static List<OperatingHours> getOperatingHours(Id serviceTerritoryId) {
        try {
            List<ServiceTerritory> territories = [
                SELECT Id, OperatingHoursId
                FROM ServiceTerritory 
                WHERE Id = :serviceTerritoryId 
                LIMIT 1
            ];
            
            if (territories.isEmpty() || territories[0].OperatingHoursId == null) {
                return new List<OperatingHours>();
            }
            
            return [
                SELECT Id, Name, TimeZone
                FROM OperatingHours 
                WHERE Id = :territories[0].OperatingHoursId
            ];
        } catch (Exception e) {
            return new List<OperatingHours>();
        }
    }
    
    // Inner classes for data structures
    
    /**
     * Wrapper class for appointment requests
     */
    public class AppointmentRequest {
        public String subject;
        public DateTime startTime;
        public DateTime endTime;
        public String description;
        public String email;
        public String phone;
        public Id serviceTerritoryId;
        public Id workTypeId;
        public Id contactId;
        public Id parentRecordId;
        
        public AppointmentRequest() {}
        
        public AppointmentRequest(String subj, DateTime start, DateTime endDt) {
            this.subject = subj;
            this.startTime = start;
            this.endTime = endDt;
        }
    }
    
    /**
     * Wrapper class for time slots
     */
    public class TimeSlot {
        public DateTime startTime;
        public DateTime endTime;
        public Boolean isAvailable;
        
        public TimeSlot(DateTime start, DateTime endDt) {
            this.startTime = start;
            this.endTime = endDt;
            this.isAvailable = true;
        }
    }
    
    /**
     * Custom exception for scheduler operations
     */
    public class CVMASchedulerException extends Exception {}
}