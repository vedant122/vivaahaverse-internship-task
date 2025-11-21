package com.vivaahaverse.vivaahaverse.controller;

import com.vivaahaverse.vivaahaverse.model.User;
import com.vivaahaverse.vivaahaverse.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/signup")
    public User signup(@RequestBody User user) {
        // Check if email already exists
        System.out.println("Got here");
        if (userRepository.findByEmail(user.getEmail()) != null) {
            throw new RuntimeException("Email already registered");
        }
        return userRepository.save(user);
    }

    @PostMapping("/login")
    public User login(@RequestBody User loginDetails) {
        // 1. Sanitize Input (Trim spaces)
        String cleanEmail = loginDetails.getEmail().trim();
        String cleanPassword = loginDetails.getPassword().trim();

        System.out.println("Login Attempt -> Email: '" + cleanEmail + "' Password: '" + cleanPassword + "'");

        // 2. Fetch User (Ensure database email is lowercase or handle exact match)
        // Note: If your DB has "Vedant@gmail.com" and you send "vedant...", this still fails.
        // Ideally, store all emails in lowercase during signup.
        User user = userRepository.findByEmail(cleanEmail);

        if (user == null) {
            System.out.println("Error: User not found in database for email: " + cleanEmail);
            throw new RuntimeException("Invalid Credentials (User not found)");
        }

        System.out.println("DB User Found -> Stored Password: '" + user.getPassword() + "'");

        // 3. Check Password
        if (!user.getPassword().equals(cleanPassword)) {
            System.out.println("Error: Password mismatch.");
            throw new RuntimeException("Invalid Credentials (Password incorrect)");
        }

        return user;
    }
}