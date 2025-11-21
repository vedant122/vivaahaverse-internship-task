# **VivaahaVerse: Full-Stack Wedding Event & Expense Tracker**

## **🌟 Project Overview**

**VivaahaVerse** is a full-stack mobile application designed to help users manage the logistics and finances of a major event, specifically focusing on wedding planning.

The application serves two primary user roles:

1. **Client/Planner:** Users can browse and book vendor services (like food, decor, photography) and track all their expenses against a set budget to ensure they stay within their financial limits.  
2. **Vendor:** Users can list and manage their own services (e.g., a photographer listing their services) and view incoming booking orders.

This project was built to meet the requirements of the technical assessment, demonstrating competence across mobile frontend development, RESTful API design, and database interaction.

## **💻 Tech Stack**

| Component | Technology | Framework/Library |
| :---- | :---- | :---- |
| **Frontend (Mobile App)** | **Flutter** | Dart, flutter\_screenutil (for responsiveness), fl\_chart |
| **Backend (REST API)** | **Java** | Spring Boot |
| **Database (NoSQL)** | **MongoDB** | Spring Data MongoDB |

## **🛠️ Setup and Installation Guide**

To run this application locally, you must set up both the backend server (Spring Boot) and the mobile frontend (Flutter).

### **A. Backend Setup (Java/Spring Boot)**

1. **Prerequisites:** Java 17+ and a running instance of MongoDB.  
2. **Database Configuration:**  
   * Navigate to the SpringBoot\_Backend/src/main/resources/application.properties file.  
   * Update the MongoDB connection string to match your local setup:  
     spring.data.mongodb.uri=mongodb://localhost:27017/vivaahaverse

3. **Run the Server:**  
   * Open your IDE (e.g., IntelliJ, VS Code).  
   * Navigate to the main application file: SpringBoot\_Backend/vivaahaverse/VivaahaverseApplication.java.  
   * Run the application. The API server will start on port 8080\.

### **B. Frontend Setup (Flutter)**

1. **Prerequisites:** Flutter SDK installed and configured.  
2. **Crucial API Fix (Network Configuration):**  
   * The API service is currently hardcoded with a local network IP address for mobile testing.  
   * **You MUST update the baseUrl** in the file Flutter\_Frontend/lib/services/api\_service.dart to match the address where your Spring Boot server is running (e.g., http://localhost:8080 if running on the same machine, or your local IP if testing on a physical device).

// File: lib/services/api\_service.dart  
static const String baseUrl \= "http://YOUR\_LOCAL\_IP\_OR\_LOCALHOST:8080";

3. **Run Dependencies:**  
   flutter pub get

4. **Run the App:**  
   flutter run

## **✅ Assessment Requirement Fulfillment**

This solution is designed to fully satisfy every requirement of the technical assessment:

### **1\. Expense Tracking & Budget Management**

| Requirement | Implementation Detail |
| :---- | :---- |
| **Add a new expense** | Implemented via the Floating Action Button on the **Budget** screen (AddExpenseScreen.dart) with fields for amount, description, date, and category. |
| **Edit/Delete existing expenses** | Users can tap on an item in the Budget list to open an **Edit Dialog** and update it, or use the delete icon to remove manual expenses/cancel bookings (BudgetScreen.dart). |
| **Display/Filter Expenses** | The **Budget** screen lists all expenses (including costs from confirmed bookings) and provides filtering by **Category** and **Month**. |
| **Dashboard/Summary** | The **Analytics** screen displays a budget progress bar and a detailed **Pie Chart** summarizing total spending segmented by category. |

### **2\. Backend API (RESTful Endpoints)**

| Endpoint | Controller/Model | Description |
| :---- | :---- | :---- |
| POST /expenses | ExpenseController.java | Adds a new expense document to MongoDB. |
| PUT /expenses/{id} | ExpenseController.java | Finds and updates an existing expense by ID. |
| DELETE /expenses/{id} | ExpenseController.java | Deletes the specified expense document. |
| GET /expenses/user/{userId} | ExpenseController.java | Retrieves the list of all manual expenses for the authenticated user. |

### **3\. Extra Points Implementation**

| Feature | Status | Detail |
| :---- | :---- | :---- |
| **Basic User Authentication** | ✅ Implemented | Full Signup/Login flow is handled by AuthController.java and AuthScreen.dart. |
| **Responsive UI** | ✅ Implemented | The Flutter frontend uses flutter\_screenutil extensively to ensure the UI scales correctly across all screen sizes. |
| **Graceful Error Handling** | ✅ Implemented | Network calls in ApiService.dart are wrapped in try-catch blocks, and user-facing error messages are shown via SnackBars on the UI (e.g., Login Failed, Network Error). |

