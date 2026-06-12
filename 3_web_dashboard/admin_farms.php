<?php
session_start();
if (!isset($_SESSION['admin_logged'])) { header("Location: admin_login.php"); exit(); }
require_once 'api/db_config.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

$u_stmt = $conn->prepare("SELECT username FROM users WHERE id = ?");
$u_stmt->bind_param("i", $user_id);
$u_stmt->execute();
$user = $u_stmt->get_result()->fetch_assoc();
if (!$user) { die("ไม่พบบัญชีผู้ใช้นี้"); }

// 💡 แก้ไข: เปลี่ยนจาก ORDER BY serial_number ASC เป็น ORDER BY created_at ASC เพื่อให้ฟาร์มที่สร้างใหม่ไปต่อท้ายสุด (อยู่ข้างหลัง)
$f_stmt = $conn->prepare("SELECT farm_name, serial_number FROM user_farms WHERE user_id = ? ORDER BY created_at ASC");
$f_stmt->bind_param("i", $user_id);
$f_stmt->execute();
$farms = $f_stmt->get_result();
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <title>Admin Portal | รายการฟาร์ม</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        body { font-family: 'Sarabun', sans-serif; background-color: #f8fafc; }
        .card-custom { border: none; border-radius: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.02); }
    </style>
</head>
<body>
<div class="container py-5">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <a href="admin_home.php" class="btn btn-outline-secondary rounded-pill px-4"><i class="bi bi-arrow-left"></i> ย้อนกลับไปรายชื่อสมาชิก</a>
        <button class="btn btn-success rounded-pill px-4 shadow-sm" onclick="openAddFarmModal()">
            <i class="bi bi-plus-circle-fill me-1"></i> เพิ่มฟาร์มใหม่ให้ผู้ใช้
        </button>
    </div>

    <div class="card card-custom p-4 mb-4 bg-white">
        <h3 class="fw-bold m-0"><i class="bi bi-folder2-open text-success me-1"></i> รายการอุปกรณ์ของคุณ: <?php echo htmlspecialchars($user['username']); ?></h3>
        <p class="text-muted small m-0 mt-1">สามารถทำการแก้ไข ลบ หรือผูกอุปกรณ์ฟาร์มใหม่ให้ลูกค้าคนนี้ได้ทันที</p>
    </div>

    <div class="row g-4">
        <?php if ($farms->num_rows > 0): ?>
            <?php while($farm = $farms->fetch_assoc()): ?>
            <div class="col-md-6 col-lg-4">
                <div class="card card-custom p-4 bg-white h-100 d-flex flex-column justify-content-between border">
                    <div>
                        <div class="d-flex justify-content-between align-items-start">
                            <div class="display-6 text-success"><i class="bi bi-cpu"></i></div>
                            <div class="d-flex gap-1">
                                <button class="btn btn-sm btn-light rounded-circle" 
                                        onclick="openEditFarmModal('<?php echo htmlspecialchars($farm['serial_number'], ENT_QUOTES); ?>', '<?php echo htmlspecialchars($farm['farm_name'], ENT_QUOTES); ?>')">
                                    <i class="bi text-primary bi-pencil"></i>
                                </button>
                                <button class="btn btn-sm btn-light rounded-circle" 
                                        onclick="deleteFarm('<?php echo htmlspecialchars($farm['serial_number'], ENT_QUOTES); ?>', '<?php echo htmlspecialchars($farm['farm_name'], ENT_QUOTES); ?>')">
                                    <i class="bi text-danger bi-trash"></i>
                                </button>
                            </div>
                        </div>
                        <h4 class="fw-bold text-dark m-0 mt-3"><?php echo htmlspecialchars($farm['farm_name']); ?></h4>
                        <p class="text-muted small mt-2"><i class="bi bi-tag-fill me-1"></i> Serial: <strong><?php echo htmlspecialchars($farm['serial_number']); ?></strong></p>
                    </div>
                    <a href="admin_view.php?serial_number=<?php echo urlencode($farm['serial_number']); ?>" class="btn btn-success rounded-pill w-100 py-2 mt-4">
                        <i class="bi bi-activity me-1"></i> ดูประวัติย้อนหลัง (Logs)
                    </a>
                </div>
            </div>
            <?php endwhile; ?>
        <?php else: ?>
            <div class="col-12 text-center py-5">
                <i class="bi bi-cpu display-4 text-muted mb-3 d-block"></i>
                <p class="text-muted fs-5">สมาชิกรายนี้ยังไม่ได้ทำเชื่อมต่ออุปกรณ์ใดๆ</p>
            </div>
        <?php endif; ?>
    </div>
</div>

