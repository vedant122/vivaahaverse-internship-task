import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService api = ApiService();

  List<dynamic> myBookings = [];
  List<dynamic> myOrders = [];
  List<dynamic> myListings = [];

  bool isLoading = true;
  String? currentUserId;
  String? currentUserName;

  // Data for Dropdowns
  final List<String> categories = ["Food", "Decor", "Hall", "Photography", "Music"];
  final List<String> priceTypes = ["PER_DAY", "PER_EVENT"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId');
    currentUserName = prefs.getString('userName');

    if (currentUserId != null) {
      try {
        var bookings = await api.getMyBookings(currentUserId!);
        var orders = await api.getMyOrders(currentUserId!);
        var listings = await api.getMyListings(currentUserId!);

        if (mounted) {
          setState(() {
            myBookings = bookings;
            myOrders = orders;
            myListings = listings;
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  // --- CANCEL BOOKING LOGIC ---
  void _cancelBooking(String id, bool isBooking) {
    TextEditingController reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text("Cancel Booking", style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: reasonCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
            hintText: "Reason for cancellation...",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD946EF)))
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Back", style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            await api.cancelBooking(id, isBooking ? "CLIENT" : "VENDOR", reasonCtrl.text);
            Navigator.pop(ctx);
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.redAccent, content: Text("Booking Cancelled")));
          },
          child: const Text("Confirm Cancel", style: TextStyle(color: Colors.white)),
        )
      ],
    ));
  }

  // --- DELETE LISTING LOGIC ---
  void _deleteListing(String id) async {
    await api.deleteService(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service Deleted")));
  }

  // --- UPDATED: FULL EDIT DIALOG ---
  void _showEditDialog(Map<String, dynamic> service) {
    final nameCtrl = TextEditingController(text: service['serviceName']);
    final priceCtrl = TextEditingController(text: service['price'].toString());
    final descCtrl = TextEditingController(text: service['description']);

    // Initialize Dropdown Values
    String selectedCategory = service['category'] ?? "Food";
    String selectedPriceType = service['priceType'] ?? "PER_DAY";

    // Ensure values exist in list, fallback if necessary
    if (!categories.contains(selectedCategory)) selectedCategory = categories[0];
    if (!priceTypes.contains(selectedPriceType)) selectedPriceType = priceTypes[0];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text("Edit Service", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameCtrl, "Service Name"),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(priceCtrl, "Price", isNumber: true)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPriceType,
                          dropdownColor: const Color(0xFF1E293B),
                          decoration: const InputDecoration(labelText: "Type", labelStyle: TextStyle(color: Colors.white54)),
                          items: priceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll("_", " "), style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
                          onChanged: (v) => setState(() => selectedPriceType = v!),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 10.h),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(labelText: "Category", labelStyle: TextStyle(color: Colors.white54)),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  SizedBox(height: 10.h),
                  _buildTextField(descCtrl, "Description", maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD946EF)),
                  onPressed: () async {
                    await api.updateService(service['id'], {
                      "serviceName": nameCtrl.text,
                      "price": double.parse(priceCtrl.text),
                      "description": descCtrl.text,
                      "category": selectedCategory,
                      "priceType": selectedPriceType
                    });
                    if(context.mounted) Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text("Update", style: TextStyle(color: Colors.white))
              )
            ],
          );
        }
    ));
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD946EF)))
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MY PROFILE", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            Text(currentUserName ?? "User", style: TextStyle(fontSize: 12.sp, color: Colors.white54)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _logout)
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD946EF),
          labelColor: const Color(0xFFD946EF),
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "BOOKINGS"),
            Tab(text: "ORDERS"),
            Tab(text: "MY LISTINGS"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD946EF)))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList(myBookings, true),
          _buildTransactionList(myOrders, false),
          _buildMyListings(),
        ],
      ),
    );
  }
  // ... [Keep _buildTransactionList and _buildMyListings same as before] ...
  Widget _buildTransactionList(List<dynamic> items, bool isBooking) {
    // (Copy existing _buildTransactionList code here - no changes needed there)
    if (items.isEmpty) return Center(child: Text("No Records", style: TextStyle(color: Colors.white38, fontSize: 14.sp)));
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
            border: Border(left: BorderSide(color: isCancelled ? Colors.grey : (isBooking ? Colors.blueAccent : Colors.greenAccent), width: 4.w)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item['serviceName'] ?? "Service", overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp))),
                Text("₹${item['amount']}", style: TextStyle(color: const Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isCancelled ? Icons.cancel : Icons.check_circle, size: 14.sp, color: isCancelled ? Colors.red : Colors.white54),
                      SizedBox(width: 6.w),
                      Text("${item['status']}", style: TextStyle(color: isCancelled ? Colors.red : Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (item['bookedAt'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text("Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(item['bookedAt']))}", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                    ),
                  if (isCancelled && item['cancellationReason'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text("Reason: ${item['cancellationReason']}", style: TextStyle(color: Colors.redAccent, fontSize: 11.sp, fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
            trailing: isCancelled
                ? null
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))
              ),
              onPressed: () => _cancelBooking(item['id'], isBooking),
              child: Text("Cancel", style: TextStyle(color: Colors.redAccent, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyListings() {
    if (myListings.isEmpty) return Center(child: Text("You haven't listed any services.", style: TextStyle(color: Colors.white38, fontSize: 14.sp)));
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: myListings.length,
      itemBuilder: (context, index) {
        final item = myListings[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8.r)),
              child: Icon(Icons.storefront, color: const Color(0xFFD946EF), size: 24.sp),
            ),
            title: Text(item['serviceName'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text("₹${item['price']} • ${item['category']}", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => _showEditDialog(item)
                ),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteListing(item['id'])
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}