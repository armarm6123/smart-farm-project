<?php
session_start();

// 🔑 1. ลอจิกจัดการการ Logout ภายในตัวเองโดยไม่ต้องย้ายหน้าไฟล์
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    session_unset();     // ล้างตัวแปร Session ทั้งหมด
    session_destroy();   // ทำลาย Session
    header("Location: web_login.php"); // ดีดกลับหน้าล็อกอินหลัก
    exit();
}

// ตรวจสอบความปลอดภัย: หากไม่ได้ล็อกอิน ให้ดีดกลับไปหน้าล็อกอินหลัก (web_login.php)
if (!isset($_SESSION['user_logged']) || $_SESSION['user_logged'] !== true) { 
    header("Location: web_login.php");
    exit();
}

require_once 'api/db_config.php';
$user_id = $_SESSION['user_id'];
$token_id = $_SESSION['token_id']; // ดึงค่า token_id ประจำตัวผู้ใช้

// 💡 แก้ไขจุดที่ 1: เปลี่ยนจาก ORDER BY id ASC เป็น ORDER BY created_at ASC เพื่อไม่ให้ SQL พัง และเรียงฟาร์มใหม่ไว้ท้ายสุด
$farm_query = "SELECT * FROM user_farms WHERE user_id = '$user_id' ORDER BY created_at ASC";
$farm_result = $conn->query($farm_query);
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartFarm | หน้าหลักผู้ใช้งาน</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        body { 
            font-family: 'Sarabun', sans-serif; 
            background-color: #f8fafc; 
        }
        .navbar-custom {
            background-color: #198754;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }
        .user-profile-trigger {
            cursor: pointer;
            padding: 6px 14px;
            border-radius: 50px;
            background-color: rgba(255, 255, 255, 0.1);
            transition: all 0.2s ease;
        }
        .user-profile-trigger:hover {
            background-color: rgba(255, 255, 255, 0.2);
        }
        .farm-card {
            border: none;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.04);
            transition: all 0.3s ease;
            background-color: white;
            position: relative;
        }
        .farm-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(25, 135, 84, 0.15);
        }
        .action-dropdown {
            position: absolute;
            top: 20px;
            right: 20px;
        }
        .modal-custom, .offcanvas-custom {
            border-radius: 20px 0 0 20px;
            border: none;
        }
        .modal-custom {
            border-radius: 20px;
        }
        .token-box {
            background-color: #f1f5f9;
            border: 1px dashed #cbd5e1;
            cursor: pointer;
            transition: background 0.2s;
        }
        .token-box:hover {
            background-color: #e2e8f0;
        }
    </style>
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-dark navbar-custom py-3">
    <div class="container">
        <a class="navbar-brand fw-bold fs-4" href="user_home.php"><i class="bi bi-leaf-fill me-2"></i>SmartFarm System</a>
        
        <div class="d-flex align-items-center gap-3">
            <div class="text-white user-profile-trigger fw-bold shadow-sm" data-bs-toggle="offcanvas" data-bs-target="#userProfileOffcanvas">
                <i class="bi bi-person-circle me-1"></i> 
                <span><?php echo htmlspecialchars($_SESSION['user_user']); ?></span>
                <i class="bi bi-chevron-down ms-1 small text-white-50"></i>
            </div>

            <a href="user_home.php?action=logout" class="btn btn-sm btn-danger rounded-pill px-3 fw-bold shadow-sm" onclick="return confirm('คุณต้องการออกจากระบบใช่หรือไม่?')">
                <i class="bi bi-box-arrow-right me-1"></i> ออกจากระบบ
            </a>
        </div>
    </div>
</nav>

