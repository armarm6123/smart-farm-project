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

if (empty($serial_number)) {
    echo json_encode(["status" => "error", "message" => "ไม่พบ Serial Number ของอุปกรณ์ (ต้องการ serial_number)"]);
    exit;
}

// 💡 แก้ไข: ลบโดยใช้เงื่อนไข serial_number แทน id เดิม
$stmt = $conn->prepare("DELETE FROM user_farms WHERE serial_number = ?");
$stmt->bind_param("s", $serial_number); // 💡 เปลี่ยนจาก "i" เป็น "s" เนื่องจากเป็นข้อความ

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "ไม่พบข้อมูลฟาร์มที่ต้องการลบ"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}

$stmt->close();
$conn->close();
?>