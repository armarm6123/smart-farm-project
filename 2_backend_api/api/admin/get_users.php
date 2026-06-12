<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../db_config.php'; 

$sql = "SELECT id, username, password, role, token_id FROM users WHERE role != 'admin' ORDER BY id DESC";
$result = $conn->query($sql);
$users = [];

if ($result) {
    while($row = $result->fetch_assoc()) {
        $users[] = [
            "id" => intval($row['id']),
            "username" => $row['username'],
            "password" => $row['password'],
            "role" => $row['role'],
            "token_id" => $row['token_id'] // เพิ่มบรรทัดนี้เข้ามา
        ];
    }
    echo json_encode([
        "status" => "success",
        "users" => $users
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "ไม่สามารถดึงข้อมูลได้: " . $conn->error]);
}

$conn->close();
?>