import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_device_screen.dart';
import 'monitor_screen.dart';
import 'login_screen.dart';
import 'config.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String name;
  final String tokenId;

  HomeScreen({required this.userId, required this.name, required this.tokenId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _farmData;

  final List<Color> _avatarColors = [
    Colors.green.shade700,
    Colors.teal.shade700,
    Colors.lightGreen.shade800,
    Colors.cyan.shade700,
    Colors.blueGrey.shade700,
    Colors.orange.shade700,
  ];

  @override
  void initState() {
    super.initState();
    _farmData = fetchFarms();
  }

  void _refreshData() {
    setState(() {
      _farmData = fetchFarms();
    });
  }

  String _getFarmInitials(String farmName) {
    String name = farmName.trim();
    if (name.isEmpty) return 'F';
    List<String> words = name.split(RegExp(r'\s+'));
    if (words.length > 1) {
      String firstInitial = words[0].isNotEmpty ? words[0].substring(0, 1) : '';
      String secondInitial =
          words[1].isNotEmpty ? words[1].substring(0, 1) : '';
      return (firstInitial + secondInitial).toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  Color _getFarmColor(String farmName) {
    if (farmName.isEmpty) return Colors.green;
    int charSum = 0;
    for (int i = 0; i < farmName.length; i++) {
      charSum += farmName.codeUnitAt(i);
    }
    return _avatarColors[charSum % _avatarColors.length];
  }

  Future<List<dynamic>> fetchFarms() async {
    final String url =
        "${AppConfig.apiUrl("get_farm.php")}?user_id=${widget.userId}";
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 💡 แก้ไข: เปลี่ยนการรับค่าจาก farmId (int) เป็น serialNumber (String) เพื่อระบุตัวตนฟาร์ม
  Future<void> _editFarmName(String serialNumber, String currentName) async {
    TextEditingController _nameEditCtrl =
        TextEditingController(text: currentName);
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Edit Farm Name"),
            content: TextField(
              controller: _nameEditCtrl,
              decoration: const InputDecoration(
                labelText: "ชื่อฟาร์มใหม่",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("ยกเลิก")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("บันทึก", style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && _nameEditCtrl.text.trim().isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(AppConfig.apiUrl("edit_farm.php")),
          body: {
            "serial_number": serialNumber, // 💡 ส่ง serial_number แทน id เก่า
            "farm_name": _nameEditCtrl.text.trim()
          },
        );
        var data = json.decode(response.body);
        if (data['status'] == "success") {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("อัปเดตชื่อฟาร์มสำเร็จ")));
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? "ไม่สามารถแก้ไขได้")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อ")));
      }
    }
  }

  // 💡 แก้ไข: เปลี่ยนการรับค่าจาก farmId (int) เป็น serialNumber (String) สำหรับการลบฟาร์ม
  Future<void> _deleteFarm(String serialNumber) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("ยืนยันการลบ"),
            content: const Text("คุณต้องการลบฟาร์มนี้ออกจากระบบใช่หรือไม่?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("ยกเลิก")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("ลบ", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final response = await http.post(
          Uri.parse(AppConfig.apiUrl("delete_farm.php")),
          body: {
            "serial_number": serialNumber
          }, // 💡 ส่ง serial_number แทน id เก่า
        );
        var data = json.decode(response.body);
        if (data['status'] == "success") {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("ลบสำเร็จ")));
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? "ลบไม่สำเร็จ")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("เชื่อมต่อผิดพลาด")));
      }
    }
  }

  Future<void> _deleteAccount() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text("ยืนยันการลบบัญชี",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
                "การลบบัญชีจะทำลายข้อมูลฟาร์มและประวัติทั้งหมดของคุณอย่างถาวร และไม่สามารถกู้คืนได้ คุณแน่ใจใช่หรือไม่?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("ยกเลิก",
                      style: TextStyle(color: Colors.grey.shade600))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("ยืนยันลบถาวร",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final response = await http.post(
          Uri.parse(AppConfig.apiUrl("delete_user.php")),
          body: {"user_id": widget.userId.toString()},
        ).timeout(const Duration(seconds: 10));

        var data = json.decode(response.body);
        if (data['status'] == "success") {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ลบบัญชีผู้ใช้งานเรียบร้อยแล้ว")));
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
          }
        } else {
          _showSnackBar("เกิดข้อผิดพลาดจากเซิร์ฟเวอร์: ${data['message']}");
        }
      } catch (e) {
        _showSnackBar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์เพื่อลบบัญชีได้");
      }
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _logout() {
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

  void _navigateToAddDevice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddDeviceScreen(userId: widget.userId)),
    );
    if (result == true) _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildUserDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade800, Colors.green.shade50, Colors.white],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  child: _buildFarmList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddDevice,
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text("เพิ่มฟาร์ม",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("สวัสดี,",
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
              Text(widget.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.account_circle_rounded,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _logout,
                child: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.logout_rounded, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade900, Colors.green.shade50, Colors.white],
            stops: const [0.0, 0.25, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 29,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.person_rounded,
                          size: 38, color: Colors.green.shade800),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "ผู้ใช้งานระบบสมาร์ทฟาร์ม",
                          style: TextStyle(
                              color: Colors.green.shade200, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vpn_key_rounded,
                              color: Colors.green.shade700, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "User Token",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.green.shade200, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              widget.tokenId.isEmpty
                                  ? "ไม่มีข้อมูล Token"
                                  : widget.tokenId,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "*ใช้รหัสนี้สำหรับตั้งค่าบนบอร์ดควบคุมฮาร์ดแวร์",
                              style: TextStyle(
                                  color: Colors.green.shade700, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Divider(height: 30),
                      Card(
                        color: Colors.red.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.red.shade100),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteAccount();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_forever_rounded,
                                    color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  "ลบบัญชีผู้ใช้งานถาวร",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmList() {
    return FutureBuilder<List<dynamic>>(
      future: _farmData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SingleChildScrollView(child: _buildEmptyState());
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final farm = Map<String, dynamic>.from(snapshot.data![index]);
            return _buildFarmCard(farm);
          },
        );
      },
    );
  }

  Widget _buildFarmCard(Map<String, dynamic> farm) {
    // 💡 แก้ไข: ดึงค่า serial_number ออกมาตรงๆ เพื่อใช้งานแทนการค้นหาด้วย ID
    final String farmName = farm['farm_name']?.toString() ?? 'ไม่มีชื่อฟาร์ม';
    final String sn = farm['serial_number']?.toString() ?? '-';

    final String initials = _getFarmInitials(farmName);
    final Color farmColor = _getFarmColor(farmName);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              color: farmColor.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                  color: farmColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        title: Text(farmName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text("SN: $sn\n(กดค้างเพื่อลบ)"),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey),
          // 💡 แก้ไข: ส่งค่า sn (Serial Number) ไปที่ฟังก์ชันแทน id เก่า
          onPressed: () => _editFarmName(sn, farmName),
        ),
        // 💡 แก้ไข: ส่งค่า sn (Serial Number) ไปที่ฟังก์ชันสำหรับการลบฟาร์มเช่นกัน
        onLongPress: () => _deleteFarm(sn),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonitorScreen(
                farmName: farmName,
                serialNumber: sn,
                tokenId: widget.tokenId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          const Text("ไม่พบฟาร์มในระบบของคุณ",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const Text("ลองลากนิ้วลงเพื่อดึงข้อมูลใหม่",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
