import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTManager extends ChangeNotifier {
  final String host = "172.20.10.4";
  MqttServerClient? _client;

  String? currentMonitorTopic;
  String? currentControlTopic;

  // --- Data Variables ---
  double temp = 0.0;
  double humi = 0.0;
  double soil = 0.0;

  // 🟢 แยกสถานะจริงที่บอร์ดรายงาน (ใช้สำหรับแสดงผลที่หน้าจอ)
  bool actualPumpStatus = false;
  bool actualLightStatus = false;

  double soilLow = 0.0;
  double soilHigh = 0.0;

  // --- Status Variables ---
  bool isAutoMode = false;
  bool isConnected = false;

  void connect(String serialNumber, String userToken) async {
    currentMonitorTopic = "user/$userToken/farm/$serialNumber/status";
    currentControlTopic = "user/$userToken/farm/$serialNumber/control";

    final String clientId =
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(host, clientId);
    _client!.port = 1883;
    _client!.keepAlivePeriod = 20;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .authenticateAs(userToken, userToken)
        .withClientIdentifier(clientId)
        .startClean();
    _client!.connectionMessage = connMess;

    _client!.onConnected = () {
      isConnected = true;
      _client!.subscribe(currentMonitorTopic!, MqttQos.atLeastOnce);
      notifyListeners();
    };

    _client!.onDisconnected = () {
      isConnected = false;
      notifyListeners();
    };

    try {
      await _client!.connect();
    } catch (e) {
      debugPrint("MQTT Connection Error: $e");
      _client!.disconnect();
    }

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final data = jsonDecode(pt);
        temp = (data['temp'] as num?)?.toDouble() ?? temp;
        humi = (data['humi'] as num?)?.toDouble() ?? humi;
        soil = (data['soil_moisture'] as num?)?.toDouble() ?? soil;

        // รับสถานะการทำงานจริงจากบอร์ด ESP32
        actualPumpStatus = (data['pump'] == true || data['pump'] == 1);
        actualLightStatus = (data['light'] == true || data['light'] == 1);

        if (data['auto_mode'] != null) {
          isAutoMode = (data['auto_mode'] == true || data['auto_mode'] == 1);
        }

        if (data['soil_low'] != null)
          soilLow = (data['soil_low'] as num).toDouble();
        if (data['soil_high'] != null)
          soilHigh = (data['soil_high'] as num).toDouble();

        notifyListeners();
      } catch (e) {
        debugPrint("Parse Error: $e");
      }
    });
  }

  // ฟังก์ชันสวิตช์เปิด-ปิดปั๊มน้ำด้วยตนเอง (Manual)
  void togglePump(bool status) {
    if (!isConnected || currentControlTopic == null) return;

    // เมื่อกดสั่งเองด้วยมือ โหมด Auto จะถูกยกเลิกโดยอัตโนมัติ
    final payload = jsonEncode({"pump": status ? 1 : 0, "auto_mode": false});
    _publish(payload);

    isAutoMode = false;
    actualPumpStatus = status;
    notifyListeners();
  }

  // ฟังก์ชันสวิตช์เปิด-ปิดหลอดไฟด้วยตนเอง
  void toggleLight(bool status) {
    if (!isConnected || currentControlTopic == null) return;
    final payload = jsonEncode({"light": status ? 1 : 0});
    _publish(payload);

    actualLightStatus = status;
    notifyListeners();
  }

  // ฟังก์ชันตั้งค่าและควบคุมโหมดอัตโนมัติ (Auto)
  void sendAutoSettings(bool isAuto, double low, double high) {
    if (!isConnected || currentControlTopic == null) return;

    isAutoMode = isAuto;
    soilLow = low;
    soilHigh = high;

    // 🟢 ปรับ Logic ใหม่: ถ้าผู้ใช้สับสวิตช์ "ปิดออโต้" (isAuto == false)
    // ตัวแอปจะสั่งบังคับให้ปั๊มน้ำในแอปเปลี่ยนเป็น false ทันที เพื่อให้สอดคล้องกับคำสั่งที่จะส่งไปบอร์ด
    if (!isAuto) {
      actualPumpStatus = false;
    }

    final payload = jsonEncode({
      "auto_mode": isAuto,
      "soil_low": low.toInt(),
      "soil_high": high.toInt(),
      // 🟢 ส่งคีย์ pump ไปด้วย: ถ้าปิดออโต้ (isAuto เป็น false) จะส่งเลข 0 ไปบอกบอร์ดให้ตัดการทำงานปั๊มทันที!
      "pump": isAuto ? (actualPumpStatus ? 1 : 0) : 0,
    });

    _publish(payload);
    notifyListeners();
  }

  void _publish(String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client?.publishMessage(
        currentControlTopic!, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _client?.disconnect();
    isConnected = false;
    notifyListeners();
  }
}
