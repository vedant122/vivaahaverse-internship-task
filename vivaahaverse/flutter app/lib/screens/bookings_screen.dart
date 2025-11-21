import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService api = ApiService();
  List<dynamic> myBookings = [];
  List<dynamic> myOrders = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId');
    if (currentUserId != null) {
      var bookings = await api.getMyBookings(currentUserId!);
      var orders = await api.getMyOrders(currentUserId!);
      if (mounted) {
        setState(() { myBookings = bookings; myOrders = orders; isLoading = false; });
      }
    }
  }

  void _cancelBooking(String id, String type) {
    TextEditingController reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text("Cancel Booking", style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: reasonCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: "Reason for cancellation...", hintStyle: TextStyle(color: Colors.white38)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Back")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await api.cancelBooking(id, type == "BOOKING" ? "CLIENT" : "VENDOR", reasonCtrl.text);
            Navigator.pop(ctx);
            _loadData();
          },
          child: const Text("Confirm Cancel", style: TextStyle(color: Colors.white)),
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        title: Text("TRANSACTIONS", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD946EF),
          labelColor: const Color(0xFFD946EF),
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: "MY BOOKINGS"), Tab(text: "CLIENT ORDERS")],
        ),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFD946EF))) : TabBarView(
        controller: _tabController,
        children: [ _buildList(myBookings, "BOOKING"), _buildList(myOrders, "ORDER") ],
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String type) {
    if (items.isEmpty) return Center(child: Text("No Records Found", style: TextStyle(color: Colors.white38, fontSize: 14.sp)));

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isCancelled = item['status'] == 'CANCELLED';

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12.r),
            border: Border(left: BorderSide(color: isCancelled ? Colors.grey : (type == "BOOKING" ? Colors.blueAccent : Colors.greenAccent), width: 4.w)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            title: Text(item['serviceName'] ?? "Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Status: ${item['status']}", style: TextStyle(color: isCancelled ? Colors.red : Colors.white54, fontSize: 12.sp)),
                if (isCancelled) Text("Reason: ${item['cancellationReason']}", style: TextStyle(color: Colors.redAccent, fontSize: 11.sp)),
              ],
            ),
            trailing: isCancelled
                ? const Icon(Icons.cancel, color: Colors.red)
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), elevation: 0),
              onPressed: () => _cancelBooking(item['id'], type),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
          ),
        );
      },
    );
  }
}