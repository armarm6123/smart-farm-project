import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mqtt_manager.dart';
import 'history_screen.dart';

class MonitorScreen extends StatefulWidget {
  final String farmName;
  final String serialNumber;
  final String tokenId;

  const MonitorScreen({
    super.key,
    required this.farmName,
    required this.serialNumber,
    required this.tokenId,
  });

  @override
  _MonitorScreenState createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final MQTTManager mqtt = MQTTManager();
  final TextEditingController lowController = TextEditingController();
  final TextEditingController highController = TextEditingController();

  final FocusNode lowFocusNode = FocusNode();
  final FocusNode highFocusNode = FocusNode();

  int _selectedIndex = 0;

  bool _showTemp = true,
      _showHumi = true,
      _showSoil = true,
      _showPumpStatus = true;
  bool _showLightCtrl = true, _showManualPump = true, _showAutoCtrl = true;

  List<int> _smallOrder = [0, 1, 2, 3];
  List<int> _largeOrder = [4, 5, 6];

  VoidCallback? _onHistoryRefresh;
  VoidCallback? _onHistorySettings;

  @override
  void initState() {
    super.initState();
    // เริ่มการเชื่อมต่อ MQTT
    mqtt.connect(widget.serialNumber, widget.tokenId);
    // โหลดการตั้งค่าลำดับวิดเจ็ตที่จัดไว้
    _loadDisplaySettings();
  }

  @override
  void dispose() {
    mqtt.disconnect();
    lowController.dispose();
    highController.dispose();
    lowFocusNode.dispose();
    highFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDisplaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sn = widget.serialNumber;
    setState(() {
      _showTemp = prefs.getBool('${sn}_show_temp') ?? true;
      _showHumi = prefs.getBool('${sn}_show_humi') ?? true;
      _showSoil = prefs.getBool('${sn}_show_soil') ?? true;
      _showPumpStatus = prefs.getBool('${sn}_show_pump_status') ?? true;
      _showLightCtrl = prefs.getBool('${sn}_show_light_ctrl') ?? true;
      _showManualPump = prefs.getBool('${sn}_show_manual_pump') ?? true;
      _showAutoCtrl = prefs.getBool('${sn}_show_auto_ctrl') ?? true;

      final savedSmall = prefs.getStringList('${sn}_small_v23');
      final savedLarge = prefs.getStringList('${sn}_large_v23');
      if (savedSmall != null) _smallOrder = savedSmall.map(int.parse).toList();
      if (savedLarge != null) _largeOrder = savedLarge.map(int.parse).toList();
    });
  }

