package com.vivaahaverse.vivaahaverse.repository;

import com.vivaahaverse.vivaahaverse.model.VendorService;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface VendorServiceRepository extends MongoRepository<VendorService, String> {
    // Find by Category (e.g., Show me all "Food" options)
    List<VendorService> findByCategory(String category);

    // Find by Vendor (e.g., Show me all services I listed)
    List<VendorService> findByVendorId(String vendorId);
}