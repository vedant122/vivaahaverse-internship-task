import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      Map<String, dynamic> user;
      if (isLogin) {
        user = await api.login(emailCtrl.text, passCtrl.text);
      } else {
        user = await api.signup(nameCtrl.text, emailCtrl.text, passCtrl.text);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user['id']);
      await prefs.setString('userName', user['name']);

      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cyberpunk Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1120), Color(0xFF1E1B4B)],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond_outlined, size: 80.w, color: const Color(0xFFD946EF))
                      .animate().scale(duration: 600.ms, curve: Curves.elasticOut)
                      .then().shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5)),

                  SizedBox(height: 20.h),

                  Text(
                    "VIVAAHA VERSE",
                    style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white
                    ),
                  ).animate().fadeIn().slideY(begin: 0.5),

                  SizedBox(height: 50.h),

                  // Glassmorphism Form Container
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD946EF).withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ]
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            isLogin ? "ACCESS PORTAL" : "NEW IDENTITY",
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white70),
                          ),
                          SizedBox(height: 24.h),

                          if (!isLogin) ...[
                            _buildInput(nameCtrl, "Full Name", Icons.person_outline),
                            SizedBox(height: 16.h),
                          ],
                          _buildInput(
                              emailCtrl,
                              "Email Address",
                              Icons.alternate_email,
                              validator: (val) {
                                if (val == null || val.isEmpty) return "Email is required";

                                // This Regex checks for format: text@text.text
                                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                                if (!emailRegex.hasMatch(val)) {
                                  return "Enter a valid email (e.g., user@gmail.com)";
                                }
                                return null;
                              }
                          ),
                          SizedBox(height: 16.h),
                          _buildInput(passCtrl, "Password", Icons.lock_outline, isObscure: true),

                          SizedBox(height: 32.h),

                          // Neon Button
                          InkWell(
                            onTap: isLoading ? null : submit,
                            borderRadius: BorderRadius.circular(16.r),
                            child: Container(
                              width: double.infinity,
                              height: 56.h,
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)]),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFD946EF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))
                                  ]
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                isLogin ? "INITIALIZE" : "REGISTER",
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),

                  SizedBox(height: 24.h),

                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin ? "Create New Account" : "Already Registered? Login",
                      style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      TextEditingController ctrl,
      String hint,
      IconData icon,
      {bool isObscure = false, String? Function(String?)? validator}
      ) {
    return TextFormField(
      controller: ctrl,
      obscureText: isObscure,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white30, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: const Color(0xFFD946EF), size: 20.sp),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
      ),
      // Use the custom validator if provided, otherwise use the default "required" check
      validator: validator ?? (v) => v!.isEmpty ? "Field required" : null,
    );
  }
}