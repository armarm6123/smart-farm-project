<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// 1. เชื่อมต่อไฟล์ Config
require_once '../db_config.php'; 

// 2. รับค่าจาก Flutter
$serial_number = $_GET['serial_number'] ?? '';

if (empty($serial_number)) {
    echo json_encode(["status" => "error", "message" => "ไม่ได้ระบุ SN"]);
    exit();
}

// 3. SQL Query 
// 💡 ตรวจสอบแล้ว: การจัดเรียงใช้ ORDER BY created_at DESC ทำงานได้สมบูรณ์และถูกต้อง แม้ไม่มีคอลัมน์ id
$sql = "SELECT temp, humi, soil_moisture, light_status, pump_status, created_at 
        FROM sensor_logs 
        WHERE serial_number = ? 
        ORDER BY created_at DESC 
        LIMIT 20";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(["status" => "error", "message" => "SQL Error: " . $conn->error]);
    exit();
}

$stmt->bind_param("s", $serial_number);
$stmt->execute();
$result = $stmt->get_result();

$logs = [];
while($row = $result->fetch_assoc()) {
    $logs[] = [
        "temperature"   => $row['temp'] !== null ? floatval($row['temp']) : 0.0,
        "humidity"      => $row['humi'] !== null ? floatval($row['humi']) : 0.0,
        "soil_moisture" => $row['soil_moisture'] !== null ? floatval($row['soil_moisture']) : 0.0,
        "light"         => $row['light_status'] !== null ? intval($row['light_status']) : 0, 
        "pump"          => $row['pump_status'] !== null ? intval($row['pump_status']) : 0,   
        "recorded_at"   => $row['created_at'] 
    ];
}

// 4. ส่งข้อมูลกลับ
echo json_encode([
    "status" => "success",
    "logs" => $logs
]);

// 💡 ปรับปรุง: ตรวจสอบตำแหน่งการปิด Statement และ Connection ให้อยู่ท้ายสุดหลังจากพ่นข้อมูลเรียบร้อยแล้วเพื่อความปลอดภัย
$stmt->close();
$conn->close();
?>