<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../db_config.php';

$input = json_decode(file_get_contents('php://input'), true);

$username = $_POST['username'] ?? $input['username'] ?? '';
$password = $_POST['password'] ?? $input['password'] ?? '';
$role = $_POST['role'] ?? $input['role'] ?? 'user';

if (empty($username) || empty($password)) {
    echo json_encode(["status" => "error", "message" => "ข้อมูลไม่ครบถ้วน"]);
    exit;
}

// 1. ตรวจสอบชื่อผู้ใช้ซ้ำ
$check_sql = "SELECT id FROM users WHERE username = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $username);
$check_stmt->execute();
if ($check_stmt->get_result()->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "ชื่อผู้ใช้นี้มีในระบบแล้ว"]);
    exit;
}

// 🛠️ 2. จัดการ token_id
$token_id = NULL; // ค่าเริ่มต้นเป็น NULL

if ($role === 'user') {
    $is_unique = false;
    while (!$is_unique) {
        $token_id = rand(10000, 99999);
        $token_sql = "SELECT id FROM users WHERE token_id = ?";
        $token_stmt = $conn->prepare($token_sql);
        $token_stmt->bind_param("i", $token_id);
        $token_stmt->execute();
        if ($token_stmt->get_result()->num_rows == 0) {
            $is_unique = true;
        }
        $token_stmt->close();
    }
}

// 🛠️ 3. เพิ่มข้อมูล
// ใช้ "sssi" ถ้า token_id เป็น int หรือ "ssss" ถ้า token_id อาจเป็น null ในบาง database driver
// วิธีที่ปลอดภัยที่สุดคือการเช็กค่าก่อน bind
$sql = "INSERT INTO users (username, password, role, token_id) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

if ($token_id === NULL) {
    $stmt->bind_param("sssi", $username, $password, $role, $token_id); // NULL จะถูกส่งเป็น NULL อัตโนมัติ
} else {
    $stmt->bind_param("sssi", $username, $password, $role, $token_id);
}

if ($stmt->execute()) {
    echo json_encode([
        "status" => "success", 
        "message" => "เพิ่มผู้ใช้งานสำเร็จ",
        "user_id" => $stmt->insert_id,
        "token_id" => $token_id
    ]);
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}

$stmt->close();
$conn->close();
?>