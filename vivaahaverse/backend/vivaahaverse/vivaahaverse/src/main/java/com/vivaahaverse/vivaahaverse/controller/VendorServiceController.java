package com.vivaahaverse.vivaahaverse.controller;

import com.vivaahaverse.vivaahaverse.model.VendorService;
import com.vivaahaverse.vivaahaverse.repository.VendorServiceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/services")
@CrossOrigin(origins = "*")
public class VendorServiceController {

    @Autowired
    private VendorServiceRepository serviceRepository;

    // 1. Add a new Service (Food, Decor, etc.)
    @PostMapping
    public VendorService addService(@RequestBody VendorService service) {
        return serviceRepository.save(service);
    }

    // 2. Get All Services (Optional Filter by Category)
    // Example: GET /services?category=Food
    @GetMapping
    public List<VendorService> getServices(@RequestParam(required = false) String category) {
        if (category != null) {
            return serviceRepository.findByCategory(category);
        }
        return serviceRepository.findAll();
    }

    // 3. Get Services by Specific Vendor (My Listings)
    @GetMapping("/my-listings/{vendorId}")
    public List<VendorService> getMyListings(@PathVariable String vendorId) {
        return serviceRepository.findByVendorId(vendorId);
    }

    // 4. Delete a Service
    @DeleteMapping("/{id}")
    public void deleteService(@PathVariable String id) {
        serviceRepository.deleteById(id);
    }

    // 5. Update a Service
    @PutMapping("/{id}")
    public VendorService updateService(@PathVariable String id, @RequestBody VendorService updatedService) {
        return serviceRepository.findById(id).map(service -> {
            service.setServiceName(updatedService.getServiceName());
            service.setPrice(updatedService.getPrice());
            service.setDescription(updatedService.getDescription());
            service.setCategory(updatedService.getCategory());
            return serviceRepository.save(service);
        }).orElseThrow(() -> new RuntimeException("Service not found"));
    }
}