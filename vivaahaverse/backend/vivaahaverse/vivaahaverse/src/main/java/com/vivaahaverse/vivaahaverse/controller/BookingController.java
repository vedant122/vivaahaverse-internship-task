package com.vivaahaverse.vivaahaverse.controller;

import com.vivaahaverse.vivaahaverse.model.Booking;
import com.vivaahaverse.vivaahaverse.repository.BookingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/bookings")
@CrossOrigin(origins = "*")
public class BookingController {

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private MongoTemplate mongoTemplate;

    // 1. Create Booking (With Conflict Check)
    @PostMapping
    public Booking createBooking(@RequestBody Booking booking) {
        if (booking.getClientId().equals(booking.getVendorId())) {
            throw new RuntimeException("You cannot book your own service!");
        }

        // Check for overlapping dates for this service
        // Logic: (StartA <= EndB) and (EndA >= StartB)
        Query query = new Query();
        query.addCriteria(Criteria.where("serviceId").is(booking.getServiceId())
                .and("status").is("CONFIRMED")
                .andOperator(
                        Criteria.where("startDate").lte(booking.getEndDate()),
                        Criteria.where("endDate").gte(booking.getStartDate())
                ));

        if (mongoTemplate.exists(query, Booking.class)) {
            throw new RuntimeException("This service is already booked for these dates!");
        }

        booking.setStatus("CONFIRMED");
        booking.setBookedAt(new Date());
        Booking saved = bookingRepository.save(booking);

        // Notify Vendor

        return saved;
    }

    // 2. Cancel Booking
    @PostMapping("/cancel/{id}")
    public Booking cancelBooking(@PathVariable String id, @RequestBody Booking cancelData) {
        Booking booking = bookingRepository.findById(id).orElseThrow();

        booking.setStatus("CANCELLED");
        booking.setCancelledBy(cancelData.getCancelledBy());
        booking.setCancellationReason(cancelData.getCancellationReason());

        // Notify the OTHER party
        String targetUser = cancelData.getCancelledBy().equals("CLIENT") ? booking.getVendorId() : booking.getClientId();

        return bookingRepository.save(booking);
    }

    // 3. Get Bookings for a specific Service (To show Red dates on Calendar)
    @GetMapping("/service/{serviceId}")
    public List<Booking> getServiceBookings(@PathVariable String serviceId) {
        Query query = new Query();
        query.addCriteria(Criteria.where("serviceId").is(serviceId).and("status").is("CONFIRMED"));
        return mongoTemplate.find(query, Booking.class);
    }

    // Standard Getters
    @GetMapping("/client/{clientId}")
    public List<Booking> getClientBookings(@PathVariable String clientId) { return bookingRepository.findByClientId(clientId); }

    @GetMapping("/vendor/{vendorId}")
    public List<Booking> getVendorOrders(@PathVariable String vendorId) { return bookingRepository.findByVendorId(vendorId); }


}