package com.vivaahaverse.vivaahaverse.repository;

import com.vivaahaverse.vivaahaverse.model.Booking;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface BookingRepository extends MongoRepository<Booking, String> {
    // My Bookings (Things I have booked for my wedding)
    List<Booking> findByClientId(String clientId);

    // My Orders (Things people booked from me)
    List<Booking> findByVendorId(String vendorId);
}