  Future<void> _saveOrderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${widget.serialNumber}_small_v23',
        _smallOrder.map((e) => e.toString()).toList());
    await prefs.setStringList('${widget.serialNumber}_large_v23',
        _largeOrder.map((e) => e.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.farmName,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.serialNumber));
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("คัดลอกรหัส Serial Number แล้ว")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 22),
            onPressed: () {
              if (_selectedIndex == 0) {
                mqtt.connect(widget.serialNumber, widget.tokenId);
              } else {
                _onHistoryRefresh?.call();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 22),
            onPressed: () {
              if (_selectedIndex == 0) {
                _showDisplaySettings();
              } else {
                _onHistorySettings?.call();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMonitorContent(),
          HistoryScreen(
            serialNumber: widget.serialNumber,
            onRegisterController: (refresh, settings) {
              _onHistoryRefresh = refresh;
              _onHistorySettings = settings;
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: "ปัจจุบัน"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), label: "ประวัติ"),
        ],
      ),
    );
  }

  Widget _buildMonitorContent() {
    return ListenableBuilder(
      listenable: mqtt,
      builder: (context, child) {
        // ซิงค์ข้อมูลขีดจำกัดความชื้นจากบอร์ดมาแสดงในช่องพิมพ์ (ถ้าไม่ได้กำลังพิมพ์อยู่)
        if (!lowFocusNode.hasFocus && mqtt.soilLow > 0) {
          lowController.text = mqtt.soilLow.toStringAsFixed(0);
        }
        if (!highFocusNode.hasFocus && mqtt.soilHigh > 0) {
          highController.text = mqtt.soilHigh.toStringAsFixed(0);
        }

        List<GridItemData> smallItems = [];
        List<GridItemData> largeItems = [];

        if (_showTemp) {
          smallItems.add(GridItemData(
              id: 0,
              child: _buildSensorCard(
                  "อุณหภูมิ",
                  "${mqtt.temp.toStringAsFixed(1)}°C",
                  Icons.thermostat_rounded,
                  Colors.orange)));
        }
        if (_showHumi) {
          smallItems.add(GridItemData(
              id: 1,
              child: _buildSensorCard(
                  "ความชื้นอากาศ",
                  "${mqtt.humi.toStringAsFixed(1)}%",
                  Icons.cloud_queue_rounded,
                  Colors.blue)));
        }
        if (_showSoil) {
          smallItems.add(GridItemData(
              id: 2,
              child: _buildSensorCard(
                  "ความชื้นในดิน",
                  "${mqtt.soil.toStringAsFixed(0)}%",
                  Icons.grass_rounded,
                  Colors.green)));
        }
        if (_showPumpStatus) {
          // ใช้ค่าทำงานจริงในการระบุสถานะสีของการ์ดปั๊มน้ำ
          smallItems.add(GridItemData(
              id: 3, child: _buildPumpStatusCard(mqtt.actualPumpStatus)));
        }

        smallItems.sort((a, b) =>
            _smallOrder.indexOf(a.id).compareTo(_smallOrder.indexOf(b.id)));

        if (_showLightCtrl) {
          largeItems.add(GridItemData(id: 4, child: _buildLightControlCard()));
        }
        if (_showManualPump) {
          largeItems.add(GridItemData(id: 5, child: _buildManualControlCard()));
        }
        if (_showAutoCtrl) {
          largeItems.add(GridItemData(id: 6, child: _buildAutoControlCard()));
        }

        largeItems.sort((a, b) =>
            _largeOrder.indexOf(a.id).compareTo(_largeOrder.indexOf(b.id)));

        return Column(
          children: [
            _buildStatusHeader(mqtt.isConnected),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: StableSlideGridContainer(
                  smallItems: smallItems,
                  largeItems: largeItems,
                  spacing: 15,
                  onSmallReorder: (oldIdx, newIdx) => setState(() {
                    _smallOrder.insert(newIdx, _smallOrder.removeAt(oldIdx));
                    _saveOrderSettings();
                  }),
                  onLargeReorder: (oldIdx, newIdx) => setState(() {
                    _largeOrder.insert(newIdx, _largeOrder.removeAt(oldIdx));
                    _saveOrderSettings();
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusHeader(bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.shade700 : Colors.deepOrange.shade600,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
                isConnected
                    ? Icons.check_circle_rounded
                    : Icons.sync_problem_rounded,
                color: Colors.white,
                size: 16),
            const SizedBox(width: 8),
            Text(
                isConnected
                    ? "เชื่อมต่อเซิร์ฟเวอร์เรียบร้อย"
                    : "ขาดการเชื่อมต่อ",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 6),
          Text("Serial Number: ${widget.serialNumber}",
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSensorCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
    );
  }

  Widget _buildPumpStatusCard(bool isWorking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isWorking ? Colors.blue.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop,
                color: isWorking ? Colors.white : Colors.blue, size: 24),
            const SizedBox(height: 10),
            Text("สถานะปั๊ม",
                style: TextStyle(
                    color: isWorking ? Colors.white70 : Colors.grey.shade500,
                    fontSize: 12)),
            Text(isWorking ? "ทำงาน" : "ปิดอยู่",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isWorking ? Colors.white : Colors.black)),
          ]),
    );
  }

  Widget _buildManualControlCard() {
    bool isWorking = mqtt.actualPumpStatus;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        CircleAvatar(
            backgroundColor:
                isWorking ? Colors.blue.shade50 : Colors.grey.shade50,
            child: Icon(Icons.water_drop,
                color: isWorking ? Colors.blue : Colors.grey)),
        const SizedBox(width: 15),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("ปั๊มน้ำ (Manual)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(
              mqtt.isAutoMode
                  ? "🔴 บอร์ดกำลังรันระบบออโต้"
                  : "เปิด-ปิดปั๊มน้ำด้วยมือ",
              style: TextStyle(
                  fontSize: 12,
                  color: mqtt.isAutoMode
                      ? Colors.red.shade400
                      : Colors.grey.shade500,
                  fontWeight:
                      mqtt.isAutoMode ? FontWeight.bold : FontWeight.normal)),
        ])),
        Switch(
            value: isWorking,
            activeColor: Colors.blue,
            // 🟢 เมื่อเปิดใช้โหมด Auto สวิตช์แมนนวลจะส่งค่าคลุมด้วย null เพื่อล็อกไม่ให้ผู้ใช้กดเล่นจนค่าดีดชนกัน
            onChanged: mqtt.isAutoMode ? null : (val) => mqtt.togglePump(val))
      ]),
    );
  }

  Widget _buildLightControlCard() {
    bool isLightOn = mqtt.actualLightStatus;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        CircleAvatar(
            backgroundColor:
                isLightOn ? Colors.yellow.shade50 : Colors.grey.shade50,
            child: Icon(Icons.lightbulb_outline,
                color: isLightOn ? Colors.yellow.shade800 : Colors.grey)),
        const SizedBox(width: 15),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("หลอดไฟ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text("เปิด-ปิดไฟส่องสว่าง",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ])),
        Switch(
            value: isLightOn,
            activeColor: Colors.yellow.shade800,
            onChanged: (val) => mqtt.toggleLight(val))
      ]),
    );
  }

  Widget _buildAutoControlCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("ระบบอัตโนมัติ (ปั๊มน้ำ)",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Switch(
              value: mqtt.isAutoMode,
              activeColor: Colors.green,
              onChanged: (val) async {
                if (val &&
                    (lowController.text.isEmpty ||
                        highController.text.isEmpty)) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "⚠️ กรุณากรอกช่วงความชื้นให้ครบถ้วนก่อนเปิดระบบ"),
                      backgroundColor: Colors.deepOrange,
                    ),
                  );
                  return;
                }

                // สั่งเปิดหรือปิดระบบออโต้ (ถ้าปิดจะพ่วงดับปั๊มน้ำส่งตรงไปยังบอร์ดทันที)
                mqtt.sendAutoSettings(
                    val,
                    double.tryParse(lowController.text) ?? 0,
                    double.tryParse(highController.text) ?? 0);
              })
        ]),
        const SizedBox(height: 15),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _buildInputField(
                  lowController, lowFocusNode, "ความชื้นต่ำสุด %")),
          const SizedBox(width: 12),
          Expanded(
              child: _buildInputField(
                  highController, highFocusNode, "ความชื้นสูงสุด %")),
        ]),
      ]),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, FocusNode focusNode, String label) {
    bool isEnabled = !mqtt.isAutoMode;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: isEnabled,
      keyboardType: TextInputType.number,
      onChanged: (val) {
        if (isEnabled) {
          mqtt.sendAutoSettings(
              mqtt.isAutoMode,
              double.tryParse(lowController.text) ?? 0,
              double.tryParse(highController.text) ?? 0);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.green : Colors.grey),
        filled: true,
        fillColor: isEnabled ? Colors.grey.shade50 : Colors.grey.shade200,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.green, width: 1.5)),
      ),
    );
  }

  void _showDisplaySettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Center(
                  child: Text("เปิด-ปิดวิดเจ็ต",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold))),
              const Divider(height: 25),
              _buildTile(setModalState, "แสดงการ์ดอุณหภูมิ", _showTemp,
                  (val) => _showTemp = val, 'show_temp'),
              _buildTile(setModalState, "แสดงการ์ดความชื้นอากาศ", _showHumi,
                  (val) => _showHumi = val, 'show_humi'),
              _buildTile(setModalState, "แสดงการ์ดความชื้นในดิน", _showSoil,
                  (val) => _showSoil = val, 'show_soil'),
              _buildTile(setModalState, "แสดงการ์ดสถานะปั๊ม", _showPumpStatus,
                  (val) => _showPumpStatus = val, 'show_pump_status'),
              _buildTile(setModalState, "แสดงแผงควบคุมหลอดไฟ", _showLightCtrl,
                  (val) => _showLightCtrl = val, 'show_light_ctrl'),
              _buildTile(
                  setModalState,
                  "แสดงสวิตช์เปิดปิดปั๊มมือ",
                  _showManualPump,
                  (val) => _showManualPump = val,
                  'show_manual_pump'),
              _buildTile(
                  setModalState,
                  "แสดงระบบควบคุมอัตโนมัติ",
                  _showAutoCtrl,
                  (val) => _showAutoCtrl = val,
                  'show_auto_ctrl'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(StateSetter setModalState, String title, bool value,
      Function(bool) action, String key) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: Colors.green.shade700,
      onChanged: (val) {
        setState(() => action(val));
        setModalState(() => action(val));
        SharedPreferences.getInstance()
            .then((prefs) => prefs.setBool('${widget.serialNumber}_$key', val));
      },
    );
  }
}

