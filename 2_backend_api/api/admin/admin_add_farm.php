<?php
// อนุญาตให้หน้าเว็บและแอปเข้าถึงได้ข้ามโดเมน (CORS)
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ระบุตำแหน่งไฟล์เชื่อมต่อฐานข้อมูลแบบระบุพาธชัดเจน (จากโฟลเดอร์ปัจจุบัน ถอยกลับไป 1 ชั้น)
require_once dirname(__DIR__) . '/db_config.php';

// รองรับทั้ง JSON Payload (จากหน้าเว็บ) และ $_POST Form (จาก Flutter/Web Form)
$raw_input = file_get_contents("php://input");
$json_input = json_decode($raw_input, true);

// 💡 แก้ไขจุดหลัก: ตรวจสอบและดึงค่าอย่างละเอียด ป้องกันค่าว่างหลุดไปทำระบบรวน
$user_id = "";
$farm_name = "";
$serial_number = "";

if (!empty($json_input)) {
    $user_id = $json_input['user_id'] ?? "";
    $farm_name = $json_input['farm_name'] ?? "";
    $serial_number = $json_input['serial_number'] ?? "";
}

// ถ้าใน JSON ไม่มี หรือไม่ได้ส่งแบบ JSON ให้ดึงจาก $_POST ตรงๆ
if (empty($user_id)) $user_id = $_POST['user_id'] ?? "";
if (empty($farm_name)) $farm_name = $_POST['farm_name'] ?? "";
if (empty($serial_number)) $serial_number = $_POST['serial_number'] ?? "";

// ตรวจสอบความครบถ้วนของข้อมูล
if (empty($user_id) || empty($farm_name) || empty($serial_number)) {
    echo json_encode(["status" => "error", "message" => "กรุณากรอกข้อมูลให้ครบถ้วน (UserID: $user_id)"]);
    exit;
}

// ตรวจสอบ Serial Number ซ้ำ
$check = $conn->prepare("SELECT serial_number FROM user_farms WHERE serial_number = ?");
$check->bind_param("s", $serial_number);
$check->execute();
$result = $check->get_result();

if ($result->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "Serial Number ซ้ำ! กรุณาสุ่มใหม่"]);
    exit;
}

// บันทึกข้อมูลฟาร์มใหม่ผูกกับ User ID ที่ส่งมาอย่างถูกต้อง
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