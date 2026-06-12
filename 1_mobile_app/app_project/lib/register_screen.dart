import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> register() async {
    String user = userCtrl.text.trim();
    String pass = passCtrl.text.trim();
    String confirmPass = confirmPassCtrl.text.trim();

    // ตรวจสอบข้อมูลเบื้องต้น
    if (user.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
      return;
    }

    if (pass != confirmPass) {
      _showSnackBar("รหัสผ่านไม่ตรงกัน", Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        // ใช้ AppConfig เพื่อให้จัดการ IP ง่ายในจุดเดียว
        Uri.parse(AppConfig.apiUrl("register.php")),
        body: {
          "username": user,
          "password": pass,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == "success") {
          _showSnackBar("สมัครสมาชิกสำเร็จ!", Colors.green);
          // รอแป๊บหนึ่งแล้วกลับไปหน้า Login
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          _showSnackBar(data['message'] ?? "เกิดข้อผิดพลาด", Colors.redAccent);
        }
      } else {
        _showSnackBar("Server Error: ${response.statusCode}", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้", Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade800, Colors.green.shade400],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // Icon ส่วนหัว
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      size: 70, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text("REGISTER",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2)),
                const Text("สร้างบัญชีผู้ใช้ใหม่",
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 30),

                // Form สมัครสมาชิก
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                          controller: userCtrl,
                          label: "Username",
                          icon: Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildTextField(
                          controller: passCtrl,
                          label: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true),
                      const SizedBox(height: 20),
                      _buildTextField(
                          controller: confirmPassCtrl,
                          label: "Confirm Password",
                          icon: Icons.lock_reset_rounded,
                          isPassword: true),
                      const SizedBox(height: 30),
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.green)
                          : ElevatedButton(
                              onPressed: register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("ลงทะเบียน",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("มีบัญชีอยู่แล้ว? เข้าสู่ระบบ",
                            style: TextStyle(color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