class GridItemData {
  final int id;
  final Widget child;
  GridItemData({required this.id, required this.child});
}

class StableSlideGridContainer extends StatefulWidget {
  final List<GridItemData> smallItems;
  final List<GridItemData> largeItems;
  final double spacing;
  final void Function(int oldIndex, int newIndex) onSmallReorder;
  final void Function(int oldIndex, int newIndex) onLargeReorder;

  const StableSlideGridContainer({
    super.key,
    required this.smallItems,
    required this.largeItems,
    required this.spacing,
    required this.onSmallReorder,
    required this.onLargeReorder,
  });

  @override
  State<StableSlideGridContainer> createState() =>
      _StableSlideGridContainerState();
}

class _StableSlideGridContainerState extends State<StableSlideGridContainer> {
  int? _activeSmallIdx;
  int? _activeLargeIdx;
  Offset _dragPosition = Offset.zero;
  Offset _touchPointerOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    double totalWidth = MediaQuery.of(context).size.width - 40;
    double halfWidth = (totalWidth - widget.spacing) / 2;

    List<Widget> normalLayerChildren = [];
    Widget? activeFloatingCard;

    double smallZoneTop = 0;
    for (int i = 0; i < widget.smallItems.length; i++) {
      final item = widget.smallItems[i];
      double h = 125;
      Offset slotOffset =
          Offset((i % 2 == 0) ? 0 : halfWidth + widget.spacing, smallZoneTop);
      if (i % 2 != 0) smallZoneTop += h + widget.spacing;

      bool isDragging = _activeSmallIdx == i;

      if (isDragging) {
        activeFloatingCard = _buildFloatingWrapper(
            item: item,
            left: _dragPosition.dx,
            top: _dragPosition.dy,
            w: halfWidth,
            h: h);
      }

      normalLayerChildren.add(
        AnimatedPositioned(
          key: ValueKey('z_small_${item.id}'),
          duration:
              isDragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: slotOffset.dx,
          top: slotOffset.dy,
          width: halfWidth,
          height: h,
          child: Opacity(
            opacity: isDragging ? 0.0 : 1.0,
            child: GestureDetector(
              onLongPressStart: (d) => setState(() {
                HapticFeedback.mediumImpact();
                _activeSmallIdx = i;
                _activeLargeIdx = null;
                _dragPosition = slotOffset;
                _touchPointerOffset = d.localPosition;
              }),
              onLongPressMoveUpdate: (d) {
                if (_activeSmallIdx == null) return;
                RenderBox box = context.findRenderObject() as RenderBox;
                setState(() => _dragPosition =
                    box.globalToLocal(d.globalPosition) - _touchPointerOffset);

                Offset center = _dragPosition + Offset(halfWidth / 2, h / 2);
                double checkTop = 0;
                for (int t = 0; t < widget.smallItems.length; t++) {
                  Offset targetSlot = Offset(
                      (t % 2 == 0) ? 0 : halfWidth + widget.spacing, checkTop);
                  if (t % 2 != 0) checkTop += 125 + widget.spacing;

                  if (t != _activeSmallIdx &&
                      center.dx >= targetSlot.dx &&
                      center.dx <= targetSlot.dx + halfWidth &&
                      center.dy >= targetSlot.dy &&
                      center.dy <= targetSlot.dy + 125) {
                    widget.onSmallReorder(_activeSmallIdx!, t);
                    _activeSmallIdx = t;
                    break;
                  }
                }
              },
              onLongPressEnd: (_) => setState(() => _activeSmallIdx = null),
              child: SizedBox.expand(child: item.child),
            ),
          ),
        ),
      );
    }
    if (widget.smallItems.isNotEmpty && widget.smallItems.length % 2 != 0) {
      smallZoneTop += 125 + widget.spacing;
    }

