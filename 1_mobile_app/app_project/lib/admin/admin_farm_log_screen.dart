import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class AdminFarmLogScreen extends StatefulWidget {
  final String farmName;
  final String serialNumber;

  AdminFarmLogScreen({required this.farmName, required this.serialNumber});

  @override
  _AdminFarmLogScreenState createState() => _AdminFarmLogScreenState();
}

class _AdminFarmLogScreenState extends State<AdminFarmLogScreen> {
  List logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    setState(() => isLoading = true);
    try {
      final String url =
          "${AppConfig.adminUrl("get_farm_logs.php")}?serial_number=${widget.serialNumber}";
      debugPrint("🔗 Calling API: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            logs = data['logs'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Flutter Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        elevation: 1,
        leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Column(
          children: [
            Text(widget.farmName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text("Admin Logs (SN: ${widget.serialNumber})",
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: fetchLogs,
              color: Colors.green,
              child: logs.isEmpty
                  ? _buildEmptyState()
                  : _buildFitDataTable(), // เรียกใช้ตารางแบบพอดีหน้าจอ
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.cloud_off, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("ไม่พบประวัติข้อมูลเซนเซอร์",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  // --- ตารางเวอร์ชันย่อส่วน บีบข้อมูลให้แสดงครบถ้วนในหน้าจอเดียวไม่ต้องเลื่อนซ้ายขวา ---
  Widget _buildFitDataTable() {
    return SizedBox(
      width: double.infinity, // บังคับกว้างเต็มจอพอดี
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical, // เลื่อนดูแนวตั้งได้อย่างเดียว
        child: Container(
          color: Colors.white,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
            dataRowHeight: 35, // บีบความสูงแถวให้เล็กลงเพื่อความหนาแน่นข้อมูล
            headingRowHeight: 38,
            horizontalMargin: 8, // ลดระยะขอบข้างตารางซ้ายขวาเพื่อเพิ่มพื้นที่
            columnSpacing:
                6, // บีบระยะห่างระหว่างคอลลัมน์ให้ชิดกันที่สุดเพื่อไม่ให้ล้นจอ
            columns: const [
              DataColumn(
                  label: Text('DATE/TIME',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
              DataColumn(
                  label: Text('TEMP',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
              DataColumn(
                  label: Text('HUMI',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
              DataColumn(
                  label: Text('SOIL',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
              DataColumn(
                  label: Text('LAMP',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
              DataColumn(
                  label: Text('PUMP',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
            ],
            rows: logs.map((log) {
              bool isLightOn = (log['light'] == 1 || log['light'] == true);
              bool isPumpOn = (log['pump'] == 1 || log['pump'] == true);

              // ย่อเวลาจัด Format เล็กน้อยให้สั้นลง เช่น "2026-05-15 14:30:22" ตัดเหลือแค่ "15 14:30" หรือคงไว้แบบกระชับ
              String rawDate = log['recorded_at'] ?? "-";
              String shortDate = rawDate;
              if (rawDate.length >= 16) {
                // ตัดเอาเฉพาะ "วัน เวลา:นาที" (เช่น 15/05 14:30) เพื่อไม่ให้คอลัมน์แรกดึงพื้นที่เพื่อน
                shortDate =
                    "${rawDate.substring(8, 10)}/${rawDate.substring(5, 7)} ${rawDate.substring(11, 16)}";
              }

              return DataRow(
                cells: [
                  DataCell(
                      Text(shortDate, style: const TextStyle(fontSize: 10))),
                  DataCell(Text("${log['temperature']}°",
                      style: const TextStyle(fontSize: 10))),
                  DataCell(Text("${log['humidity']}%",
                      style: const TextStyle(fontSize: 10))),
                  DataCell(Text("${log['soil_moisture']}%",
                      style: const TextStyle(fontSize: 10))),

                  // แสดงสถานะสั้นๆ ด้วยตัวอักษรสีเพื่อความเร็วในการสังเกต
                  DataCell(Text(
                    isLightOn ? "ON" : "OFF",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            isLightOn ? Colors.orange.shade700 : Colors.grey),
                  )),
                  DataCell(Text(
                    isPumpOn ? "ON" : "OFF",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPumpOn ? Colors.blue.shade600 : Colors.grey),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
