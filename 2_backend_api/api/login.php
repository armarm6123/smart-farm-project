<?php
// เริ่มต้นใช้งาน Session สำหรับฝั่งหน้าเว็บ
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'db_config.php'; 

// รับค่าจาก POST
$user = $_POST['username'] ?? '';
$pass = $_POST['password'] ?? '';

// ดึงข้อมูลตรวจสอบ
$sql = "SELECT id, username, role, token_id FROM users WHERE username = ? AND password = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $user, $pass);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    
    // 💡 สิ่งที่เพิ่มเข้ามา: ฝังข้อมูลลง Session ทันที (สำหรับรองรับหน้าเว็บ user_web.php และ admin_web.php)
    if (($row['role'] ?? 'user') === 'admin') {
        $_SESSION['admin_logged'] = true;
        $_SESSION['admin_id'] = $row['id'];
        $_SESSION['admin_user'] = $row['username'];
    } else {
        $_SESSION['user_logged'] = true;
        $_SESSION['user_id'] = $row['id'];
        $_SESSION['user_user'] = $row['username'];
        $_SESSION['token_id'] = $row['token_id']; // ตัวนี้จะถูกดึงไปใช้ต่อใน MQTT บนหน้าเว็บผู้ใช้
    }

    // 📱 ส่งข้อมูลกลับในรูปแบบ JSON เหมือนเดิมเป๊ะ (แอป Flutter ใช้งานได้ปกติ ไม่พังแน่นอน)
    echo json_encode([
        "status" => "success",
        "user_id" => $row['id'],
        "token_id" => $row['token_id'],
        "name" => $row['username'],
        "role" => $row['role']
    ]);
} else {
    echo json_encode([
        "status" => "error", 
        "message" => "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"
    ]);
}

$stmt->close();
$conn->close();
?>