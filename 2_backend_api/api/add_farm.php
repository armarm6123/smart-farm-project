<?php
header("Content-Type: application/json");
require_once 'db_config.php';

$user_id = $_POST['user_id'] ?? '';
$farm_name = $_POST['farm_name'] ?? '';
$serial_number = $_POST['serial_number'] ?? '';

// --- 💡 แก้ไข: เปลี่ยน SELECT id เป็น SELECT serial_number เพราะในตารางไม่มีคอลัมน์ id แล้ว ---
$check = $conn->prepare("SELECT serial_number FROM user_farms WHERE serial_number = ?");
$check->bind_param("s", $serial_number);
$check->execute();
$result = $check->get_result();

if ($result->num_rows > 0) {
    // ถ้าเจอว่าเลขนี้มีคนใช้แล้ว ให้หยุดการทำงานและบอก Flutter ว่า "ซ้ำ"
    echo json_encode(["status" => "error", "message" => "Serial Number ซ้ำ! กรุณาสุ่มใหม่"]);
    exit;
}
// -----------------------------------

$sql = "INSERT INTO user_farms (user_id, farm_name, serial_number) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("iss", $user_id, $farm_name, $serial_number);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}

$stmt->close();
$conn->close();
?>