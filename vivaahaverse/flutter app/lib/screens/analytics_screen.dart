import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<dynamic> allExpenses = [];
  List<dynamic> filteredExpenses = [];
  double totalSpent = 0.0;

  // FILTER STATE
  DateTime selectedDate = DateTime.now();
  String viewMode = "Monthly"; // Options: "Monthly", "Daily"

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId != null) {
      try {
        var bookings = await api.getMyBookings(userId);
        var manuals = await api.getExpenses(userId);

        List<dynamic> merged = [];

        for (var b in bookings) {
          if (b['status'] == 'CONFIRMED') {
            merged.add({
              "amount": b['amount'],
              "category": b['category'] ?? "Misc",
              "date": DateTime.parse(b['startDate'])
            });
          }
        }

        for (var m in manuals) {
          merged.add({
            "amount": m['amount'],
            "category": m['category'] ?? "Misc",
            "date": m['date'] != null ? DateTime.parse(m['date']) : DateTime.now()
          });
        }

        if(mounted) {
          setState(() {
            allExpenses = merged;
            _filterData();
            isLoading = false;
          });
        }
      } catch (e) {
        if(mounted) setState(() => isLoading = false);
      }
    }
  }

  // UPDATED: Handle both Monthly and Daily filtering
  void _filterData() {
    setState(() {
      filteredExpenses = allExpenses.where((e) {
        DateTime d = e['date'];
        if (viewMode == "Monthly") {
          return d.year == selectedDate.year && d.month == selectedDate.month;
        } else {
          // Daily
          return d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;
        }
      }).toList();

      totalSpent = filteredExpenses.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
    });
  }

  // UPDATED: Shift date based on current mode
  void _changeDate(int offset) {
    setState(() {
      if (viewMode == "Monthly") {
        selectedDate = DateTime(selectedDate.year, selectedDate.month + offset);
      } else {
        selectedDate = selectedDate.add(Duration(days: offset));
      }
      _filterData();
    });
  }

  // NEW: Date Picker for quick jumping
  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD946EF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E293B),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _filterData();
      });
    }
  }

  Map<String, double> _getCategoryData() {
    Map<String, double> data = {};
    for (var item in filteredExpenses) {
      String cat = item['category'];
      data[cat] = (data[cat] ?? 0) + (item['amount'] as num).toDouble();
    }
    var sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> categoryData = _getCategoryData();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        title: const Text("SPENDING ANALYTICS"),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD946EF)))
          : SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // 1. VIEW MODE TOGGLE
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white10)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleBtn("Monthly"),
                  _buildToggleBtn("Daily"),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 2. DATE NAVIGATOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left, color: Colors.white)
                ),
                GestureDetector(
                  onTap: _pickDate, // Click text to open Calendar
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(8.r)
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFFD946EF)),
                        SizedBox(width: 8.w),
                        Text(
                            viewMode == "Monthly"
                                ? DateFormat('MMMM yyyy').format(selectedDate)
                                : DateFormat('EEE, MMM dd, yyyy').format(selectedDate),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () => _changeDate(1),
                    icon: const Icon(Icons.chevron_right, color: Colors.white)
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 3. CHART CARD
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                children: [
                  Text("$viewMode Breakdown", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 30.h),
                  SizedBox(
                    height: 220.h,
                    child: totalSpent == 0
                        ? Center(child: Text("No Expenses", style: TextStyle(color: Colors.white54, fontSize: 14.sp)))
                        : PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 50,
                        sections: categoryData.entries.map((e) {
                          return PieChartSectionData(
                            color: _getColorForCategory(e.key),
                            value: e.value,
                            title: "${((e.value / totalSpent) * 100).toStringAsFixed(0)}%",
                            titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                            radius: 60,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if(totalSpent > 0) ...[
                    SizedBox(height: 20.h),
                    Text("Total: ₹${totalSpent.toStringAsFixed(0)}", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 4. CATEGORY LIST
            Align(alignment: Alignment.centerLeft, child: Text("Top Categories", style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.bold))),
            SizedBox(height: 10.h),

            categoryData.isEmpty
                ? Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Text("No data for this selection", style: TextStyle(color: Colors.white38)),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryData.length,
              itemBuilder: (ctx, i) {
                String key = categoryData.keys.elementAt(i);
                double value = categoryData.values.elementAt(i);
                double pct = totalSpent == 0 ? 0 : (value / totalSpent);

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border(left: BorderSide(color: _getColorForCategory(key), width: 4.w))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(key, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                          SizedBox(height: 4.h),
                          SizedBox(
                            width: 100.w,
                            child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white10, color: _getColorForCategory(key), minHeight: 4.h),
                          )
                        ],
                      ),
                      Text("₹${value.toStringAsFixed(0)}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  // Helper Widget for the Toggle
  Widget _buildToggleBtn(String title) {
    bool isSelected = viewMode == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          viewMode = title;
          _filterData();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD946EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
            title,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp
            )
        ),
      ),
    );
  }

  Color _getColorForCategory(String cat) {
    switch (cat) {
      case "Food": return Colors.orange;
      case "Hall": return Colors.blue;
      case "Decor": return Colors.pink;
      case "Shopping": return Colors.green;
      case "Travel": return Colors.purple;
      case "Photography": return Colors.teal;
      case "Music": return Colors.redAccent;
      default: return Colors.grey;
    }
  }
}