<div class="offcanvas offcanvas-end offcanvas-custom" tabindex="-1" id="userProfileOffcanvas" aria-labelledby="userProfileOffcanvasLabel">
    <div class="offcanvas-header border-bottom py-4">
        <h5 class="offcanvas-title fw-bold text-dark" id="userProfileOffcanvasLabel">
            <i class="bi bi-sliders me-2 text-success"></i>ข้อมูลผู้ใช้
        </h5>
        <button type="button" class="btn-close shadow-none" data-bs-dismiss="offcanvas" aria-label="Close"></button>
    </div>
    <div class="offcanvas-body d-flex flex-column justify-content-between p-4">
        <div>
            <div class="text-center my-4">
                <i class="bi bi-person-circle text-success" style="font-size: 4.5rem;"></i>
                <h4 class="fw-bold text-dark mt-2 mb-0"><?php echo htmlspecialchars($_SESSION['user_user']); ?></h4>
                <span class="badge bg-success-subtle text-success px-3 py-1.5 rounded-pill small mt-2">ระดับ: ผู้ใช้งานทั่วไป</span>
            </div>

            <hr class="text-muted opacity-25">

            <div class="mb-4">
                <label class="form-label text-secondary small fw-bold mb-2"><i class="bi bi-key-fill text-warning me-1"></i> รหัสประจำตัว (User Token)</label>
                <div class="p-3 rounded-3 token-box d-flex justify-content-between align-items-center" onclick="copyToken('<?php echo htmlspecialchars($token_id); ?>')" title="คลิกเพื่อคัดลอก">
                    <span class="font-monospace text-dark fw-bold"><?php echo htmlspecialchars($token_id); ?></span>
                    <i class="bi bi-copy text-muted"></i>
                </div>
                <div class="form-text text-muted small mt-1">ใช้รหัส Token นี้ในการผูกเข้ากับบอร์ดสมาร์ตฟาร์มของคุณ</div>
            </div>
        </div>

        <div class="mb-3">
            <button class="btn btn-danger-subtle text-danger border-1 border-danger-subtle w-100 py-2.5 rounded-pill fw-bold" onclick="clickDeleteAccount()">
                <i class="bi bi-trash3-fill me-2"></i>ลบบัญชีผู้ใช้งานถาวร
            </button>
        </div>
    </div>
</div>

<div class="container my-5">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center mb-4 gap-3">
        <div>
            <h2 class="fw-bold text-dark"><i class="bi bi-grid-1x2-fill text-success me-2"></i>ระบบจัดการฟาร์มของคุณ</h2>
        </div>
        <button class="btn btn-success btn-lg rounded-pill px-4 shadow-sm" data-bs-toggle="modal" data-bs-target="#addFarmModal" onclick="generateSerialNumber()">
            <i class="bi bi-plus-circle-fill me-2"></i>เพิ่มฟาร์มใหม่
        </button>
    </div>

    <div class="row g-4">
        <?php if ($farm_result->num_rows == 0): ?>
            <div class="col-12 text-center py-5 bg-white rounded-4 shadow-sm my-3">
                <i class="bi bi-cpu text-muted mb-3" style="font-size: 4rem;"></i>
                <h4 class="text-muted fw-bold">ไม่พบอุปกรณ์ฟาร์มในบัญชีของคุณ</h4>
                <p class="text-secondary mb-0">กรุณากดปุ่ม "เพิ่มฟาร์มใหม่" ด้านบนเพื่อเริ่มระบบ</p>
            </div>
        <?php else: ?>
            <?php while($farm = $farm_result->fetch_assoc()): ?>
                <div class="col-12 col-md-6 col-lg-4">
                    <div class="card farm-card p-4 h-100 d-flex flex-column justify-content-between">
                        
                        <div class="dropdown action-dropdown">
                            <button class="btn btn-link text-muted p-0 shadow-none" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="bi bi-three-dots-vertical fs-5"></i>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end border-0 shadow-sm rounded-3">
                                <li>
                                    <button class="dropdown-item py-2" onclick="openEditModal('<?php echo htmlspecialchars($farm['serial_number'], ENT_QUOTES); ?>', '<?php echo htmlspecialchars($farm['farm_name'], ENT_QUOTES); ?>')">
                                        <i class="bi bi-pencil-square text-warning me-2"></i>แก้ไขชื่อฟาร์ม
                                    </button>
                                </li>
                                <li><hr class="dropdown-divider"></li>
                                <li>
                                    <button class="dropdown-item py-2 text-danger" onclick="deleteFarm('<?php echo htmlspecialchars($farm['serial_number'], ENT_QUOTES); ?>')">
                                        <i class="bi bi-trash3-fill me-2"></i>ลบฟาร์มนี้
                                    </button>
                                </li>
                            </ul>
                        </div>

                        <div class="pe-4 mb-4">
                            <h3 class="fw-bold text-dark text-truncate mb-2" style="max-width: 85%;"><?php echo htmlspecialchars($farm['farm_name']); ?></h3>
                            <div class="d-flex align-items-center">
                                <span class="text-muted small">S/N: <code><?php echo $farm['serial_number']; ?></code></span>
                            </div>
                        </div>
                        
                        <div class="d-flex flex-column gap-2 mt-auto">
                            <a href="user_farm.php?sn=<?php echo $farm['serial_number']; ?>" class="btn btn-success w-100 rounded-pill py-2 fw-semibold">
                                <i class="bi bi-speedometer2 me-1"></i> เข้าสู่แดชบอร์ดควบคุม
                            </a>
                        </div>
                    </div>
                </div>
            <?php endwhile; ?>
        <?php endif; ?>
    </div>
