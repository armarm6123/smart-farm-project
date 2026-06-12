<?php
// db_config.php
$host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "smart_farm_db";

// เชื่อมต่อ Database
$conn = new mysqli($host, $db_user, $db_pass, $db_name);

// ตรวจสอบการเชื่อมต่อ
if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// ตั้งค่าภาษาไทย
$conn->set_charset("utf8");
?>