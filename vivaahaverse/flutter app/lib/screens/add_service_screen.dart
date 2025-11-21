import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});
  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String selectedCategory = "Food";
  String selectedPriceType = "PER_DAY"; // Default

  final List<String> categories = ["Food", "Decor", "Hall", "Photography", "Music"];
  final List<String> priceTypes = ["PER_DAY", "PER_EVENT"];

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? userName = prefs.getString('userName');

    if (userId == null) return;

    try {
      await api.addService({
        "vendorId": userId,
        "vendorName": userName,
        "serviceName": nameCtrl.text,
        "category": selectedCategory,
        "price": double.parse(priceCtrl.text),
        "priceType": selectedPriceType, // Sending new field
        "description": descCtrl.text,
        "location": "Unknown"
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        title: Text("NEW LISTING", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label("Service Details"),
              SizedBox(height: 16.h),
              _field(nameCtrl, "Service Title", TextInputType.text),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(child: _field(priceCtrl, "Price (₹)", TextInputType.number)),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPriceType,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          items: priceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll("_", " "), style: TextStyle(color: Colors.white, fontSize: 12.sp)))).toList(),
                          onChanged: (v) => setState(() => selectedPriceType = v!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: Colors.white, fontSize: 14.sp)))).toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _field(descCtrl, "Description", TextInputType.multiline, lines: 3),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD946EF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
                  child: Text("PUBLISH", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(color: const Color(0xFFD946EF), fontSize: 14.sp, fontWeight: FontWeight.bold));
  Widget _field(TextEditingController ctrl, String hint, TextInputType type, {int lines = 1}) {
    return TextFormField(
      controller: ctrl, keyboardType: type, maxLines: lines, style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white30, fontSize: 14.sp), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none), contentPadding: EdgeInsets.all(20.w)),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}