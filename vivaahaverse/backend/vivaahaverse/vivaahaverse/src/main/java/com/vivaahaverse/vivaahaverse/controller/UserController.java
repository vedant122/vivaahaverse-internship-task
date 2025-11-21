package com.vivaahaverse.vivaahaverse.controller;

import com.vivaahaverse.vivaahaverse.model.User;
import com.vivaahaverse.vivaahaverse.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Map; // Import Map

@RestController
@RequestMapping("/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/{id}")
    public User getUser(@PathVariable String id) {
        return userRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
    }

    // FIX: Change @RequestBody Double to @RequestBody Map<String, Double>
    @PutMapping("/{id}/budget")
    public User updateBudget(@PathVariable String id, @RequestBody Map<String, Double> payload) {
        Double newLimit = payload.get("limit"); // Extract the value

        return userRepository.findById(id).map(user -> {
            user.setBudgetLimit(newLimit);
            return userRepository.save(user);
        }).orElseThrow(() -> new RuntimeException("User not found"));
    }
}