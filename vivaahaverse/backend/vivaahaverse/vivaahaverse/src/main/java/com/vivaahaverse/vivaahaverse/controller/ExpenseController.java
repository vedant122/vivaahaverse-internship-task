package com.vivaahaverse.vivaahaverse.controller;

import com.vivaahaverse.vivaahaverse.model.Expense;
import com.vivaahaverse.vivaahaverse.repository.ExpenseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/expenses")
@CrossOrigin(origins = "*")
public class ExpenseController {

    @Autowired
    private ExpenseRepository expenseRepository;

    // 1. Add a new Manual Expense
    @PostMapping
    public Expense addExpense(@RequestBody Expense expense) {
        if (expense.getDate() == null) {
            expense.setDate(new Date()); // Default to today if empty
        }
        return expenseRepository.save(expense);
    }

    // 2. Get All Manual Expenses for a User
    @GetMapping("/user/{userId}")
    public List<Expense> getUserExpenses(@PathVariable String userId) {
        return expenseRepository.findByUserId(userId);
    }

    // 3. Delete an Expense
    @DeleteMapping("/{id}")
    public void deleteExpense(@PathVariable String id) {
        expenseRepository.deleteById(id);
    }

    // 4. Update an Expense
    @PutMapping("/{id}")
    public Expense updateExpense(@PathVariable String id, @RequestBody Expense updated) {
        return expenseRepository.findById(id).map(expense -> {
            expense.setTitle(updated.getTitle());
            expense.setAmount(updated.getAmount());
            expense.setCategory(updated.getCategory());
            expense.setDescription(updated.getDescription());
            expense.setDate(updated.getDate());
            return expenseRepository.save(expense);
        }).orElseThrow(() -> new RuntimeException("Expense not found"));
    }
}