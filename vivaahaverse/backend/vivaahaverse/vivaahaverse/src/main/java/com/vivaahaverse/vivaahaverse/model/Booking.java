package com.vivaahaverse.vivaahaverse.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.util.Date;

@Data
@Document(collection = "bookings")
public class Booking {
    @Id
    private String id;
    private String serviceId;      // Which service ID was booked
    private String serviceName;    // Snapshot of the service name
    private String category;       // "Food", "Hall"
    private String clientId;       // The User ID of the person engaging the service (Customer)
    private String vendorId;       // The User ID of the service provider (Vendor)
    private Double amount;

    // NEW: Date Range
    private Date startDate;
    private Date endDate;

    private String status; // "CONFIRMED", "CANCELLED"
    private Date bookedAt;

    // NEW: Cancellation Info
    private String cancelledBy; // "CLIENT" or "VENDOR"
    private String cancellationReason;

}