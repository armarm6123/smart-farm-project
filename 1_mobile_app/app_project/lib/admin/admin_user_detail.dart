import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // ใช้สำหรับสุ่มตัวเลข/ตัวอักษร
import '../config.dart';
import 'admin_farm_log_screen.dart';

class AdminUserDetail extends StatefulWidget {
  final String userId;
  final String name;

  AdminUserDetail({required this.userId, required this.name});

  @override
  State<AdminUserDetail> createState() => _AdminUserDetailState();
}

class _AdminUserDetailState extends State<AdminUserDetail> {
  late Future<List> _farmsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFarmsList();
  }

  void _refreshFarmsList() {
    setState(() {
      _farmsFuture = fetchFarms();
    });
  }

  // ฟังก์ชันดึงข้อมูลฟาร์มจาก API ของแอดมิน
  Future<List> fetchFarms() async {
    try {
      final String url =
          "${AppConfig.adminUrl("get_user_farms.php")}?user_id=${widget.userId}";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['farms'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching user farms: $e");
    }
    return [];
  }

  // ==========================================
  // ฟังก์ชันสุ่ม Serial Number (Gen SN)
  // ==========================================
  String _generateSerialNumber() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomStr =
        List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
    return "SN-$randomStr";
  }

  // ==========================================
  // ฟังก์ชันเปิด Dialog เพิ่มฟาร์มใหม่
  // ==========================================
  void _showAddFarmDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _snController = TextEditingController();

    _snController.text = _generateSerialNumber();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("เพิ่มฟาร์มใหม่",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อฟาร์ม",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.agriculture),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _snController,
                        decoration: const InputDecoration(
                          labelText: "Serial Number บอร์ด",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.developer_board),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.cached, color: Colors.blue),
                      tooltip: "สุ่มเลขใหม่",
                      onPressed: () {
                        setDialogState(() {
                          _snController.text = _generateSerialNumber();
                        });
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final farmName = _nameController.text.trim();
                final serialNumber = _snController.text.trim();

                if (farmName.isEmpty || serialNumber.isEmpty) {
                  _showErrorSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน");
                  return;
                }

                Navigator.pop(context);

                try {
                  final response = await http.post(
                    Uri.parse(AppConfig.adminUrl("admin_add_farm.php")),
                    body: {
                      "user_id": widget.userId,
                      "farm_name": farmName,
                      "serial_number": serialNumber,
                    },
                  );

                  final data = json.decode(response.body);
                  if (data['status'] == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("เพิ่มฟาร์มใหม่สำเร็จ!"),
                          backgroundColor: Colors.green),
                    );
                    _refreshFarmsList();
                  } else {
                    _showErrorSnackBar(data['message'] ?? "เกิดข้อผิดพลาด");
                  }
                } catch (e) {
                  _showErrorSnackBar("ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้");
                }
              },
              child: const Text("เพิ่มฟาร์ม",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 💡 แก้ไข: เปลี่ยนพารามิเตอร์แรกจาก farmId เป็น serialNumber
  Future<void> _editFarmName(String serialNumber, String currentName) async {
    final TextEditingController _nameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("แก้ไขชื่อฟาร์ม",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: "ชื่อฟาร์มใหม่",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final newName = _nameController.text.trim();
              if (newName.isEmpty) return;

              Navigator.pop(context);

              try {
                final response = await http.post(
                  Uri.parse(AppConfig.adminUrl("admin_edit_farm.php")),
                  body: {
                    "serial_number":
                        serialNumber, // 💡 แก้ไข: ส่งค่า serial_number แทน farm_id
                    "farm_name": newName,
                  },
                );

                final data = json.decode(response.body);
                if (data['status'] == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("แก้ไขชื่อฟาร์มเรียบร้อยแล้ว"),
                        backgroundColor: Colors.green),
                  );
                  _refreshFarmsList();
                } else {
                  _showErrorSnackBar(data['message'] ?? "เกิดข้อผิดพลาด");
                }
              } catch (e) {
                _showErrorSnackBar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้");
              }
            },
            child: const Text("บันทึก", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 💡 แก้ไข: เปลี่ยนพารามิเตอร์แรกจาก farmId เป็น serialNumber
  Future<void> _deleteFarm(String serialNumber, String farmName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("ยืนยันการลบฟาร์ม",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            "คุณต้องการลบฟาร์ม '$farmName' ออกจากระบบใช่หรือไม่?\n(การกระทำนี้ไม่สามารถย้อนกลับได้)"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              try {
                final response = await http.post(
                  Uri.parse(AppConfig.adminUrl("admin_delete_farm.php")),
                  body: {
                    "serial_number":
                        serialNumber, // 💡 แก้ไข: ส่งค่า serial_number แทน farm_id
                  },
                );

                final data = json.decode(response.body);
                if (data['status'] == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("ลบฟาร์มสำเร็จ"),
                        backgroundColor: Colors.redAccent),
                  );
                  _refreshFarmsList();
                } else {
                  _showErrorSnackBar(
                      data['message'] ?? "เกิดข้อผิดพลาดในการลบ");
                }
              } catch (e) {
                _showErrorSnackBar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้");
              }
            },
            child: const Text("ลบฟาร์ม", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showActionMenu(BuildContext context, Map farm) {
    // 💡 แก้ไข: เปลี่ยนไปอ่านค่าจาก 'serial_number' แทน 'id' ที่ไม่มีอยู่แล้ว
    final serialNumber = farm['serial_number'] ?? "";
    final farmName = farm['farm_name'] ?? "";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 5),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text("แก้ไขชื่อฟาร์ม"),
              onTap: () {
                Navigator.pop(context);
                _editFarmName(serialNumber,
                    farmName); // 💡 ส่งค่า serialNumber ไปทำงานแทน
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("ลบฟาร์มนี้ออกจากระบบ",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteFarm(serialNumber,
                    farmName); // 💡 ส่งค่า serialNumber ไปทำงานแทน
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Text("Farm Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFarmDialog,
        backgroundColor: Colors.green.shade600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("เพิ่มฟาร์ม",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 25, top: 10),
            child: Column(children: [
              const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 50, color: Colors.white)),
              const SizedBox(height: 10),
              Text(widget.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Text("User ID: #${widget.userId}",
                  style: const TextStyle(color: Colors.white60)),
            ]),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45)),
              ),
              child: FutureBuilder<List>(
                future: _farmsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.green));
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("เกิดข้อผิดพลาดในการดึงข้อมูล"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.agriculture_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("ไม่พบข้อมูลฟาร์มและ SN ของสมาชิกรายนี้",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 25, right: 25, top: 25, bottom: 80),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final farm = snapshot.data![index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10)
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminFarmLogScreen(
                                        farmName: farm['farm_name'] ??
                                            "ไม่ระบุชื่อฟาร์ม",
                                        serialNumber:
                                            farm['serial_number'] ?? "N/A",
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 5),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.router,
                                            color: Colors.green),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                farm['farm_name'] ??
                                                    "ไม่ระบุชื่อฟาร์ม",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            const SizedBox(height: 4),
                                            RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13),
                                                children: [
                                                  const TextSpan(text: "SN: "),
                                                  TextSpan(
                                                      text: farm[
                                                              'serial_number'] ??
                                                          "N/A",
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.blueGrey,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
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
                            IconButton(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.grey),
                              onPressed: () => _showActionMenu(context, farm),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
