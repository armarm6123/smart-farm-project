/*
 * =================================================================
 * SMART FARM ESP32 - COMPLETE VERSION (SDA:21, SCL:22)
 * =================================================================
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// --- ตั้งค่าอุปกรณ์ ---
const char* userToken = "11345"; 
const char* serialNumber = "SN-FSH64G4";
const char* ssid = "iPhone";
const char* password = "12345678";
const char* mqtt_server = "172.20.10.4"; 

#define DHTPIN 32
#define DHTTYPE DHT22
#define SOIL_PIN 33
#define RELAY_LIGHT 18    
#define RELAY_PUMP 19     

Adafruit_SSD1306 display(128, 64, &Wire, -1);
DHT dht(DHTPIN, DHTTYPE);
WiFiClient espClient;
PubSubClient client(espClient);

// --- ตัวแปร ---
bool autoMode = false;
int soilLow = -1;
int soilHigh = -1;
unsigned long lastSend = 0;
unsigned long lastWifiAttempt = 0;

String baseTopic = "user/" + String(userToken) + "/farm/" + String(serialNumber);
String statusTopic = baseTopic + "/status";
String controlTopic = baseTopic + "/control";

void updateOLED(float t, float h, float s) {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1); // ใช้ขนาด 1 ทั้งหน้าจอ มั่นใจได้ว่าไม่ล้นจอ

  // === 1. แถวบนสุด: การเชื่อมต่อระบบ (มุมบนสุด) ===
  display.setCursor(0, 0);
  display.printf("SN:%s", serialNumber);
  
  // เช็กสถานะ WiFi (แสดงมุมบนขวา)
  display.setCursor(85, 0);
  if (WiFi.status() == WL_CONNECTED) {
    display.print("WiFi:OK");
  } else if (WiFi.status() == WL_DISCONNECTED || WiFi.status() == WL_IDLE_STATUS) {
    display.print("WF:CONN"); // กำลังเชื่อมต่อ
  } else {
    display.print("WF:FAIL"); // เชื่อมต่อไม่ได้/หลุด
  }
  
  // เส้นคั่นส่วนหัว
  display.drawFastHLine(0, 10, 128, SSD1306_WHITE);

  // === 2. โซนกลาง: มัดรวมค่าเซนเซอร์ไว้ด้วยกัน (อ่านง่ายในจุดเดียว) ===
  display.setCursor(10, 16);
  display.printf("TEMP  : %.1f C", t);    // อุณหภูมิอากาศ
  
  display.setCursor(10, 27);
  display.printf("HUMI  : %.0f %%", h);    // ความชื้นอากาศ
  
  display.setCursor(10, 38);
  display.printf("SOIL  : %.0f %%", s);    // ความชื้นในดิน

  // เส้นคั่นก่อนเข้าสู่โซนควบคุม
  display.drawFastHLine(0, 49, 128, SSD1306_WHITE);

  // === 3. แถวล่างสุด: โหมดการทำงาน และ การควบคุมอุปกรณ์ ===
  // ตัดเงื่อนไข WAIT ออกแล้ว -> ถ้า true เป็น [AUTO] ถ้า false เป็น [MANU] ทันที
  display.setCursor(0, 56);
  display.printf("[%s]", autoMode ? "AUTO" : "MANU");

  // แสดงสถานะ ไฟ และ ปั๊มน้ำ (ขยับปั๊มมาที่พิกัด 80 ตามสัดส่วนเดิมของคุณ)
  display.setCursor(42, 56);
  display.printf("L:%s", digitalRead(RELAY_LIGHT) == LOW ? "ON" : "OFF");
  
  display.setCursor(80, 56);
  display.printf("PUMP:%s", digitalRead(RELAY_PUMP) == LOW ? "ON" : "OFF");

  display.display();
}

void callback(char* topic, byte* payload, unsigned int length) {
  StaticJsonDocument<256> doc;
  deserializeJson(doc, payload, length);

  if (doc.containsKey("light")) digitalWrite(RELAY_LIGHT, doc["light"] == 1 ? LOW : HIGH);
  
  if (doc.containsKey("pump")) {
    autoMode = false; 
    digitalWrite(RELAY_PUMP, doc["pump"] == 1 ? LOW : HIGH);
  }
  
  if (doc.containsKey("auto_mode")) {
    autoMode = doc["auto_mode"];
    if (doc.containsKey("soil_low")) soilLow = doc["soil_low"];
    if (doc.containsKey("soil_high")) soilHigh = doc["soil_high"];
  }
}

void setup() {
  Serial.begin(115200);
  
  // กำหนดขา I2C สำหรับ OLED
  Wire.begin(21, 22); 
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) Serial.println("OLED failed");
  
  dht.begin();
  pinMode(RELAY_LIGHT, OUTPUT); 
  pinMode(RELAY_PUMP, OUTPUT);
  digitalWrite(RELAY_LIGHT, HIGH); 
  digitalWrite(RELAY_PUMP, HIGH); 
  
  WiFi.begin(ssid, password);
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  // WiFi management
  if (WiFi.status() != WL_CONNECTED) {
    if (millis() - lastWifiAttempt > 5000) {
      WiFi.begin(ssid, password);
      lastWifiAttempt = millis();
    }
  }

  // MQTT management
  if (WiFi.status() == WL_CONNECTED && !client.connected()) {
    if (client.connect(serialNumber)) client.subscribe(controlTopic.c_str());
  }
  client.loop();

  // Task execution
  if (millis() - lastSend > 3000) {
    lastSend = millis();

    float h = dht.readHumidity();
    float t = dht.readTemperature();
    int rawSoil = analogRead(SOIL_PIN);
    float s = constrain(map(rawSoil, 3500, 1500, 0, 100), 0, 100);

    if (autoMode && soilLow != -1 && soilHigh != -1) {
      if (s < soilLow) digitalWrite(RELAY_PUMP, LOW);
      else if (s >= soilHigh) digitalWrite(RELAY_PUMP, HIGH);
    }

    updateOLED(t, h, s);
    
    if (client.connected()) {
      StaticJsonDocument<256> outDoc;
      outDoc["temp"] = t;
      outDoc["humi"] = h;
      outDoc["soil_moisture"] = s;
      outDoc["pump"] = (digitalRead(RELAY_PUMP) == LOW);
      outDoc["light"] = (digitalRead(RELAY_LIGHT) == LOW);
      outDoc["auto_mode"] = autoMode;
      outDoc["soil_low"] = soilLow;
      outDoc["soil_high"] = soilHigh;
      
      char buffer[256];
      serializeJson(outDoc, buffer);
      client.publish(statusTopic.c_str(), buffer);
    }
  }
}