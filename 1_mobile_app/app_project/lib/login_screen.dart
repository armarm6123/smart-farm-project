import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'register_screen.dart';
import 'admin/admin_screen.dart'; // อย่าลืม Import หน้า Admin ที่อยู่ในโฟลเดอร์ admin
import 'config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    if (userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      showError("กรุณากรอกชื่อผู้ใช้และรหัสผ่าน");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiUrl("login.php")),
        body: {
          "username": userCtrl.text.trim(),
          "password": passCtrl.text.trim(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == "success") {
          int userId = int.tryParse(data['user_id'].toString()) ?? 0;
          String displayName = userCtrl.text.trim();
          String role = data['role'] ?? 'user'; // รับค่า role จาก API

          // 🛠️ แก้ไข 1: ดึงค่า token_id ที่ตอบกลับมาจากไฟล์ PHP ล่าสุด
          String tokenId = data['token_id']?.toString() ?? '';

          if (mounted) {
            // --- เช็คสิทธิ์เพื่อแยกหน้าจอตรงนี้ ---
            if (role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    userId: userId,
                    name: displayName,
                    tokenId:
                        tokenId, // ◄ 🛠️ แก้ไข 2: ส่งค่า Token ตัวจริงจาก DB ไปหน้า Home ด้วย!
                  ),
                ),
              );
            }
          }
        } else {
          showError(data['message'] ?? "ชื่อผู้ใช้หรือรหัสผ่านผิด");
        }
      } else {
        showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      showError("ไม่สามารถเชื่อมต่อได้: ตรวจสอบ IP หรือ XAMPP");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.spa_rounded,
                      size: 80, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text("SMART FARM",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2)),
                const Text("ระบบจัดการฟาร์มอัจฉริยะ",
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 40),
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
                      const SizedBox(height: 30),
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.green)
                          : ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("เข้าสู่ระบบ",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "ยังไม่มีบัญชี? สมัครสมาชิกที่นี่",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