</div>

<div class="modal fade" id="addFarmModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content modal-custom p-3">
            <div class="modal-header border-0">
                <h5 class="modal-title fw-bold text-dark"><i class="bi bi-plus-circle text-success me-2"></i>เพิ่มอุปกรณ์ฟาร์มใหม่</h5>
                <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form id="addFarmForm" onsubmit="submitAddFarm(event)">
                <div class="modal-body py-2">
                    <input type="hidden" name="user_id" value="<?php echo $user_id; ?>">
                    <div class="mb-3">
                        <label class="form-label text-secondary small fw-bold">ชื่อฟาร์ม / พื้นที่เพาะปลูก</label>
                        <input type="text" name="farm_name" class="form-control bg-light border-0 py-2 rounded-3 shadow-none" placeholder="เช่น โรงเรือนเมล่อน เอ" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label text-secondary small fw-bold">Serial Number อุปกรณ์</label>
                        <div class="input-group">
                            <input type="text" name="serial_number" id="add_serial_number" class="form-control bg-light border-0 py-2 rounded-start-3 shadow-none" placeholder="กดปุ่มสุ่มเลขด้านขวา" required readonly>
                            <button class="btn btn-dark rounded-end-3 px-3 shadow-none" type="button" onclick="generateSerialNumber()"><i class="bi bi-shuffle me-1"></i> สุ่มเลข</button>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0">
                    <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">ยกเลิก</button>
                    <button type="submit" class="btn btn-success rounded-pill px-4 shadow-sm">บันทึกฟาร์ม</button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="modal fade" id="editFarmModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content modal-custom p-3">
            <div class="modal-header border-0">
                <h5 class="modal-title fw-bold text-dark"><i class="bi bi-pencil-square text-warning me-2"></i>แก้ไขชื่อฟาร์ม</h5>
                <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form id="editFarmForm" onsubmit="submitEditFarm(event)">
                <div class="modal-body py-2">
                    <input type="hidden" name="serial_number" id="edit_serial_number">
                    <div class="mb-3">
                        <label class="form-label text-secondary small fw-bold">ระบุชื่อฟาร์มใหม่ของคุณ</label>
                        <input type="text" name="farm_name" id="edit_farm_name" class="form-control bg-light border-0 py-2 rounded-3 shadow-none" required>
                    </div>
                </div>
                <div class="modal-footer border-0">
                    <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">ยกเลิก</button>
                    <button type="submit" class="btn btn-warning text-dark fw-bold rounded-pill px-4 shadow-sm">อัปเดตข้อมูล</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
function copyToken(text) {
    navigator.clipboard.writeText(text).then(() => {
        alert(`📋 คัดลอกรหัสประจำตัว User Token: "${text}" เรียบร้อย!`);
    }).catch(err => {
        console.error('ไม่สามารถคัดลอกได้', err);
    });
}