<div class="modal fade" id="addFarmModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content border-0 rounded-4 shadow">
      <div class="modal-header border-0 pb-0">
        <h5 class="modal-title fw-bold"><i class="bi bi-plus-circle text-success me-1"></i> เพิ่มฟาร์มใหม่ให้สมาชิก</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <form id="addFarmForm" onsubmit="submitAddFarm(event)">
        <div class="modal-body p-4">
            <input type="hidden" name="user_id" value="<?php echo $user_id; ?>">
            <div class="mb-3">
                <label class="form-label small fw-bold text-muted">ชื่อฟาร์ม (Farm Name)</label>
                <input type="text" class="form-control rounded-3" name="farm_name" id="add_farm_name" required placeholder="เช่น ฟาร์มมะเขือเทศ">
            </div>
            <div class="mb-3">
                <label class="form-label small fw-bold text-muted">หมายเลขเครื่อง (Serial Number)</label>
                <div class="input-group">
                    <input type="text" class="form-control rounded-start-3" name="serial_number" id="add_serial_number" required>
                    <button class="btn btn-outline-secondary" type="button" onclick="generateSerialNumber()"><i class="bi bi-shuffle"></i> สุ่มเลขใหม่</button>
                </div>
            </div>
        </div>
        <div class="modal-footer border-0">
            <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">ยกเลิก</button>
            <button type="submit" class="btn btn-success rounded-pill px-4">บันทึกฟาร์ม</button>
        </div>
      </form>
    </div>
  </div>
</div>

<div class="modal fade" id="editFarmModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content border-0 rounded-4 shadow">
      <div class="modal-header border-0 pb-0">
        <h5 class="modal-title fw-bold"><i class="bi bi-gear-fill text-success me-1"></i> แก้ไขอุปกรณ์ฟาร์ม</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <form id="editFarmForm" onsubmit="submitEditFarm(event)">
        <div class="modal-body p-4">
            <input type="hidden" name="serial_number" id="edit_serial_number">
            <div class="mb-3">
                <label class="form-label small fw-bold text-muted">ชื่อฟาร์มใหม่ (Farm Name)</label>
                <input type="text" class="form-control rounded-3" name="farm_name" id="edit_farm_name" required>
            </div>
        </div>
        <div class="modal-footer border-0">
            <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">ยกเลิก</button>
            <button type="submit" class="btn btn-success rounded-pill px-4">บันทึกข้อมูล</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
let addModal, editModal;

document.addEventListener("DOMContentLoaded", function() {
    addModal = new bootstrap.Modal(document.getElementById('addFarmModal'));
    editModal = new bootstrap.Modal(document.getElementById('editFarmModal'));
});

function generateSerialNumber() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 8; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    document.getElementById('add_serial_number').value = 'SN-' + result;
}

function openAddFarmModal() {
    document.getElementById('add_farm_name').value = '';
    generateSerialNumber();
    addModal.show();
}

function submitAddFarm(event) {
    event.preventDefault();
    const formData = new FormData(document.getElementById('addFarmForm'));

    fetch('api/admin/admin_add_farm.php', {
        method: 'POST',
        body: formData
    })
    .then(res => res.json())
    .then(data => {
        if(data.status === 'success') {
            alert('เพิ่มฟาร์มใหม่สำเร็จ!');
            location.reload();
        } else {
            alert(data.message || 'เกิดข้อผิดพลาดในการเพิ่มฟาร์ม');
        }
    })
    .catch(err => {
        console.error(err);
        alert('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    });
}

function openEditFarmModal(serialNumber, name) {
    document.getElementById('edit_serial_number').value = serialNumber;
    document.getElementById('edit_farm_name').value = name;
    editModal.show();
}

function submitEditFarm(event) {
    event.preventDefault();
    const formData = new FormData(document.getElementById('editFarmForm'));

    fetch('api/admin/admin_edit_farm.php', {
        method: 'POST',
        body: formData
    })
    .then(res => res.json())
    .then(data => {
        if(data.status === 'success') {
            alert('แก้ไขข้อมูลสำเร็จ!');
            location.reload();
        } else {
            alert(data.message || 'เกิดข้อผิดพลาด');
        }
    })
    .catch(err => {
        console.error(err);
        alert('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    });
}

function deleteFarm(serialNumber, name) {
    if (confirm("คุณต้องการยกเลิกและลบอุปกรณ์ฟาร์ม: " + name + " ใช่หรือไม่?")) {
        const formData = new FormData();
        formData.append('serial_number', serialNumber);

        fetch('api/admin/admin_delete_farm.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if(data.status === 'success') {
                alert('ลบข้อมูลฟาร์มสำเร็จ!');
                location.reload();
            } else {
                alert(data.message || 'เกิดข้อผิดพลาดในการลบ');
            }
        })
        .catch(err => {
            console.error(err);
            alert('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
        });
    }
}
</script>
</body>
</html>