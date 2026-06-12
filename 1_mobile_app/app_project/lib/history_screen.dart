import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class HistoryScreen extends StatefulWidget {
  final String serialNumber;

  // 💡 ช่องรับฟังก์ชันสำหรับส่งคำสั่งกลับไปผูกกับปุ่มบน AppBar ของ MonitorScreen
  final void Function(VoidCallback refresh, VoidCallback settings)
      onRegisterController;

  const HistoryScreen({
    super.key,
    required this.serialNumber,
    required this.onRegisterController,
  });

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = false;

  bool _showTemp = true;
  bool _showHumi = true;
  bool _showSoil = true;
  bool _isBarChart = false;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _fetchHistory();

    // 💡 ส่งฟังก์ชันของหน้าตัวเองกลับไปลงทะเบียนที่หน้าจอหลัก (Monitor) ทันทีที่เปิดหน้านี้
    widget.onRegisterController(_fetchHistory, showHistoryChartSettings);
  }

  // 🔄 ฟังก์ชันรีเฟรชดึงข้อมูลประวัติจาก PHP API
  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    String s = DateFormat('yyyy-MM-dd').format(_startDate);
    String e = DateFormat('yyyy-MM-dd').format(_endDate);

    final String url =
        "${AppConfig.apiUrl("get_history.php")}?serial_number=${widget.serialNumber}&start=$s&end=$e";

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          _logs = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (err) {
      setState(() => _isLoading = false);
    }
  }

  void _updatePeriod(String period) {
    DateTime now = DateTime.now();
    DateTime start;
    switch (period) {
      case '3M':
        start = now.subtract(const Duration(days: 90));
        break;
      case '1M':
        start = now.subtract(const Duration(days: 30));
        break;
      case '1W':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'Today':
      default:
        start = DateTime(now.year, now.month, now.day);
        break;
    }
    setState(() {
      _selectedPeriod = period;
      _startDate = start;
      _endDate = now;
    });
    _fetchHistory();
  }

  Future<void> _pickDate(bool isStart) async {
    DateTime? p = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (p != null) {
      setState(() {
        _selectedPeriod = 'Custom';
        if (isStart) {
          _startDate = p;
        } else {
          _endDate = p;
        }
      });
      _fetchHistory();
    }
  }

  // ⚙️ หน้าต่าง Pop-up (BottomSheet) สำหรับเลือกเปิด/ปิดการแสดงผลข้อมูลบนกราฟ
  void showHistoryChartSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text("เลือกข้อมูลที่จะแสดงบนกราฟ",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 25),
                  _check("อุณหภูมิ (°C)", Colors.orange, _showTemp, (v) {
                    setState(() => _showTemp = v!);
                    setModalState(() {});
                  }),
                  _check("ความชื้นอากาศ (%)", Colors.blue, _showHumi, (v) {
                    setState(() => _showHumi = v!);
                    setModalState(() {});
                  }),
                  _check("ความชื้นดิน (%)", Colors.green, _showSoil, (v) {
                    setState(() => _showSoil = v!);
                    setModalState(() {});
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _check(String t, Color c, bool b, Function(bool?) f) =>
      CheckboxListTile(
        title: Text(t,
            style:
                TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w500)),
        value: b,
        onChanged: f,
        activeColor: c,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildChartCard(),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green))
                      : _buildDataTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.green.shade800,
      child: Row(
        children: [
          _dateButton("เริ่ม", _startDate, () => _pickDate(true)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, color: Colors.white54, size: 18),
          ),
          _dateButton("สิ้นสุด", _endDate, () => _pickDate(false)),
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime date, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white12, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
              Text(DateFormat('dd MMM yyyy').format(date),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 15, 20, 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.show_chart,
                    color: !_isBarChart ? Colors.green : Colors.grey),
                onPressed: () => setState(() => _isBarChart = false),
                tooltip: "กราฟเส้น",
              ),
              IconButton(
                icon: Icon(Icons.bar_chart,
                    color: _isBarChart ? Colors.green : Colors.grey),
                onPressed: () => setState(() => _isBarChart = true),
                tooltip: "กราฟแท่ง",
              ),
            ],
          ),
          SizedBox(
            height: 250,
            child: _logs.isEmpty && !_isLoading
                ? const Center(
                    child: Text("ไม่มีข้อมูลในช่วงที่เลือก",
                        style: TextStyle(color: Colors.grey)))
                : _isBarChart
                    ? BarChart(_mainBarChartData())
                    : LineChart(_mainChartData()),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _timeButton("วันนี้", "Today"),
              _timeButton("1 สัปดาห์", "1W"),
              _timeButton("1 เดือน", "1M"),
              _timeButton("3 เดือน", "3M"),
            ],
          )
        ],
      ),
    );
  }

  Widget _timeButton(String label, String value) {
    bool isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => _updatePeriod(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.green.shade800 : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            )),
      ),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      minY: 0,
      maxY: 100,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) => Text("${value.toInt()}",
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int i = value.toInt();
                  if (i >= 0 &&
                      i < _logs.length &&
                      (i % (_logs.length > 10 ? _logs.length ~/ 5 : 2) == 0)) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(_logs[i]['time'],
                          style:
                              const TextStyle(fontSize: 8, color: Colors.grey)),
                    );
                  }
                  return const SizedBox();
                })),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        if (_showTemp) _lineBarData(Colors.orange, 'temp'),
        if (_showHumi) _lineBarData(Colors.blue, 'humi'),
        if (_showSoil) _lineBarData(Colors.green, 'soil'),
      ],
    );
  }

  LineChartBarData _lineBarData(Color c, String k) => LineChartBarData(
        spots: _logs
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), (e.value[k] ?? 0).toDouble()))
            .toList(),
        isCurved: true,
        color: c,
        barWidth: 2,
        dotData: const FlDotData(show: false),
      );

  BarChartData _mainBarChartData() {
    return BarChartData(
      minY: 0,
      maxY: 100,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) => Text("${value.toInt()}",
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              int i = value.toInt();
              if (i >= 0 &&
                  i < _logs.length &&
                  (i % (_logs.length > 5 ? _logs.length ~/ 4 : 2) == 0)) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(_logs[i]['time'],
                      style: const TextStyle(fontSize: 8, color: Colors.grey)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      barGroups: _logs.asMap().entries.map((e) {
        int index = e.key;
        var log = e.value;

        return BarChartGroupData(
          x: index,
          barsSpace: 2,
          barRods: [
            if (_showTemp)
              BarChartRodData(
                  toY: (log['temp'] ?? 0).toDouble(),
                  color: Colors.orange,
                  width: 4),
            if (_showHumi)
              BarChartRodData(
                  toY: (log['humi'] ?? 0).toDouble(),
                  color: Colors.blue,
                  width: 4),
            if (_showSoil)
              BarChartRodData(
                  toY: (log['soil'] ?? 0).toDouble(),
                  color: Colors.green,
                  width: 4),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDataTable() {
    if (_logs.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ประวัติรายการ (${_logs.length})",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _logs.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, i) {
            final log = _logs[i];
            bool pumpOn = (log['pump'] == 1 || log['pump'] == true);
            bool lightOn = (log['light'] == 1 || log['light'] == true);

            return ListTile(
              dense: true,
              title: Text(log['time'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("T:${log['temp']}°C H:${log['humi']}% S:${log['soil']}%",
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 10),
                  Icon(Icons.lightbulb,
                      size: 14, color: lightOn ? Colors.orange : Colors.grey),
                  Icon(Icons.water_drop,
                      size: 14, color: pumpOn ? Colors.blue : Colors.grey),
                  const SizedBox(width: 4),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
