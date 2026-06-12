import paho.mqtt.client as mqtt
import mysql.connector
import json
from datetime import datetime, timedelta

# 1. ตั้งค่าการเชื่อมต่อฐานข้อมูล
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'smart_farm_db' 
}

# ตัวแปร Dictionary สำหรับจำเวลาบันทึกล่าสุดแยกตาม Serial Number ของบอร์ด
last_saved_time = {}

MQTT_BROKER = "172.20.10.4" 
# โครงสร้าง Topic จากบอร์ด ESP32: user/[token]/farm/[serial_number]/status
MQTT_TOPIC = "user/+/farm/+/status" 

def save_to_database(user_token, serial_number, data, timestamp):
    """ฟังก์ชันตรวจสอบสิทธิ์ผ่านข้อมูลตารางจริง และบันทึกข้อมูลลงตาราง sensor_logs"""
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        
        # 🔒 แก้ไข SQL ตรวจสอบสิทธิ์ให้สัมพันธ์ตามฐานข้อมูลจริงของคุณ (เชื่อมตารางด้วย INNER JOIN)
        check_sql = """
            SELECT uf.serial_number 
            FROM user_farms uf
            INNER JOIN users u ON uf.user_id = u.id
            WHERE u.token_id = %s AND uf.serial_number = %s
        """
        cursor.execute(check_sql, (user_token, serial_number))
        exists = cursor.fetchone()
        
        if not exists:
            print(f"⚠️ [ปฏิเสธการเข้าถึง] ผู้ใช้ Token: {user_token} ไม่มีสิทธิ์ควบคุมบอร์ด {serial_number} (ข้ามการบันทึก)")
            cursor.close()
            conn.close()
            return

        # ดึงค่าเซนเซอร์ออกมาเตรียมใช้งาน
        temp = data.get('temp')
        humi = data.get('humi')
        soil = data.get('soil_moisture')
        light = 1 if data.get('light') is True or data.get('light') == 1 else 0
        pump = 1 if data.get('pump') is True or data.get('pump') == 1 else 0
        formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S')

        # บันทึกข้อมูลลงตารางประวัติเซนเซอร์ (sensor_logs)
        insert_sql = """
            INSERT INTO sensor_logs (serial_number, temp, humi, soil_moisture, light_status, pump_status, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        
        val = (serial_number, temp, humi, soil, light, pump, formatted_time)
        cursor.execute(insert_sql, val)
        conn.commit()
        
        # 🟢 Log แสดงรายละเอียดเมื่อผ่านการตรวจสอบและบันทึกเรียบร้อย
        print(f"💾 [บันทึกสำเร็จ] Token ผู้ใช้: {user_token} | บอร์ดซีเรียล: {serial_number} | เวลา: {formatted_time}")
        print(f"   └─ ค่าที่บันทึก -> อุณหภูมิ: {temp}°C, ความชื้นอากาศ: {humi}%, ความชื้นดิน: {soil}%, ไฟ: {light}, ปั๊ม: {pump}")
        print("-" * 80)
        
        cursor.close()
        conn.close()
    except mysql.connector.Error as err:
        print(f"❌ [Database Error] {err}")

def on_connect(client, userdata, flags, rc):
    print(f"📡 เชื่อมต่อกับ MQTT Broker ({MQTT_BROKER}) เรียบร้อยแล้ว")
    client.subscribe(MQTT_TOPIC)

def on_message(client, userdata, msg):
    global last_saved_time
    
    try:
        # แกะข้อมูลจาก Topic ตัวอย่าง: user/11345/farm/SN-FSH64G4/status
        topic_parts = msg.topic.split('/')
        user_token = topic_parts[1]     # แกะได้ Token_id เช่น "11345"
        serial_number = topic_parts[3]  # แกะได้ ซีเรียล เช่น "SN-FSH64G4"
        
        payload = json.loads(msg.payload.decode('utf-8'))
        current_time = datetime.now()
        
        # ⏱️ ตรวจสอบเงื่อนไขการบันทึกข้อมูลทุก ๆ 1 นาทีแยกตามซีเรียลนัมเบอร์
        if serial_number in last_saved_time:
            time_difference = current_time - last_saved_time[serial_number]
            
            if time_difference < timedelta(minutes=1):
                return
        
        # อัปเดตสแตมป์เวลาปัจจุบัน และเรียกคำสั่งตรวจสอบพร้อมบันทึก
        last_saved_time[serial_number] = current_time
        save_to_database(user_token, serial_number, payload, current_time)

    except Exception as e:
        print(f"❌ [Error Processing Message] {e}")

# เริ่มระบบ MQTT Client
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

print(f"🚀 MQTT Bridge เริ่มทำงาน (ระบบแมปตารางสัมพันธ์ร่วมและจำกัดการบันทึกทุกๆ 1 นาที...)")
client.connect(MQTT_BROKER, 1883, 60)
client.loop_forever()