<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'db_config.php';

// เปลี่ยนจากรับ id มาเป็นรับ serial_number (sn)
$serial_number = $_POST['serial_number'] ?? $_POST['sn'] ?? '';

if (empty($serial_number)) {
    die(json_encode(["status" => "error", "message" => "Missing Serial Number"]));
}

// เปลี่ยน WHERE id = ? เป็น WHERE serial_number = ?
$sql = "DELETE FROM user_farms WHERE serial_number = ?";
$stmt = $conn->prepare($sql);
// เปลี่ยนจาก "i" (Integer) เป็น "s" (String) เพราะ Serial Number เป็นข้อความ
$stmt->bind_param("s", $serial_number);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}

$stmt->close();
$conn->close();
?>