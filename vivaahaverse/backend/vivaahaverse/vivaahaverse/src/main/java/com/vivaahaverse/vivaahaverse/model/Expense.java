package com.vivaahaverse.vivaahaverse.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.util.Date;

@Data
@Document(collection = "expenses")
public class Expense {
    @Id
    private String id;
    private String userId;      // Who spent the money
    private String title;       // e.g., "Wedding Rings"
    private String category;    // "Shopping", "Travel", "Misc"
    private Double amount;
    private String description;
    private Date date;          // When was it spent
}