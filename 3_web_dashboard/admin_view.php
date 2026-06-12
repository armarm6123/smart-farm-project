<?php
session_start();
if (!isset($_SESSION['admin_logged'])) { 
    header("Location: web_login.php"); 
    exit(); 
}
require_once 'api/db_config.php';

// 💡 ปรับปรุงตัวรับค่า: รองรับทั้งแบบเก่า (?farm_id=13) และแบบใหม่ (?serial_number=... หรือ ?sn=...)
$serial_number = isset($_GET['serial_number']) ? $conn->real_escape_string(trim($_GET['serial_number'])) : (isset($_GET['sn']) ? $conn->real_escape_string(trim($_GET['sn'])) : '');
$old_farm_id = isset($_GET['farm_id']) ? intval($_GET['farm_id']) : 0;

// 1. ดึงรายละเอียดของฟาร์ม
if (!empty($serial_number)) {
    // โครงสร้างใหม่: ค้นหาผ่าน Serial Number ตรงๆ (เนื่องจากลบ id ออกจาก user_farms แล้ว)
    $farm_stmt = $conn->prepare("SELECT user_farms.farm_name, user_farms.serial_number, users.username, users.id as user_id 
                                 FROM user_farms 
                                 LEFT JOIN users ON user_farms.user_id = users.id 
                                 WHERE user_farms.serial_number = ? LIMIT 1");
    $farm_stmt->bind_param("s", $serial_number);
} else if ($old_farm_id > 0) {
    // 💡 เคสพิเศษรองรับระบบเก่า: ถ้า URL ยังส่งเป็น ?farm_id=13 เข้ามา 
    // ระบบจะไปค้นหาจาก serial_number มาให้แทน เพื่อไม่ให้หน้าเว็บแจ้งเตือนพัง
    $farm_stmt = $conn->prepare("SELECT user_farms.farm_name, user_farms.serial_number, users.username, users.id as user_id 
                                 FROM user_farms 
                                 LEFT JOIN users ON user_farms.user_id = users.id 
                                 WHERE user_farms.serial_number = (SELECT serial_number FROM user_farms WHERE id = ? LIMIT 1) LIMIT 1");
    $farm_stmt->bind_param("i", $old_farm_id);
} else {
    die("ไม่ได้ระบุข้อมูลอุปกรณ์ฟาร์ม");
}

$farm_stmt->execute();
$farm_data = $farm_stmt->get_result()->fetch_assoc();

if (!$farm_data) { 
    die("ไม่พบอุปกรณ์ฟาร์มที่ระบุ"); 
}

// 2. ดึงประวัติ Logs ล่าสุด 20 รายการ (จัดเรียงผ่าน created_at DESC เพราะไม่มี id ในเซนเซอร์ล็อกแล้ว)
$log_stmt = $conn->prepare("SELECT temp, humi, soil_moisture, light_status, pump_status, created_at 
                             FROM sensor_logs 
                             WHERE serial_number = ? 
                             ORDER BY created_at DESC LIMIT 20");
$log_stmt->bind_param("s", $farm_data['serial_number']);
$log_stmt->execute();
$log_result = $log_stmt->get_result();
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Portal | Sensor Logs</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        body { font-family: 'Sarabun', sans-serif; background-color: #f8fafc; }
        .card-custom { border: none; border-radius: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.02); }
        .table thead th { border-top: none; background-color: #f1f5f9; font-weight: 600; color: #475569; }
        .badge-lightbulb { background-color: #fefce8; color: #854d0e; border: 1px solid #fef08a; }
        .badge-pump { background-color: #ecfeff; color: #0891b2; border: 1px solid #a5f3fc; }
    </style>
</head>
<body>
<div class="container py-5">
    <div class="mb-4">
        <a href="admin_farms.php?user_id=<?php echo $farm_data['user_id']; ?>" class="btn btn-outline-secondary rounded-pill px-4">
            <i class="bi bi-arrow-left"></i> ย้อนกลับไปรายการฟาร์ม
        </a>
    </div>

    <div class="card card-custom p-4 mb-4 bg-white">
        <span class="badge bg-success-subtle text-success px-3 py-1.5 rounded-pill mb-2 d-inline-block" style="width: max-content;">ตรวจสอบข้อมูลเรียลไทม์</span>
        <h2 class="fw-bold text-dark m-0"><?php echo htmlspecialchars($farm_data['farm_name']); ?></h2>
        <p class="text-muted m-0 mt-1">
            <i class="bi bi-person-fill"></i> เจ้าของ: <strong><?php echo htmlspecialchars($farm_data['username']); ?></strong> | 
            <i class="bi bi-tag-fill ms-2"></i> Serial Number: <strong><?php echo htmlspecialchars($farm_data['serial_number']); ?></strong>
        </p>
    </div>

    <div class="card card-custom p-4 bg-white">
        <h5 class="fw-bold mb-4"><i class="bi bi-clock-history text-success me-1"></i> ประวัติเซนเซอร์ย้อนหลัง (Sensor Log)</h5>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead>
                    <tr>
                        <th class="py-3">วัน-เวลาบันทึก</th>
                        <th>อุณหภูมิ (°C)</th>
                        <th>ความชื้นอากาศ (%)</th>
                        <th>ความชื้นดิน (%)</th>
                        <th>สถานะหลอดไฟ</th>
                        <th>สถานะปั๊มน้ำ</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if ($log_result && $log_result->num_rows > 0): ?>
                        <?php while($log = $log_result->fetch_assoc()): ?>
                            <tr>
                                <td><small class="text-muted"><?php echo $log['created_at']; ?></small></td>
                                <td><strong class="text-danger"><?php echo number_format($log['temp'], 1); ?> °C</strong></td>
                                <td><strong class="text-primary"><?php echo number_format($log['humi'], 1); ?> %</strong></td>
                                <td><strong style="color: #8B4513;"><?php echo number_format($log['soil_moisture'], 1); ?> %</strong></td>
                                
                                <td>
                                    <?php echo $log['light_status'] == 1 
                                        ? '<span class="badge badge-lightbulb rounded-pill px-3 py-1.5"><i class="bi bi-lightbulb-fill me-1"></i> เปิดไฟ</span>' 
                                        : '<span class="badge bg-light text-muted rounded-pill px-3 py-1.5">ปิดไฟ</span>'; ?>
                                </td>

                                <td>
                                    <?php echo $log['pump_status'] == 1 
                                        ? '<span class="badge badge-pump rounded-pill px-3 py-1.5"><i class="bi bi-droplets-fill me-1"></i> ทำงาน</span>' 
                                        : '<span class="badge bg-light text-muted rounded-pill px-3 py-1.5">หยุดทำงาน</span>'; ?>
                                </td>
                            </tr>
                        <?php endwhile; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="6" class="text-center py-5 text-muted">
                                <i class="bi bi-cloud-slash display-5 d-block mb-3 text-secondary"></i>
                                ยังไม่มีข้อมูลบันทึกใดๆ ส่งมาจากบอร์ดเซนเซอร์ของกล่องซีเรียลนี้
                            </td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
<?php 
$farm_stmt->close();
$log_stmt->close();
$conn->close();
?>
</body>
</html>