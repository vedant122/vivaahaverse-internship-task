import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService api = ApiService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  List<DateTime> bookedDates = [];
  bool isLoading = true;
  double totalBill = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchBookedDates();
  }

  void _fetchBookedDates() async {
    var bookings = await api.getServiceBookings(widget.service['id']);
    List<DateTime> temp = [];
    for (var b in bookings) {
      DateTime start = DateTime.parse(b['startDate']);
      DateTime end = DateTime.parse(b['endDate']);
      for (int i = 0; i <= end.difference(start).inDays; i++) {
        temp.add(start.add(Duration(days: i)));
      }
    }
    setState(() {
      bookedDates = temp;
      isLoading = false;
    });
  }

  bool _isDayBooked(DateTime day) {
    for (var bookedDay in bookedDates) {
      if (isSameDay(day, bookedDay)) return true;
    }
    return false;
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
    });
    _calculateBill();
  }

  void _calculateBill() {
    if (_rangeStart == null) {
      totalBill = 0.0;
      setState(() {});
      return;
    }

    DateTime endDate = _rangeEnd ?? _rangeStart!;
    int days = endDate.difference(_rangeStart!).inDays + 1;

    for (int i = 0; i < days; i++) {
      if (_isDayBooked(_rangeStart!.add(Duration(days: i)))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Selected range includes booked dates!")));
        setState(() { _rangeStart = null; _rangeEnd = null; totalBill = 0; });
        return;
      }
    }

    double price = widget.service['price'];
    String type = widget.service['priceType'] ?? "PER_DAY";

    if (type == "PER_EVENT") {
      totalBill = price;
    } else {
      totalBill = price * days;
    }
    setState(() {});
  }

  void _confirmBooking() async {
    if (_rangeStart == null || totalBill == 0) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    DateTime finalEnd = _rangeEnd ?? _rangeStart!;

    try {
      await api.createBooking({
        "serviceId": widget.service['id'],
        "serviceName": widget.service['serviceName'],
        "category": widget.service['category'],
        "clientId": userId,
        "vendorId": widget.service['vendorId'],
        "amount": totalBill,
        "startDate": _rangeStart!.toIso8601String(),
        "endDate": finalEnd.toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Payment Successful! Booking Confirmed.")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(e.toString())));
    }
  }

  // Helper widget for consistent Red Booked Marker
  Widget _buildBookedMarker(DateTime day) {
    return Center(child: Container(
      width: 35.w, height: 35.w,
      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
      child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white))),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(title: const Text("Select Dates"), backgroundColor: Colors.transparent),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onRangeSelected: _onRangeSelected,
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white70),
                rangeStartDecoration: const BoxDecoration(color: Color(0xFFD946EF), shape: BoxShape.circle),
                rangeEndDecoration: const BoxDecoration(color: Color(0xFFD946EF), shape: BoxShape.circle),
                rangeHighlightColor: const Color(0xFFD946EF).withOpacity(0.2),
                todayDecoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle), // subtle today style
              ),
              // UPDATED CALENDAR BUILDERS
              calendarBuilders: CalendarBuilders(
                // 1. Handle Normal Days
                defaultBuilder: (context, day, focusedDay) {
                  if (_isDayBooked(day)) return _buildBookedMarker(day);
                  return null;
                },
                // 2. Handle TODAY specifically (This was missing)
                todayBuilder: (context, day, focusedDay) {
                  if (_isDayBooked(day)) return _buildBookedMarker(day);
                  return null; // Use default today style if not booked
                },
                // 3. Handle Selected Day specifically
                selectedBuilder: (context, day, focusedDay) {
                  if (_isDayBooked(day)) return _buildBookedMarker(day);
                  return null;
                },
                // 4. Handle Range Start/End specifically
                rangeStartBuilder: (context, day, focusedDay) {
                  if (_isDayBooked(day)) return _buildBookedMarker(day);
                  return null;
                },
                rangeEndBuilder: (context, day, focusedDay) {
                  if (_isDayBooked(day)) return _buildBookedMarker(day);
                  return null;
                },
              ),
            ),
            SizedBox(height: 20.h),

            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16.r)),
              child: Column(
                children: [
                  Text("Bill Summary", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10.h),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Rate Type:", style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
                    Text(widget.service['priceType']?.replaceAll("_", " ") ?? "PER DAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                  SizedBox(height: 10.h),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Total:", style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
                    Text("₹$totalBill", style: TextStyle(color: const Color(0xFF4ADE80), fontSize: 24.sp, fontWeight: FontWeight.w900)),
                  ]),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: totalBill > 0 ? _confirmBooking : null,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD946EF), padding: EdgeInsets.symmetric(vertical: 16.h)),
                      child: const Text("PAY & BOOK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}