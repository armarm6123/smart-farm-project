<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once 'api/db_config.php'; 

// 🟢 อัปเดตตรรกะดีดีตามกำหนด: ถ้าผู้ใช้ล็อกอินอยู่แล้ว ให้ดีดไปหน้า user_home ทันที
if (isset($_SESSION['user_logged']) && $_SESSION['user_logged'] === true) {
    header("Location: user_home.php");
    exit();
}

$error = "";
$success = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $user = trim($_POST['username'] ?? '');
    $pass = trim($_POST['password'] ?? '');
    $confirm_pass = trim($_POST['confirm_password'] ?? '');

    if (empty($user) || empty($pass)) {
        $error = "กรุณากรอกข้อมูลให้ครบถ้วน";
    } elseif ($pass !== $confirm_pass) {
        $error = "รหัสผ่านและการยืนยันรหัสผ่านไม่ตรงกัน";
    } else {
        $check_sql = "SELECT id FROM users WHERE username = ?";
        $stmt = $conn->prepare($check_sql);
        $stmt->bind_param("s", $user);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $error = "ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว กรุณาเปลี่ยนใหม่";
            $stmt->close();
        } else {
            $stmt->close();

            // สุ่มสร้าง Token ID (5 หลัก) แบบไม่ซ้ำในระบบ
            $token_id = "";
            $is_unique = false;
            while (!$is_unique) {
                $token_id = (string)rand(10000, 99999);
                
                $token_check = "SELECT id FROM users WHERE token_id = ?";
                $t_stmt = $conn->prepare($token_check);
                $t_stmt->bind_param("s", $token_id);
                $t_stmt->execute();
                if ($t_stmt->get_result()->num_rows == 0) {
                    $is_unique = true;
                }
                $t_stmt->close();
            }

            $insert_sql = "INSERT INTO users (username, password, role, token_id) VALUES (?, ?, 'user', ?)";
            $ins_stmt = $conn->prepare($insert_sql);
            $ins_stmt->bind_param("sss", $user, $pass, $token_id);

            if ($ins_stmt->execute()) {
                $success = "สมัครสมาชิกสำเร็จ! กำลังพาท่านไปหน้าเข้าสู่ระบบ...";
                header("refresh:2; url=web_login.php");
            } else {
                $error = "เกิดข้อผิดพลาดในการบันทึกข้อมูล: " . $conn->error;
            }
            $ins_stmt->close();
        }
    }
}
?>

<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SMART FARM | สมัครสมาชิก</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        
        body { 
            font-family: 'Sarabun', sans-serif; 
            background: linear-gradient(180deg, #1b5e20 0%, #4caf50 100%); 
            min-height: 100vh; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            padding: 20px;
        }
        
        .brand-icon-container {
            background-color: rgba(255, 255, 255, 0.2);
            width: 120px;
            height: 120px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px auto;
        }

        .custom-card {
            background: white;
            border: none;
            border-radius: 30px;
            box-shadow: 0 10px 15px rgba(0,0,0,0.26);
            width: 100%;
            max-width: 400px;
        }

        .custom-input-group {
            background-color: #e8f5e9;
            border-radius: 15px;
            border: none;
            overflow: hidden;
        }
        .custom-input-group .input-group-text {
            background-color: transparent;
            border: none;
            color: #2e7d32;
            padding-left: 20px;
        }
        .custom-input-group .form-control {
            background-color: transparent;
            border: none;
            padding: 14px 20px 14px 10px;
            font-size: 16px;
            color: #1b5e20;
        }
        .custom-input-group .form-control:focus {
            box-shadow: none;
            background-color: transparent;
        }

        .btn-flutter {
            background-color: #2e7d32;
            color: white;
            border: none;
            border-radius: 15px;
            padding: 14px;
            font-size: 18px;
            font-weight: bold;
            transition: all 0.2s ease;
        }
        .btn-flutter:hover {
            background-color: #1b5e20;
            color: white;
        }

        .text-btn {
            color: #2e7d32;
            font-weight: bold;
            text-decoration: none;
            font-size: 15px;
        }
        .text-btn:hover {
            color: #1b5e20;
        }
    </style>
</head>
<body>

<div class="container-fluid text-center">
    <div class="brand-icon-container">
        <i class="bi bi-person-badge text-white" style="font-size: 60px;"></i>
    </div>
    <h1 class="text-white fw-bold mb-1" style="font-size: 32px; letter-spacing: 2px;">SIGN UP</h1>
    <p class="text-white-50 mb-4" style="font-size: 16px;">สร้างบัญชีผู้ใช้งานระบบฟาร์ม</p>

    <div class="card custom-card mx-auto p-4 p-md-5">
        <?php if(!empty($error)): ?>
            <div class="alert alert-danger border-0 rounded-3 small py-2 mb-3 text-center" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-1"></i> <?php echo $error; ?>
            </div>
        <?php endif; ?>

        <?php if(!empty($success)): ?>
            <div class="alert alert-success border-0 rounded-3 small py-2 mb-3 text-center" role="alert">
                <i class="bi bi-check-circle-fill me-1"></i> <?php echo $success; ?>
            </div>
        <?php endif; ?>

        <form method="POST" action="web_register.php">
            <div class="mb-3 text-start">
                <div class="input-group custom-input-group">
                    <span class="input-group-text"><i class="bi bi-person"></i></span>
                    <input type="text" name="username" class="form-control" placeholder="Username" required autocomplete="off">
                </div>
            </div>

            <div class="mb-3 text-start">
                <div class="input-group custom-input-group">
                    <span class="input-group-text"><i class="bi bi-lock"></i></span>
                    <input type="password" name="password" class="form-control" placeholder="Password" required>
                </div>
            </div>

            <div class="mb-4 text-start">
                <div class="input-group custom-input-group">
                    <span class="input-group-text"><i class="bi bi-shield-lock"></i></span>
                    <input type="password" name="confirm_password" class="form-control" placeholder="Confirm Password" required>
                </div>
            </div>

            <button type="submit" class="btn btn-flutter w-100 shadow-sm mb-3">
                ลงทะเบียนสมาชิก
            </button>

            <div class="mt-2">
                <a href="web_login.php" class="text-btn">มีบัญชีอยู่แล้ว? เข้าสู่ระบบที่นี่</a>
            </div>
        </form>
    </div>
</div>

</body>
</html>