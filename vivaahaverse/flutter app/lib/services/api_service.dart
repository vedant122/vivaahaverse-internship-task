import 'package:dio/dio.dart';

class ApiService {
  // REPLACE WITH YOUR IP ADDRESS
  static const String baseUrl = "http://192.168.1.5:8080";

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 40),
    receiveTimeout: const Duration(seconds: 40),
  ));

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {"email": email, "password": password});
      return response.data;
    } catch (e) {
      throw Exception("Login Failed.");
    }
  }

  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/signup', data: {
        "name": name, "email": email, "password": password, "phone": "0000000000"
      });
      return response.data;
    } catch (e) {
      throw Exception("Signup Failed.");
    }
  }

  Future<List<dynamic>> getServices(String? category) async {
    try {
      String path = '/services';
      if (category != null && category != "All") path += '?category=$category';
      final response = await _dio.get(path);
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<void> addService(Map<String, dynamic> serviceData) async {
    await _dio.post('/services', data: serviceData);
  }


  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    await _dio.post('/bookings', data: bookingData);
  }

  Future<void> cancelBooking(String bookingId, String who, String reason) async {
    await _dio.post('/bookings/cancel/$bookingId', data: {
      "cancelledBy": who,
      "cancellationReason": reason
    });
  }

  Future<List<dynamic>> getServiceBookings(String serviceId) async {
    try {
      final response = await _dio.get('/bookings/service/$serviceId');
      return response.data;
    } catch (e) {
      return [];
    }
  }


  Future<List<dynamic>> getMyBookings(String clientId) async {
    final response = await _dio.get('/bookings/client/$clientId');
    return response.data;
  }

  Future<List<dynamic>> getMyOrders(String vendorId) async {
    final response = await _dio.get('/bookings/vendor/$vendorId');
    return response.data;
  }

  Future<List<dynamic>> getMyListings(String vendorId) async {
    try {
      final response = await _dio.get('/services/my-listings/$vendorId');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteService(String serviceId) async {
    await _dio.delete('/services/$serviceId');
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    await _dio.put('/services/$serviceId', data: data);
  }

  // --- NEW: EXPENSE & BUDGET METHODS ---

  // 1. Get User Details (to fetch budget limit)
  Future<Map<String, dynamic>> getUser(String userId) async {
    final response = await _dio.get('/users/$userId');
    return response.data;
  }

  // 2. Update Budget Limit
  Future<void> updateBudget(String userId, double newLimit) async {
    // FIX: Wrap the double in a Map so Dio knows it's JSON
    await _dio.put('/users/$userId/budget', data: {
      "limit": newLimit
    });
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    await _dio.put('/expenses/$id', data: data);
  }

  // 3. Get Manual Expenses
  Future<List<dynamic>> getExpenses(String userId) async {
    final response = await _dio.get('/expenses/user/$userId');
    return response.data;
  }

  // 4. Add Manual Expense
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    await _dio.post('/expenses', data: expenseData);
  }

  // 5. Delete Manual Expense
  Future<void> deleteExpense(String expenseId) async {
    await _dio.delete('/expenses/$expenseId');
  }
}