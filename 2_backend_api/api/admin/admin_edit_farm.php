<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once dirname(__DIR__) . '/db_config.php';

$raw_input = file_get_contents("php://input");
$json_input = json_decode($raw_input, true);

// 💡 แก้ไข: เปลี่ยนมารับค่า serial_number แทน farm_id แบบเก่า
$serial_number = $json_input['serial_number'] ?? $_POST['serial_number'] ?? '';
$farm_name = $json_input['farm_name'] ?? $_POST['farm_name'] ?? '';

if (empty($serial_number) || empty($farm_name)) {
    echo json_encode(["status" => "error", "message" => "ข้อมูลไม่ครบถ้วน (ต้องการ serial_number, farm_name)"]);
    exit;
}

// 💡 แก้ไข: ทำการ UPDATE ข้อมูลโดยใช้เงื่อนไขคีย์หลักตัวใหม่คือ serial_number
$stmt = $conn->prepare("UPDATE user_farms SET farm_name = ? WHERE serial_number = ?");
$stmt->bind_param("ss", $farm_name, $serial_number); // 💡 ปรับเป็น "ss" (String ทั้งคู่)

if ($stmt->execute()) {
    // แนะนำเพิ่มเติม: ตรวจสอบ affected_rows เพื่อความมั่นใจว่ามีการอัปเดตเกิดขึ้นจริง
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}

$stmt->close();
$conn->close();
?>