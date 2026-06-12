<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'db_config.php';

// รับค่าจาก Flutter
$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($username) || empty($password)) {
    echo json_encode(["status" => "error", "message" => "กรุณากรอกข้อมูลให้ครบถ้วน"]);
    exit;
}

// 1. ตรวจสอบก่อนว่าชื่อผู้ใช้นี้มีอยู่แล้วหรือไม่
$check_sql = "SELECT id FROM users WHERE username = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $username);
$check_stmt->execute();
$check_stmt->store_result();

if ($check_stmt->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "ชื่อผู้ใช้นี้ถูกใช้งานแล้ว"]);
    $check_stmt->close();
    $conn->close();
    exit;
}
$check_stmt->close();


// 🛠️ 2. ลอจิกสุ่มและตรวจสอบรหัส token_id 5 หลักไม่ให้ซ้ำกันในระบบ
$token_id = "";
$is_unique = false;

while (!$is_unique) {
    // สุ่มตัวเลขระหว่าง 10000 ถึง 99999 แล้วแปลงเป็น String
    $token_id = (string)rand(10000, 99999);
    
    // ตรวจสอบในฐานข้อมูลว่ามี token_id นี้หรือยัง
    $token_sql = "SELECT id FROM users WHERE token_id = ?";
    $token_stmt = $conn->prepare($token_sql);
    $token_stmt->bind_param("s", $token_id);
    $token_stmt->execute();
    $token_stmt->store_result();
    
    // ถ้าไม่พบข้อมูลซ้ำ แปลว่าเลขนี้ใช้ได้
    if ($token_stmt->num_rows == 0) {
        $is_unique = true;
    }
    $token_stmt->close();
}


// 🛠️ 3. บันทึกข้อมูลใหม่พร้อมรหัส token_id และใส่ role เป็น 'user' อัตโนมัติ
$sql = "INSERT INTO users (username, password, role, token_id) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

$default_role = 'user'; // กำหนดสิทธิ์เริ่มต้น

// เปลี่ยนเป็น "ssss" เพื่อให้เสถียรต่อช่องประเภทข้อมูลใน DB (ไม่ว่าจะเป็น INT หรือ VARCHAR)
$stmt->bind_param("ssss", $username, $password, $default_role, $token_id);

if ($stmt->execute()) {
    // ส่งค่ากลับไปบอก Flutter
    echo json_encode([
        "status" => "success", 
        "message" => "สมัครสมาชิกสำเร็จ",
        "token_id" => $token_id 
    ]);
} else {
    // 🛠️ แก้ไขจุดบกพร่อง: เปลี่ยนมาใช้ $conn->error แทนเพื่อไม่ให้เกิด Error 500
    echo json_encode([
        "status" => "error", 
        "message" => "เกิดข้อผิดพลาดจากระบบฐานข้อมูล: " . $conn->error
    ]);
}

$stmt->close();
$conn->close();
?>