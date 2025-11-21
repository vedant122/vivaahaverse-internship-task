package com.vivaahaverse.vivaahaverse.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document(collection = "vendor_services")
public class VendorService {
    @Id
    private String id;
    private String vendorId;
    private String vendorName;
    private String serviceName;
    private String category;
    private Double price;
    private String priceType;

    private String description;
    private String location;
}