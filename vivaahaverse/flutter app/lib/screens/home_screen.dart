import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'add_service_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';
import 'booking_screen.dart'; // IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // UPDATED PAGES LIST
  final List<Widget> _pages = [
    const HomeFeed(),
    const BudgetScreen(), // ADDED HERE
    const ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFFD946EF),
        unselectedItemColor: Colors.white38,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Budget"), // ADDED TAB
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      // Only show "+" FAB on Home Screen, not Budget or Profile
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddServiceScreen())),
        backgroundColor: const Color(0xFFD946EF),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  final ApiService api = ApiService();
  String selectedCategory = "All";
  List<dynamic> services = [];
  bool isLoading = true;
  String? currentUserId;
  String? currentUserName;

  final List<String> categories = ["All", "Food", "Decor", "Hall", "Photography", "Music"];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchServices();
  }

  void _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(mounted) {
      setState(() {
        currentUserId = prefs.getString('userId');
        currentUserName = prefs.getString('userName');
      });
    }
  }

  void _fetchServices() async {
    setState(() => isLoading = true);
    var data = await api.getServices(selectedCategory);
    if(mounted) {
      setState(() { services = data; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("VIVAAHA VERSE", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                // NOTIFICATION ICON
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () => (){},
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text("Welcome, ${currentUserName ?? 'User'}", style: TextStyle(color: Colors.white54, fontSize: 16.sp)),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 50.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () { setState(() => selectedCategory = cat); _fetchServices(); },
                  child: AnimatedContainer(
                    duration: 300.ms,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(25.r),
                      border: isSelected ? Border.all(color: const Color(0xFFD946EF)) : null,
                    ),
                    child: Center(child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12.sp))),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFD946EF))) : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final s = services[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Colors.white10)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.w),
                    leading: Icon(Icons.storefront, color: const Color(0xFFD946EF), size: 30.sp),
                    title: Text(s['serviceName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.white)),
                    subtitle: Text("₹${s['price']} / ${s['priceType'] == 'PER_EVENT' ? 'Event' : 'Day'}", style: TextStyle(color: const Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        if (s['vendorId'] == currentUserId) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot book own service")));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(service: s)));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                      child: const Text("BOOK", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}