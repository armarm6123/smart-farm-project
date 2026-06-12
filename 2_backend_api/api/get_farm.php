<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'db_config.php';

$user_id = $_GET['user_id'] ?? 0;

// 💡 แก้ไข: เพิ่ม ORDER BY created_at ASC ต่อท้ายคำสั่ง เพื่อให้ฟาร์มใหม่ไปต่อท้ายสุด (อยู่ข้างหลัง)
$sql = "SELECT farm_name, serial_number FROM user_farms WHERE user_id = ? ORDER BY created_at ASC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$farms = [];
while ($row = $result->fetch_assoc()) {
    $farms[] = $row;
}

echo json_encode($farms);
$stmt->close(); // ปิด statement เพื่อคืนค่าหน่วยความจำ
$conn->close();
?>