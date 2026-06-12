import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../login_screen.dart';
import 'admin_user_detail.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List users = [];
  List filteredUsers = []; // เก็บรายชื่อผู้ใช้ที่ผ่านการกรองคำค้นหาแล้ว
  Map stats = {"total_users": "0", "total_farms": "0"}; // ตัด active_sn ออก
  bool isLoading = true;
  final TextEditingController _searchController =
      TextEditingController(); // ควบคุมช่องค้นหา

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    await Future.wait([fetchUsers(), fetchStats()]);
    setState(() => isLoading = false);
  }

  Future<void> fetchStats() async {
    try {
      final response =
          await http.get(Uri.parse(AppConfig.adminUrl("get_stats.php")));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            stats = {
              "total_users": data['total_users'].toString(),
              "total_farms":
                  data['total_farms'].toString(), // เก็บเฉพาะจำนวนฟาร์ม/SN รวม
            };
          });
        }
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    }
  }

  Future<void> fetchUsers() async {
    try {
      final response =
          await http.get(Uri.parse(AppConfig.adminUrl("get_users.php")));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            users = data['users'] ?? [];
            _filterUsers(_searchController.text);
          });
        }
      }
    } catch (e) {
      debugPrint("Users Error: $e");
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        final searchQuery = query.toLowerCase();
        filteredUsers = users.where((user) {
          final username = (user['username'] ?? '').toString().toLowerCase();
          final userId = (user['id'] ?? '').toString();
          // ดึงค่า token_id มาตรวจสอบ (กรณีเป็น null ให้เป็น string ว่าง)
          final tokenId = (user['token_id'] ?? '').toString().toLowerCase();

          // เพิ่มเงื่อนไขค้นหาด้วย tokenId เข้าไป
          return username.contains(searchQuery) ||
              userId.contains(searchQuery) ||
              tokenId.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> addUser(String username, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.adminUrl("add_user.php")),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "username": username,
          "password": password,
          "role": role,
        },
      );
      final resData = json.decode(response.body);
      if (resData['status'] == 'success') {
        refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? "เพิ่มผู้ใช้สำเร็จ")));
      } else {
        _showErrorSnackBar(resData['message'] ?? "เกิดข้อผิดพลาด");
      }
    } catch (e) {
      _showErrorSnackBar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้");
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.adminUrl("delete_user.php")),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"user_id": id},
      );
      final resData = json.decode(response.body);
      if (resData['status'] == 'success') {
        refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? "ลบผู้ใช้สำเร็จ")));
      } else {
        _showErrorSnackBar(resData['message'] ?? "ไม่สามารถลบข้อมูลได้");
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        icon:
            const Icon(Icons.logout_rounded, size: 45, color: Colors.redAccent),
        title: const Text("ออกจากระบบ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("ยืนยันการออกจากระบบใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text("ยกเลิก", style: TextStyle(color: Colors.grey.shade600)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              child: const Text("ออกจากระบบ",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map user) {
    final TextEditingController userCtrl =
        TextEditingController(text: user['username']?.toString() ?? "");
    final TextEditingController passCtrl =
        TextEditingController(text: user['password']?.toString() ?? "");
    bool isVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("แก้ไขข้อมูลสมาชิก",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(
                    labelText: "ชื่อผู้ใช้งาน",
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passCtrl,
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    labelText: "รหัสผ่าน",
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setStateDialog(() => isVisible = !isVisible),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("ยกเลิก", style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final response = await http.post(
                  Uri.parse(AppConfig.adminUrl("update_user.php")),
                  body: {
                    "id": user['id'].toString(),
                    "username": userCtrl.text,
                    "password": passCtrl.text,
                  },
                );
                if (json.decode(response.body)['status'] == 'success') {
                  Navigator.pop(context);
                  refreshData();
                }
              },
              child: const Text("บันทึกข้อมูล",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final TextEditingController userCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    String selectedRole = 'user';
    bool isVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("เพิ่มบัญชีผู้ใช้ใหม่",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(
                    labelText: "ชื่อผู้ใช้งาน (Username)",
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passCtrl,
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    labelText: "รหัสผ่านตั้งต้น",
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setStateDialog(() => isVisible = !isVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: "สิทธิ์การใช้งาน (Role)",
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'user', child: Text("User (ทั่วไป)")),
                    DropdownMenuItem(
                        value: 'admin', child: Text("Admin (ผู้ควบคุม)")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => selectedRole = val);
                    }
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("ยกเลิก", style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (userCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                  Navigator.pop(context);
                  addUser(userCtrl.text, passCtrl.text, selectedRole);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("กรุณากรอกข้อมูลให้ครบถ้วน"),
                    backgroundColor: Colors.orange,
                  ));
                }
              },
              child: const Text("สร้างบัญชี",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ?"),
        content: Text("ข้อมูลของ ${user['username']} จะถูกลบถาวร"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteUser(user['id'].toString());
            },
            child: const Text("ยืนยันลบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ปรับดีไซน์ให้ขนาดตัวอักษรและไอคอนลงตัวขึ้นเมื่อเหลือ 2 การ์ด ซ้าย-ขวา
  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        // ปรับด้านในเป็น Row ซ้ายไอคอน-ขวาตัวเลข ช่วยประหยัดพื้นที่แนวตั้งและดูโมเดิร์นขึ้น
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 20,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.amber.shade700,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("เพิ่มผู้ใช้",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Admin Dashboard",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        Text("ระบบจัดการหลังบ้าน",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ]),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.logout_rounded, color: Colors.white),
                      onPressed: _showLogoutDialog,
                    ),
                  )
                ],
              ),
            ),

            // --- 📊 ปรับตรงนี้ให้เหลือ 2 การ์ด บาลานซ์ ซ้าย-ขวา เต็มหน้าพอดี ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          "ผู้ใช้งานทั้งหมด",
                          stats['total_users'].toString(),
                          Icons.group,
                          Colors.blue)),
                  const SizedBox(
                      width: 12), // เพิ่มระยะห่างตรงกลางให้ดูสบายตาขึ้น
                  Expanded(
                      child: _buildStatCard(
                          "ฟาร์มทั้งหมด (SN)",
                          stats['total_farms'].toString(),
                          Icons.agriculture,
                          Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterUsers,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: "ค้นหาชื่อผู้ใช้ หรือ ID...",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.green.shade800),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterUsers('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(30, 5, 30, 5),
                      child: Row(children: [
                        Text("การจัดการสมาชิก",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))
                      ]),
                    ),
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.green))
                          : RefreshIndicator(
                              onRefresh: refreshData,
                              child: filteredUsers.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.15),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.search_off,
                                                  size: 65,
                                                  color: Colors.grey.shade300),
                                              const SizedBox(height: 10),
                                              Text(
                                                "ไม่พบสมาชิกที่ต้องการค้นหา",
                                                style: TextStyle(
                                                    color:
                                                        Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          child: ListTile(
                                            leading: const CircleAvatar(
                                                backgroundColor: Colors.white,
                                                child: Icon(Icons.person,
                                                    color: Colors.green)),
                                            title: Text(
                                                user['username'] ?? "N/A",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text("ID: #${user['id']}"),
                                                Text(
                                                  "Token: ${user['token_id'] ?? 'N/A'}",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.green.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue),
                                                  onPressed: () =>
                                                      _showEditDialog(user),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent),
                                                  onPressed: () =>
                                                      _confirmDelete(user),
                                                ),
                                              ],
                                            ),
                                            onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AdminUserDetail(
                                                            userId: user['id']
                                                                .toString(),
                                                            name: user[
                                                                'username']))),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