async function clickDeleteAccount() {
    const userId = "<?php echo isset($user_id) ? $user_id : ($_SESSION['user_id'] ?? 0); ?>";
    
    if (userId == 0 || userId == "") {
        alert("⚠️ เกิดข้อผิดพลาด: ไม่พบข้อมูลบัญชีผู้ใช้งาน");
        return;
    }
    
    if (confirm("🚨 คำเตือนความปลอดภัยสูงสุด!\n\nการกดลบบัญชีนี้จะทำการลบข้อมูลโปรไฟล์ของคุณ ข้อมูลอุปกรณ์ฟาร์ม และประวัติบันทึกเซนเซอร์ทั้งหมดออกจากเซิร์ฟเวอร์แบบถาวรและไม่สามารถเรียกคืนได้อีก!\n\nคุณยังต้องการลบบัญชีนี้อยู่ใช่หรือไม่?")) {
        
        const formData = new FormData();
        formData.append('user_id', userId);

        try {
            const res = await fetch('api/delete_user.php', { 
                method: 'POST', 
                body: formData 
            });
            
            const data = await res.json();
            
            if (data.status === 'success') {
                alert("🔒 ระบบทำการลบข้อมูลบัญชีของคุณเสร็จสมบูรณ์");
                window.location.href = "web_login.php";
            } else {
                alert("⚠️ ไม่สามารถลบบัญชีได้: " + data.message);
            }
        } catch (error) {
            console.error(error);
            alert("❌ เกิดข้อผิดพลาด: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้");
        }
    }
}

function generateSerialNumber() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    let result = 'SN-';
    for (let i = 0; i < 6; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    document.getElementById('add_serial_number').value = result;
}

async function submitAddFarm(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    
    try {
        const res = await fetch('api/add_farm.php', { method: 'POST', body: formData }); 
        const data = await res.json();
        if(data.status === 'success') {
            location.reload();
        } else {
            alert("⚠️ " + data.message);
        }
    } catch (error) {
        alert("เกิดข้อผิดพลาดในการติดต่อเซิร์ฟเวอร์");
    }
}

let bootstrapEditModal;
// 💡 แก้ไข: เปลี่ยนตัวแปรรับค่าจาก id เป็น serialNumber
function openEditModal(serialNumber, currentName) {
    document.getElementById('edit_serial_number').value = serialNumber;
    document.getElementById('edit_farm_name').value = currentName;
    bootstrapEditModal = new bootstrap.Modal(document.getElementById('editFarmModal'));
    bootstrapEditModal.show();
}

async function submitEditFarm(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    
    try {
        const res = await fetch('api/edit_farm.php', { method: 'POST', body: formData }); 
        const data = await res.json();
        if(data.status === 'success') {
            bootstrapEditModal.hide();
            location.reload(); 
        } else {
            alert("⚠️ เกิดข้อผิดพลาด: " + data.message);
        }
    } catch (error) {
        alert("ไม่สามารถอัปเดตข้อมูลได้ในขณะนี้");
    }
}

// 💡 แก้ไข: เปลี่ยนจากรับค่า id เป็นรับ serialNumber แทนเพื่อส่งค่าให้ไฟล์หลังบ้านลบข้อมูลได้อย่างถูกต้อง
async function deleteFarm(serialNumber) {
    if(confirm('🚨 ยืนยันการลบฟาร์ม?\nการดำเนินการนี้จะลบสิทธิ์การเข้าถึงอุปกรณ์นี้ออกจากระบบและไม่สามารถกู้คืนได้')) {
        const formData = new FormData();
        formData.append('serial_number', serialNumber);
        
        try {
            const res = await fetch('api/delete_farm.php', { method: 'POST', body: formData }); 
            const data = await res.json();
            if(data.status === 'success') {
                location.reload();
            } else {
                alert("⚠️ ไม่สามารถลบข้อมูลได้: " + data.message);
            }
        } catch (error) {
            alert("เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย");
        }
    }
}
</script>
</body>
</html>