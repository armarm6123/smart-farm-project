import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'config.dart';

class AddDeviceScreen extends StatefulWidget {
  final int userId;
  AddDeviceScreen({required this.userId});

  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController snCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    generateNewSN(); // เจนเลขทันทีที่เปิดหน้า
  }

  // ฟังก์ชันสุ่ม Serial Number
  void generateNewSN() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    String randomStr = String.fromCharCodes(Iterable.generate(
        7, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    setState(() {
      snCtrl.text = "SN-$randomStr";
    });
  }

  Future<void> saveFarm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        // ใช้ AppConfig เพื่อให้จัดการ IP ง่ายในจุดเดียว
        Uri.parse(AppConfig.apiUrl("add_farm.php")),
        body: {
          "user_id": widget.userId.toString(),
          "farm_name": nameCtrl.text.trim(),
          "serial_number": snCtrl.text.trim(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == "success") {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("สร้างฟาร์มและจดทะเบียนอุปกรณ์สำเร็จ!"),
                backgroundColor: Colors.green),
          );
        } else {
          _showErrorDialog(data['message']);
        }
      } else {
        _showErrorDialog("Server Error: รหัสสถานะ ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("เชื่อมต่อไม่ได้: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("แจ้งเตือน"),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("ตกลง"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("เพิ่มฟาร์มใหม่",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ตั้งชื่อฟาร์มของคุณ",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              SizedBox(height: 10),
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "ชื่อฟาร์ม",
                  prefixIcon: Icon(Icons.home_work),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                validator: (v) => v!.isEmpty ? "กรุณากรอกชื่อฟาร์ม" : null,
              ),
              SizedBox(height: 30),
              Text("Serial Number (ใช้สำหรับอุปกรณ์)",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: snCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon: Icon(Icons.vpn_key),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(15)),
                    child: IconButton(
                      icon: Icon(Icons.refresh,
                          color: Colors.green.shade700, size: 30),
                      onPressed: generateNewSN,
                      tooltip: "สุ่มเลขใหม่",
                    ),
                  )
                ],
              ),
              SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveFarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("บันทึกฟาร์ม",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
