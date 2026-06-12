<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET"); // เพิ่ม GET เผื่อแอปส่งมาทาง URL

require_once '../db_config.php';

$input = json_decode(file_get_contents('php://input'), true);
$user_id = $_REQUEST['id'] ?? $_REQUEST['user_id'] ?? $input['id'] ?? $input['user_id'] ?? '';

if (!empty($user_id)) {
    // ใช้ Transaction เพื่อความปลอดภัยสูงสุด
    $conn->begin_transaction();

    try {
        // 1. ลบ Logs ของฟาร์มทั้งหมดที่ User นี้เป็นเจ้าของ
        $sql_logs = "DELETE FROM sensor_logs WHERE serial_number IN (SELECT serial_number FROM user_farms WHERE user_id = ?)";
        $stmt_logs = $conn->prepare($sql_logs);
        $stmt_logs->bind_param("i", $user_id);
        $stmt_logs->execute();

        // 2. ลบอุปกรณ์ฟาร์ม
        $del_farms = $conn->prepare("DELETE FROM user_farms WHERE user_id = ?");
        $del_farms->bind_param("i", $user_id);
        $del_farms->execute();

        // 3. ลบตัวผู้ใช้ (ยกเว้น admin)
        $stmt = $conn->prepare("DELETE FROM users WHERE id = ? AND role != 'admin'");
        $stmt->bind_param("i", $user_id);
        $stmt->execute();

        if ($stmt->affected_rows > 0) {
            $conn->commit(); // ยืนยันการลบทั้งหมด
            echo json_encode(["status" => "success", "message" => "ลบข้อมูลเรียบร้อยแล้ว"]);
        } else {
            throw new Exception("ไม่สามารถลบบัญชีแอดมินหรือหาผู้ใช้ไม่พบ");
        }
    } catch (Exception $e) {
        $conn->rollback(); // ยกเลิกการลบทั้งหมดหากมีจุดใดจุดหนึ่งพลาด
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "No ID provided"]);
}
$conn->close();