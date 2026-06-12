<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET"); // เปิดให้รองรับทั้ง POST และ GET เพื่อให้ทดสอบง่าย

// 1. เชื่อมต่อฐานข้อมูล (ใช้ MySQLi config ของระบบคุณ)
require_once 'db_config.php'; 

// 2. ดักรับค่ายืดหยุ่นสูง: อ่านได้ทั้งจาก $_POST, $_GET หรือ JSON raw body
$input = json_decode(file_get_contents('php://input'), true);
$user_id = $_POST['user_id'] ?? $_GET['user_id'] ?? $_REQUEST['id'] ?? $input['user_id'] ?? $input['id'] ?? 0;

// แปลงค่าให้เป็นตัวเลขจำนวนเต็มเพื่อความปลอดภัย
$user_id = intval($user_id);

if ($user_id <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "ข้อมูล User ID ไม่ถูกต้อง หรือไม่ได้ส่งมา"
    ]);
    exit;
}

try {
    // 3. เริ่ม Transaction ด้วยไวยากรณ์ MySQLi เพื่อความปลอดภัยของข้อมูล
    $conn->begin_transaction();

    // ขั้นตอนที่ 3.1: ลบ Logs เซนเซอร์ที่ผูกกับฟาร์มของ User นี้ก่อน (ป้องกัน Error ข้อมูลกำพร้า)
    $sql_logs = "DELETE FROM sensor_logs WHERE serial_number IN (SELECT serial_number FROM user_farms WHERE user_id = ?)";
    $stmt_logs = $conn->prepare($sql_logs);
    if ($stmt_logs) {
        $stmt_logs->bind_param("i", $user_id);
        $stmt_logs->execute();
    }

    // ขั้นตอนที่ 3.2: ลบข้อมูลความสัมพันธ์ของฟาร์ม (ตาราง user_farms)
    $sql_farms = "DELETE FROM user_farms WHERE user_id = ?";
    $stmt_farms = $conn->prepare($sql_farms);
    if ($stmt_farms) {
        $stmt_farms->bind_param("i", $user_id);
        $stmt_farms->execute();
    }

    // ขั้นตอนที่ 3.3: ลบข้อมูลบัญชีหลักของผู้ใช้งาน (ตาราง users)
    $sql_user = "DELETE FROM users WHERE id = ?";
    $stmt_user = $conn->prepare($sql_user);
    if ($stmt_user) {
        $stmt_user->bind_param("i", $user_id);
        $stmt_user->execute();
        
        // ตรวจสอบผลลัพธ์ว่ามี User ถูกลบออกไปจริงไหม
        if ($stmt_user->affected_rows > 0) {
            // 4. บันทึกคำสั่งลบทั้งหมดลงฐานข้อมูลอย่างถาวรเมื่อทำงานผ่านฉลุยทุกตาราง
            $conn->commit();
            echo json_encode([
                "status" => "success",
                "message" => "ลบบัญชีและข้อมูลที่เกี่ยวข้องทั้งหมดเรียบร้อยแล้วถาวร"
            ]);
        } else {
            throw new Exception("ไม่พบข้อมูลผู้ใช้งานในระบบ หรือบัญชีนี้ไม่มีอยู่แล้ว");
        }
    } else {
        throw new Exception("เกิดข้อผิดพลาดในโครงสร้างคำสั่ง SQL ของระบบ");
    }

} catch (Exception $e) {
    // หากขั้นตอนใดค้างหรือพัง ให้คืนค่าฐานข้อมูลกลับมาทันที (Rollback)
    $conn->rollback();
    echo json_encode([
        "status" => "error",
        "message" => "ล้มเหลวในการลบข้อมูล: " . $e->getMessage()
    ]);
}

// ปิดการเชื่อมต่อฐานข้อมูล
$conn->close();
?>