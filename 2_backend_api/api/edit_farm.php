<?php
header("Content-Type: application/json");
require_once 'db_config.php';

// เปลี่ยนจากรับ id มาเป็นรับ serial_number (sn)
$serial_number = $_POST['serial_number'] ?? $_POST['sn'] ?? '';
$farm_name = $_POST['farm_name'] ?? '';

if (empty($serial_number) || empty($farm_name)) {
    echo json_encode(["status" => "error", "message" => "ข้อมูลไม่ครบถ้วน"]);
    exit;
}

// เปลี่ยน WHERE id = ? เป็น WHERE serial_number = ?
$sql = "UPDATE user_farms SET farm_name = ? WHERE serial_number = ?";
$stmt = $conn->prepare($sql);
// เปลี่ยนจาก "si" (String, Integer) เป็น "ss" (String, String)
$stmt->bind_param("ss", $farm_name, $serial_number);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}
?>