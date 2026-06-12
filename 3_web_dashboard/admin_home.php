<?php
session_start();

// --- LOGOUT ---
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    session_destroy();
    header("Location: web_login.php");
    exit();
}

// ตรวจสอบ Login
if (!isset($_SESSION['admin_logged'])) { 
    header("Location: web_login.php"); 
    exit(); 
}

require_once 'api/db_config.php';

// รับค่า Search และ Role Filter
$search = isset($_GET['search']) ? $conn->real_escape_string(trim($_GET['search'])) : '';
$role_filter = isset($_GET['role']) ? $_GET['role'] : 'all';

// 1. คำนวณ Stats (แยกนับเฉพาะผู้ใช้ทั่วไป และ แอดมิน)
$total_users_res = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'user'");
$total_users = $total_users_res->fetch_assoc()['count'];

$total_admins_res = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'admin'");
$total_admins = $total_admins_res->fetch_assoc()['count'];

$total_farms_res = $conn->query("SELECT COUNT(*) as count FROM user_farms");
$total_farms = $total_farms_res->fetch_assoc()['count'];

// 2. Query รายชื่อสมาชิก + ค้นหา + คัดกรอง
$query = "SELECT users.*, COUNT(user_farms.serial_number) as total_farms
          FROM users 
          LEFT JOIN user_farms ON users.id = user_farms.user_id";

$where_clauses = [];

// เงื่อนไขการค้นหา (ชื่อผู้ใช้ หรือ Token ID)
if (!empty($search)) {
    $where_clauses[] = "(users.username LIKE '%$search%' OR users.token_id LIKE '%$search%')";
}

// เงื่อนไขการคัดกรอง Role
if ($role_filter === 'admin') {
    $where_clauses[] = "users.role = 'admin'";
} elseif ($role_filter === 'user') {
    $where_clauses[] = "users.role = 'user'";
}

// รวมเงื่อนไข SQL
if (count($where_clauses) > 0) {
    $query .= " WHERE " . implode(" AND ", $where_clauses);
}