    double largeZoneTop =
        smallZoneTop + (widget.smallItems.isNotEmpty ? 15 : 0);
    for (int i = 0; i < widget.largeItems.length; i++) {
      final item = widget.largeItems[i];
      double h = (item.id == 6) ? 185 : 95;
      Offset slotOffset = Offset(0, largeZoneTop);

      bool isDragging = _activeLargeIdx == i;

      if (isDragging) {
        activeFloatingCard = _buildFloatingWrapper(
            item: item,
            left: _dragPosition.dx,
            top: _dragPosition.dy,
            w: totalWidth,
            h: h);
      }

      normalLayerChildren.add(
        AnimatedPositioned(
          key: ValueKey('z_large_${item.id}'),
          duration:
              isDragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: slotOffset.dx,
          top: slotOffset.dy,
          width: totalWidth,
          height: h,
          child: Opacity(
            opacity: isDragging ? 0.0 : 1.0,
            child: GestureDetector(
              onLongPressStart: (d) => setState(() {
                HapticFeedback.mediumImpact();
                _activeLargeIdx = i;
                _activeSmallIdx = null;
                _dragPosition = slotOffset;
                _touchPointerOffset = d.localPosition;
              }),
              onLongPressMoveUpdate: (d) {
                if (_activeLargeIdx == null) return;
                RenderBox box = context.findRenderObject() as RenderBox;
                setState(() => _dragPosition =
                    box.globalToLocal(d.globalPosition) - _touchPointerOffset);

                Offset center = _dragPosition + Offset(totalWidth / 2, h / 2);
                double checkTop =
                    smallZoneTop + (widget.smallItems.isNotEmpty ? 15 : 0);
                for (int t = 0; t < widget.largeItems.length; t++) {
                  double th = (widget.largeItems[t].id == 6) ? 185 : 95;
                  if (t != _activeLargeIdx &&
                      center.dy >= checkTop &&
                      center.dy <= checkTop + th) {
                    widget.onLargeReorder(_activeLargeIdx!, t);
                    _activeLargeIdx = t;
                    break;
                  }
                  checkTop += th + widget.spacing;
                }
              },
              onLongPressEnd: (_) => setState(() => _activeLargeIdx = null),
              child: SizedBox.expand(child: item.child),
            ),
          ),
        ),
      );
      largeZoneTop += h + widget.spacing;
    }

    return SizedBox(
      width: totalWidth,
      height: largeZoneTop - widget.spacing,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...normalLayerChildren,
          if (activeFloatingCard != null) activeFloatingCard
        ],
      ),
    );
  }

  Widget _buildFloatingWrapper(
      {required GridItemData item,
      required double left,
      required double top,
      required double w,
      required double h}) {
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1.05,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 14))
              ],
            ),
            child: Opacity(
                opacity: 0.95, child: SizedBox.expand(child: item.child)),
          ),
        ),
      ),
    );
  }
}
