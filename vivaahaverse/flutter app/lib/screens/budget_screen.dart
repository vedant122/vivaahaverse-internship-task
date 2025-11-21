import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final ApiService api = ApiService();

  double totalBudget = 0.0;
  List<dynamic> allExpenses = [];
  List<dynamic> filteredExpenses = [];
  bool isLoading = true;

  // Filters
  String selectedCategory = "All";
  DateTime selectedMonth = DateTime.now();

  final List<String> categories = ["All", "Food", "Hall", "Decor", "Shopping", "Travel", "Misc"];
  final List<String> expenseCategories = ["Food", "Hall", "Decor", "Shopping", "Travel", "Misc", "Gifts", "Venue"]; // For Edit Dropdown

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
        var user = await api.getUser(userId);
        var bookings = await api.getMyBookings(userId);
        var manuals = await api.getExpenses(userId);

        List<dynamic> merged = [];

        // Merge Bookings
        for (var b in bookings) {
          if (b['status'] == 'CONFIRMED') {
            merged.add({
              "title": b['serviceName'],
              "amount": b['amount'],
              "date": DateTime.parse(b['startDate']),
              "category": b['category'] ?? "Misc",
              "isBooking": true,
              "id": b['id']
            });
          }
        }

        // Merge Expenses
        for (var m in manuals) {
          merged.add({
            "title": m['title'],
            "amount": m['amount'],
            "date": m['date'] != null ? DateTime.parse(m['date']) : DateTime.now(),
            "category": m['category'] ?? "Misc",
            "description": m['description'],
            "isBooking": false,
            "id": m['id']
          });
        }

        // Sort
        merged.sort((a, b) => b['date'].compareTo(a['date']));

        if (mounted) {
          setState(() {
            totalBudget = (user['budgetLimit'] ?? 500000.0).toDouble();
            allExpenses = merged;
            _filterData();
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _filterData() {
    setState(() {
      filteredExpenses = allExpenses.where((e) {
        DateTime date = e['date'];
        bool matchMonth = date.year == selectedMonth.year && date.month == selectedMonth.month;
        bool matchCategory = selectedCategory == "All" || e['category'] == selectedCategory;
        return matchMonth && matchCategory;
      }).toList();
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + offset);
      _filterData();
    });
  }

  void _updateBudgetDialog() {
    TextEditingController ctrl = TextEditingController(text: totalBudget.toStringAsFixed(0));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text("Set Budget Limit", style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: ctrl, keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: "Limit (₹)", labelStyle: TextStyle(color: Colors.white54)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD946EF)),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? userId = prefs.getString('userId');
            if (userId != null) {
              await api.updateBudget(userId, double.parse(ctrl.text));
              _loadData();
              Navigator.pop(ctx);
            }
          },
          child: const Text("Save", style: TextStyle(color: Colors.white)),
        )
      ],
    ));
  }

  void _deleteExpense(String id) async {
    await api.deleteExpense(id);
    _loadData();
  }

  void _cancelBooking(String id) {
    TextEditingController reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text("Cancel Booking?", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("This will remove the cost from your budget and notify the vendor.", style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 10.h),
          TextField(
            controller: reasonCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "Reason (e.g. Change of plans)", hintStyle: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Back")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            await api.cancelBooking(id, "CLIENT", reasonCtrl.text);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Booking Cancelled")));
            _loadData();
          },
          child: const Text("Confirm Cancel", style: TextStyle(color: Colors.white)),
        )
      ],
    ));
  }

  // --- NEW: EDIT DIALOG (Replaces Full Screen Navigation) ---
  void _showEditExpenseDialog(Map<String, dynamic> item) {
    if (item['isBooking']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booked services cannot be edited.")));
      return;
    }

    final titleCtrl = TextEditingController(text: item['title']);
    final amountCtrl = TextEditingController(text: item['amount'].toString());
    final descCtrl = TextEditingController(text: item['description'] ?? '');

    String currentCat = item['category'];
    if (!expenseCategories.contains(currentCat)) currentCat = expenseCategories[0];

    DateTime currentDate = item['date'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text("Edit Expense", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(titleCtrl, "Title"),
                  SizedBox(height: 10.h),
                  _buildTextField(amountCtrl, "Amount", isNumber: true),
                  SizedBox(height: 10.h),
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: currentCat,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(labelText: "Category", labelStyle: TextStyle(color: Colors.white54)),
                    items: expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setDialogState(() => currentCat = v!),
                  ),
                  SizedBox(height: 10.h),
                  // Date Picker Row
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: currentDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFD946EF), onPrimary: Colors.white, surface: Color(0xFF1E293B), onSurface: Colors.white), dialogBackgroundColor: const Color(0xFF1E293B)), child: child!);
                          }
                      );
                      if (picked != null) setDialogState(() => currentDate = picked);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Date: ${DateFormat('MMM dd, yyyy').format(currentDate)}", style: const TextStyle(color: Colors.white)),
                          const Icon(Icons.calendar_today, color: Color(0xFFD946EF), size: 16),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildTextField(descCtrl, "Description", maxLines: 2),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD946EF)),
                  onPressed: () async {
                    await api.updateExpense(item['id'], {
                      "title": titleCtrl.text,
                      "amount": double.parse(amountCtrl.text),
                      "category": currentCat,
                      "description": descCtrl.text,
                      "date": currentDate.toIso8601String()
                    });
                    if (context.mounted) Navigator.pop(ctx);
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

  double get totalSpent => filteredExpenses.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

  @override
  Widget build(BuildContext context) {
    double progress = totalBudget == 0 ? 0 : (totalSpent / totalBudget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        title: const Text("BUDGET MANAGER"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_outline, color: Color(0xFFD946EF)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD946EF)))
          : Column(
        children: [
          // 1. SUMMARY CARD
          Container(
            margin: EdgeInsets.all(20.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Text("Total Spent (${DateFormat('MMM yyyy').format(selectedMonth)})", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                Text("₹${totalSpent.toStringAsFixed(0)}", style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 10.h),
                ClipRRect(borderRadius: BorderRadius.circular(10.r), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black26, color: Colors.white, minHeight: 8.h)),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _updateBudgetDialog,
                      child: Row(children: [
                        Text("Limit: ₹${totalBudget.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 5.w),
                        const Icon(Icons.edit, color: Colors.white70, size: 14)
                      ]),
                    ),
                    Text("${(progress * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white)),
                  ],
                )
              ],
            ),
          ),

          // 2. MONTH SELECTOR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left, color: Colors.white)),
                Text(DateFormat('MMMM yyyy').format(selectedMonth), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right, color: Colors.white)),
              ],
            ),
          ),

          SizedBox(
            height: 40.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () { setState(() { selectedCategory = cat; _filterData(); }); },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD946EF) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: isSelected ? const Color(0xFFD946EF) : Colors.white24),
                    ),
                    child: Center(child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.sp))),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 10.h),

          // 3. TRANSACTIONS LIST
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(child: Text("No Transactions for this month", style: TextStyle(color: Colors.white38, fontSize: 14.sp)))
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: filteredExpenses.length,
              itemBuilder: (ctx, i) {
                final item = filteredExpenses[i];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12.r)),
                  child: ListTile(
                    onTap: () => _showEditExpenseDialog(item), // NOW OPENS DIALOG
                    leading: CircleAvatar(
                      backgroundColor: item['isBooking'] ? Colors.blueAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                      child: Icon(item['isBooking'] ? Icons.storefront : Icons.receipt, color: item['isBooking'] ? Colors.blueAccent : Colors.orangeAccent, size: 20.sp),
                    ),
                    title: Text(item['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("${DateFormat('MMM dd').format(item['date'])} • ${item['category']}", style: const TextStyle(color: Colors.white54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("- ₹${item['amount']}", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(width: 5.w),
                        if (item['isBooking'])
                          IconButton(icon: const Icon(Icons.cancel_presentation, color: Colors.redAccent, size: 20), onPressed: () => _cancelBooking(item['id']))
                        else
                          IconButton(icon: const Icon(Icons.delete, color: Colors.white30, size: 20), onPressed: () => _deleteExpense(item['id']))
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
          _loadData();
        },
        backgroundColor: const Color(0xFFD946EF),
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
    );
  }
}