$query .= " GROUP BY users.id ORDER BY users.id DESC";
$result = $conn->query($query);
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <title>Admin Portal | ระบบจัดการสมาชิก</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        body { font-family: 'Sarabun', sans-serif; background-color: #f8fafc; }
        .card-custom { border: none; border-radius: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.02); }
        .stat-card { border-left: 5px solid #198754; }
        .nav-pills .nav-link { border-radius: 30px; color: #64748b; }
        .nav-pills .nav-link.active { background-color: #198754; color: white; }
    </style>
</head>
<body>

<nav class="navbar navbar-dark bg-dark mb-4 sticky-top">
    <div class="container">
        <a class="navbar-brand fw-bold text-success" href="#"><i class="bi bi-leaf-fill me-2"></i>SmartFarm Admin</a>
        <div class="d-flex align-items-center">
            <span class="text-white me-3"><i class="bi bi-person-circle me-1"></i><?php echo htmlspecialchars($_SESSION['admin_user'] ?? 'Admin'); ?></span>
            <a href="?action=logout" class="btn btn-outline-danger btn-sm rounded-pill"><i class="bi bi-box-arrow-right"></i> ออกจากระบบ</a>
        </div>
    </div>
</nav>

<div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="fw-bold m-0">ระบบจัดการบัญชีผู้ใช้</h2>
        <button class="btn btn-success rounded-pill px-4 shadow-sm" data-bs-toggle="modal" data-bs-target="#addUserModal">
            <i class="bi bi-person-plus-fill me-2"></i>เพิ่มสมาชิกใหม่
        </button>
    </div>
    
    <div class="row g-4 mb-4 mt-2">
        <div class="col-md-4">
            <div class="card card-custom stat-card p-4 bg-white" style="border-left-color: #dc3545;">
                <h6 class="text-muted small">จำนวนแอดมิน (Admin)</h6>
                <h3><?php echo number_format($total_admins); ?> คน</h3>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card card-custom stat-card p-4 bg-white">
                <h6 class="text-muted small">จำนวนผู้ใช้ทั่วไป (User)</h6>
                <h3><?php echo number_format($total_users); ?> คน</h3>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card card-custom stat-card p-4 bg-white" style="border-left-color: #0dcaf0;">
                <h6 class="text-muted small">จำนวนฟาร์มทั้งหมด</h6>
                <h3><?php echo number_format($total_farms); ?> ฟาร์ม</h3>
            </div>
        </div>
    </div>

    <div class="card card-custom p-4 bg-white mb-4">
        <div class="row align-items-center g-3">
            <div class="col-lg-6">
                <ul class="nav nav-pills gap-2">
                    <li class="nav-item"><a class="nav-link <?php echo $role_filter === 'all' ? 'active' : ''; ?>" href="?role=all&search=<?php echo urlencode($search); ?>">ทั้งหมด</a></li>
                    <li class="nav-item"><a class="nav-link <?php echo $role_filter === 'admin' ? 'active' : ''; ?>" href="?role=admin&search=<?php echo urlencode($search); ?>">Admin</a></li>
                    <li class="nav-item"><a class="nav-link <?php echo $role_filter === 'user' ? 'active' : ''; ?>" href="?role=user&search=<?php echo urlencode($search); ?>">User</a></li>
                </ul>
            </div>
            <div class="col-lg-6">
                <form action="" method="GET" class="d-flex">
                    <input type="hidden" name="role" value="<?php echo htmlspecialchars($role_filter); ?>">
                    <input type="text" name="search" class="form-control rounded-pill me-2 px-3" placeholder="ค้นหาด้วย ชื่อผู้ใช้ หรือ Token ID..." value="<?php echo htmlspecialchars($search); ?>">
                    <button type="submit" class="btn btn-success rounded-pill px-4 flex-shrink-0"><i class="bi bi-search me-1"></i> ค้นหา</button>
                </form>
            </div>
        </div>
    </div>

    <div class="card card-custom p-4 bg-white">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-light">
                    <tr>
                        <th>ชื่อผู้ใช้</th><th>รหัสผ่าน</th><th>Token ID</th><th>จำนวนอุปกรณ์</th><th class="text-center">การจัดการ</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if ($result->num_rows > 0): ?>
                        <?php while($row = $result->fetch_assoc()): ?>
                        <tr>
                            <td>
                                <div class="fw-bold"><?php echo htmlspecialchars($row['username']); ?></div>
                                <span class="badge <?php echo $row['role'] === 'admin' ? 'bg-danger' : 'bg-success'; ?>"><?php echo strtoupper($row['role']); ?></span>
                            </td>
                            <td><code><?php echo htmlspecialchars($row['password']); ?></code></td>
                            <td><span class="badge bg-secondary"><?php echo htmlspecialchars($row['token_id'] ?? '-'); ?></span></td>
                            <td><?php echo $row['total_farms']; ?> อุปกรณ์</td>
                            <td class="text-center">
                                <div class="d-flex justify-content-center gap-2">
                                    <a href="admin_farms.php?user_id=<?php echo $row['id']; ?>" class="btn btn-sm btn-success rounded-pill px-3 shadow-sm">ตรวจสอบ</a>
                                    <button class="btn btn-sm btn-light border rounded-circle" onclick="openEditUserModal(<?php echo $row['id']; ?>, '<?php echo htmlspecialchars($row['username']); ?>', '<?php echo htmlspecialchars($row['password']); ?>', '<?php echo htmlspecialchars($row['token_id'] ?? ''); ?>')"><i class="bi bi-pencil-fill text-primary"></i></button>
                                    <button class="btn btn-sm btn-light border rounded-circle" onclick="deleteUser(<?php echo $row['id']; ?>, '<?php echo htmlspecialchars($row['username']); ?>')"><i class="bi bi-trash-fill text-danger"></i></button>
                                </div>
                            </td>
                        </tr>
                        <?php endwhile; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="5" class="text-center py-4 text-muted">ไม่พบข้อมูลผู้ใช้ที่ตรงกับเงื่อนไขการค้นหา</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<div class="modal fade" id="addUserModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <form id="addUserForm" class="modal-content p-4 rounded-4 shadow border-0">
            <div class="modal-header border-0 p-0 mb-3">
                <h5 class="fw-bold text-dark m-0"><i class="bi bi-person-plus-fill text-success me-2"></i>เพิ่มสมาชิกใหม่เข้าระบบ</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-0">
                <div class="mb-3">
                    <label class="form-label text-muted small fw-bold">ชื่อผู้ใช้งาน (Username)</label>
                    <input type="text" class="form-control rounded-3 py-2" name="username" placeholder="กรอกชื่อผู้ใช้..." required>
                </div>
                <div class="mb-3">
                    <label class="form-label text-muted small fw-bold">รหัสผ่าน (Password)</label>
                    <input type="text" class="form-control rounded-3 py-2" name="password" placeholder="กรอกรหัสผ่าน..." required>
                </div>
                <div class="mb-3">
                    <label class="form-label text-muted small fw-bold">ระดับสิทธิ์การใช้งาน (Role)</label>
                    <select class="form-select rounded-3 py-2" name="role" required>
                        <option value="user" selected>USER (ผู้ใช้งานทั่วไป)</option>
                        <option value="admin">ADMIN (ผู้ดูแลระบบ)</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer border-0 p-0 mt-4 pt-2">
                <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">ยกเลิก</button>
                <button type="submit" class="btn btn-success rounded-pill px-4 shadow-sm">สร้างบัญชี</button>
            </div>
        </form>
    </div>
</div>

<div class="modal fade" id="editUserModal" tabindex="-1">
    <div class="modal-dialog"><form id="editUserForm" class="modal-content p-4 rounded-4 shadow border-0">
        <div class="modal-header border-0 p-0 mb-3"><h5 class="fw-bold">แก้ไขข้อมูลสมาชิก</h5></div>
        <div class="modal-body p-0">
            <input type="hidden" name="id" id="edit_user_id">
            <div class="mb-3"><label class="form-label text-muted small fw-bold">Username</label><input type="text" class="form-control" name="username" id="edit_username"></div>
            <div class="mb-3"><label class="form-label text-muted small fw-bold">Password</label><input type="text" class="form-control" name="password" id="edit_password"></div>
            <div class="mb-3"><label class="form-label text-muted small fw-bold">Token ID</label><input type="text" class="form-control" name="token_id" id="edit_token_id"></div>
        </div>
        <div class="modal-footer border-0 p-0 mt-4 pt-2"><button type="submit" class="btn btn-success rounded-pill px-4">บันทึก</button></div>
    </form></div>
</div>

<script>
// 🟢 ฟังก์ชันส่งข้อมูลไปยัง api/admin/add_user.php ของคุณโดยตรง
document.getElementById('addUserForm').onsubmit = async function(e) { 
    e.preventDefault(); 
    
    try {
        const res = await fetch('api/admin/add_user.php', { 
            method: 'POST', 
            body: new FormData(this) 
        }); 
        
        const data = await res.json();
        
        if(data.status === 'success') {
            alert("✨ สำเร็จ: " + data.message);
            location.reload(); 
        } else {
            alert("⚠️ แจ้งเตือน: " + data.message);
        }
    } catch (error) {
        alert("❌ เกิดข้อผิดพลาด: ไม่สามารถเชื่อมต่อกับ API ได้");
    }
};

function openEditUserModal(id, username, password, token_id) {
    document.getElementById('edit_user_id').value = id;
    document.getElementById('edit_username').value = username;
    document.getElementById('edit_password').value = password;
    document.getElementById('edit_token_id').value = token_id;
    new bootstrap.Modal(document.getElementById('editUserModal')).show();
}

document.getElementById('editUserForm').onsubmit = async function(e) { 
    e.preventDefault(); 
    const res = await fetch('api/edit_user.php', { method: 'POST', body: new FormData(this) }); 
    alert((await res.json()).message); 
    location.reload(); 
};

async function deleteUser(id, username) { 
    if (!confirm(`ยืนยันการลบผู้ใช้: ${username}?`)) return; 
    const formData = new FormData(); 
    formData.append('id', id); 
    const res = await fetch('api/delete_user.php', { method: 'POST', body: formData }); 
    alert((await res.json()).message); 
    location.reload(); 
}
</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>