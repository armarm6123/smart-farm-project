<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'db_config.php';

// รับค่าจากแอป
$sn = $_GET['serial_number'] ?? '';
$start = $_GET['start'] ?? date('Y-m-d');
$end = $_GET['end'] ?? date('Y-m-d');

if (empty($sn)) {
    echo json_encode(["status" => "error", "message" => "Serial Number is required"]);
    exit;
}

// คำนวณส่วนต่างของวันที่เลือก
$date1 = new DateTime($start);
$date2 = new DateTime($end);
$daysDiff = $date1->diff($date2)->days;

if ($daysDiff == 0) {
    // --- กรณีเลือกวันเดียวกัน: แสดงข้อมูลดิบทุกรายการ (Raw Logs) ---
    $sql = "SELECT 
                temp, 
                humi, 
                soil_moisture as soil, 
                pump_status as pump, 
                light_status as light, -- 1. เพิ่มสถานะไฟ
                created_at as d_time 
            FROM sensor_logs 
            WHERE serial_number = ? AND DATE(created_at) BETWEEN ? AND ? 
            ORDER BY d_time ASC";
    
    $timeFormat = "H:i:s"; // แสดงเป็น ชั่วโมง:นาที:วินาที
} else {
    // --- กรณีเลือกหลายวัน: แสดงเป็นค่าเฉลี่ยรายวัน (Daily Average) ---
    $sql = "SELECT 
                AVG(temp) as temp, 
                AVG(humi) as humi, 
                AVG(soil_moisture) as soil, 
                MAX(pump_status) as pump, 
                MAX(light_status) as light, -- 2. เพิ่มสถานะไฟ (ใช้ MAX เพื่อดูว่าวันนั้นมีการเปิดไฟไหม)
                created_at as d_time 
            FROM sensor_logs 
            WHERE serial_number = ? AND DATE(created_at) BETWEEN ? AND ? 
            GROUP BY DATE(created_at) 
            ORDER BY d_time ASC";
    
    $timeFormat = "d M"; // แสดงเป็น วันที่ เดือน เช่น 17 May
}

$stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $sn, $start, $end);
$stmt->execute();
$result = $stmt->get_result();

$logs = [];
while ($row = $result->fetch_assoc()) {
    $logs[] = [
        "temp" => round((float)$row['temp'], 1),
        "humi" => round((float)$row['humi'], 1),
        "soil" => round((float)$row['soil'], 1),
        "pump" => (int)$row['pump'],
        "light" => (int)$row['light'], // 3. ส่งค่าสถานะไฟกลับไปใน JSON
        "time" => date($timeFormat, strtotime($row['d_time']))
    ];
}

echo json_encode($logs);

$stmt->close();
$conn->close();
?>