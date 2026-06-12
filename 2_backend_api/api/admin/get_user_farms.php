<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../db_config.php'; // ปรับ path ให้ตรงกับโครงสร้างของคุณ

$user_id = $_GET['user_id'] ?? $_POST['user_id'] ?? '';

if (!empty($user_id)) {
    // 💡 แก้ไข: เปลี่ยนจาก ORDER BY serial_number ASC เป็น ORDER BY created_at ASC เพื่อให้เรียงตามเวลาที่สร้างจริง (ฟาร์มใหม่ไปอยู่ข้างหลังสุด)
    $sql = "SELECT farm_name, serial_number FROM user_farms WHERE user_id = ? ORDER BY created_at ASC";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $farms = [];
    while($row = $result->fetch_assoc()) {
        $farms[] = [
            "farm_name" => $row['farm_name'],
            "serial_number" => $row['serial_number']
        ];
    }
    
    // คืนค่ากลับไปในรูปแบบที่โค้ดแอดมินฝั่ง Flutter รอถอดรหัสอยู่
    echo json_encode([
        "status" => "success",
        "farms" => $farms
    ], JSON_UNESCAPED_UNICODE);
    
    $stmt->close();
} else {
    echo json_encode([
        "status" => "error",
        "message" => "No user_id provided",
        "farms" => []
    ]);
}

$conn->close();
?>