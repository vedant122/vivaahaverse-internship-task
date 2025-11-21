package com.vivaahaverse.vivaahaverse.repository;

import com.vivaahaverse.vivaahaverse.model.Expense;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface ExpenseRepository extends MongoRepository<Expense, String> {
    // Fetch all manual expenses for a specific user
    List<Expense> findByUserId(String userId);
}