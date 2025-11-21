import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for formatting
import '../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? expenseToEdit;
  const AddExpenseScreen({super.key,this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  late TextEditingController titleCtrl;
  late TextEditingController amountCtrl;
  late TextEditingController descCtrl;

  String selectedCategory = "Shopping";
  DateTime _selectedDate = DateTime.now();
  bool isLoading = false;
  final List<String> categories = [
    "Shopping",
    "Travel",
    "Food",
    "Misc",
    "Gifts",
    "Venue"
  ];

  @override
  void initState() {
    super.initState();
    // NEW: Pre-fill data if editing
    final e = widget.expenseToEdit;
    titleCtrl = TextEditingController(text: e != null ? e['title'] : '');
    amountCtrl =
        TextEditingController(text: e != null ? e['amount'].toString() : '');
    descCtrl =
        TextEditingController(text: e != null ? e['description'] ?? '' : '');

    if (e != null) {
      selectedCategory = e['category'];
      _selectedDate =
      e['date'] is DateTime ? e['date'] : DateTime.parse(e['date']);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId != null) {
      try {
        Map<String, dynamic> data = {
          "userId": userId,
          "title": titleCtrl.text,
          "amount": double.parse(amountCtrl.text),
          "category": selectedCategory,
          "description": descCtrl.text,
          "date": _selectedDate.toIso8601String(),
        };

        if (widget.expenseToEdit != null) {
          // EDIT MODE: Call Update
          await api.updateExpense(widget.expenseToEdit!['id'], data);
        } else {
          // ADD MODE: Call Create
          await api.addExpense(data);
        }

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")));
      }
    }
    if (mounted) setState(() => isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
          title: Text(widget.expenseToEdit != null ? "Edit Expense" : "Add New Expense"),
          backgroundColor: Colors.transparent
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDecor("Title"), validator: (v) => v!.isEmpty ? "Required" : null),
              SizedBox(height: 16.h),
              TextFormField(controller: amountCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecor("Amount"), validator: (v) => v!.isEmpty ? "Required" : null),
              SizedBox(height: 16.h),
              // Category Dropdown (Keep your existing code)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12.r)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Date Picker (Keep your existing code)
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white10)),
                  child: Row(children: [Icon(Icons.calendar_today, color: const Color(0xFFD946EF), size: 20.sp), SizedBox(width: 12.w), Text("Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}", style: TextStyle(color: Colors.white, fontSize: 16.sp)), const Spacer(), const Icon(Icons.arrow_drop_down, color: Colors.white54)]),
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDecor("Notes"), maxLines: 3),
              SizedBox(height: 30.h),
              SizedBox(width: double.infinity, height: 50.h, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD946EF)), onPressed: isLoading ? null : _submit, child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.expenseToEdit != null ? "UPDATE" : "ADD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }
  InputDecoration _inputDecor(String label) {
    return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h)
    );
  }
  void _pickDate() async {
    // ... (Keep your existing _pickDate code) ...
    DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030), builder: (context, child) { return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFD946EF), onPrimary: Colors.white, surface: Color(0xFF1E293B), onSurface: Colors.white), dialogBackgroundColor: const Color(0xFF1E293B)), child: child!); });
    if (picked != null) setState(() => _selectedDate = picked);
  }
}
