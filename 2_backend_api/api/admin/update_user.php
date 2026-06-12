<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

require_once '../db_config.php';

$input = json_decode(file_get_contents('php://input'), true);
$id = $_POST['id'] ?? $input['id'] ?? '';
$username = $_POST['username'] ?? $input['username'] ?? '';
$password = $_POST['password'] ?? $input['password'] ?? '';

if (!empty($id) && !empty($username)) {
    
    // ตรวจสอบก่อนว่าเปลี่ยนชื่อไปซ้ำกับคนอื่นหรือไม่
    $check = $conn->prepare("SELECT id FROM users WHERE username = ? AND id != ?");
    $check->bind_param("si", $username, $id);
    $check->execute();
    if ($check->get_result()->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "ชื่อผู้ใช้นี้ถูกใช้ไปแล้ว"]);
        exit();
    }

    if (!empty($password)) {
        // แนะนำ: ในอนาคตควรใช้ password_hash แทนข้อความธรรมดาเพื่อความปลอดภัย
        $sql = "UPDATE users SET username = ?, password = ? WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssi", $username, $password, $id);
    } else {
        $sql = "UPDATE users SET username = ? WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("si", $username, $id);
    }

    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "อัปเดตข้อมูลสำเร็จ"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Error: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "ข้อมูลไม่ครบถ้วน"]);
}
$conn->close();