<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../db_config.php';

// นับจำนวนผู้ใช้ทั้งหมด (ยกเว้น admin)
$userCount = $conn->query("SELECT COUNT(*) as total FROM users WHERE role != 'admin'")->fetch_assoc()['total'] ?? 0;

// นับจำนวนฟาร์มทั้งหมดที่ถูกสร้าง
$farmCount = $conn->query("SELECT COUNT(*) as total FROM user_farms")->fetch_assoc()['total'] ?? 0;

// นับจำนวน Serial Number ที่ถูกเปิดใช้งาน
$snCount = $conn->query("SELECT COUNT(DISTINCT serial_number) as total FROM user_farms")->fetch_assoc()['total'] ?? 0;

echo json_encode([
    "status" => "success",
    "total_users" => intval($userCount),
    "total_farms" => intval($farmCount),
    "active_sn" => intval($snCount)
]);

$conn->close();
?>