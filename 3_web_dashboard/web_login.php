<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once 'api/db_config.php'; 

// จัดการระบบ Logout
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    $_SESSION = array();
    session_destroy();
    header("Location: web_login.php");
    exit();
}

// เช็กสถานะล็อกอินค้าง
if (isset($_SESSION['user_logged']) && $_SESSION['user_logged'] === true) {
    header("Location: user_home.php");
    exit();
}
if (isset($_SESSION['admin_logged']) && $_SESSION['admin_logged'] === true) {
    header("Location: admin_home.php"); 
    exit();
}

$error = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $user = $_POST['username'] ?? '';
    $pass = $_POST['password'] ?? '';

    $sql = "SELECT id, username, role, token_id FROM users WHERE username = ? AND password = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $user, $pass);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        
        if (($row['role'] ?? 'user') === 'admin') {
            $_SESSION['admin_logged'] = true;
            $_SESSION['admin_id'] = $row['id'];
            $_SESSION['admin_user'] = $row['username'];
            $_SESSION['user_role'] = 'admin';
            
            if (!isset($_POST['is_api'])) {
                header("Location: admin_home.php"); 
                exit();
            }
        } else {
            $_SESSION['user_logged'] = true;
            $_SESSION['user_id'] = $row['id'];
            $_SESSION['user_user'] = $row['username'];
            $_SESSION['user_role'] = 'user';
            $_SESSION['token_id'] = $row['token_id']; 
            
            if (!isset($_POST['is_api'])) {
                header("Location: user_home.php");
                exit();
            }
        }

        header("Content-Type: application/json");
        header("Access-Control-Allow-Origin: *");
        echo json_encode([
            "status" => "success",
            "user_id" => $row['id'],
            "token_id" => $row['token_id'],
            "name" => $row['username'],
            "role" => $row['role']
        ]);
        exit();

    } else {
        if (!isset($_POST['is_api'])) {
            $error = "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง";
        } else {
            header("Content-Type: application/json");
            header("Access-Control-Allow-Origin: *");
            echo json_encode(["status" => "error", "message" => "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"]);
            exit();
        }
    }
    $stmt->close();
}
?>

<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SMART FARM | เข้าสู่ระบบ</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        
        body { 
            font-family: 'Sarabun', sans-serif; 
            /* ไล่เฉดสีสไตล์เดียวกับไลเนอร์ใน Flutter Container ของคุณ */
            background: linear-gradient(180deg, #1b5e20 0%, #4caf50 100%); 
            min-height: 100vh; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            padding: 20px;
        }
        
        /* วงกลมไอคอนด้านบนเลียนแบบ BoxShape.circle ใน Flutter */
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

        /* กล่องสีขาวมุมโค้งมน 30px และเงาแบบเดียวกับในโค้ดแอป */
        .custom-card {
            background: white;
            border: none;
            border-radius: 30px;
            box-shadow: 0 10px 15px rgba(0,0,0,0.26);
            width: 100%;
            max-width: 400px;
        }

        /* ฟิลด์กรอกข้อมูลสไตล์ InputDecoration Filled สีเขียวอ่อน */
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

        /* ปุ่มหลักทรงมนยืดตามความกว้างสไตล์ ElevatedButton */
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

        /* ลิงก์ TextButton */
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
        <i class="bi bi-flower1 text-white" style="font-size: 60px;"></i>
    </div>
    <h1 class="text-white fw-bold mb-1" style="font-size: 32px; letter-spacing: 2px;">SMART FARM</h1>
    <p class="text-white-50 mb-4" style="font-size: 16px;">ระบบจัดการฟาร์มอัจฉริยะ</p>

    <div class="card custom-card mx-auto p-4 p-md-5">
        <?php if(!empty($error)): ?>
            <div class="alert alert-danger border-0 rounded-3 small py-2 mb-3 text-center" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-1"></i> <?php echo $error; ?>
            </div>
        <?php endif; ?>

        <form method="POST" action="web_login.php">
            <div class="mb-3 text-start">
                <div class="input-group custom-input-group">
                    <span class="input-group-text"><i class="bi bi-person"></i></span>
                    <input type="text" name="username" class="form-control" placeholder="Username" required autocomplete="off">
                </div>
            </div>

            <div class="mb-4 text-start">
                <div class="input-group custom-input-group">
                    <span class="input-group-text"><i class="bi bi-lock"></i></span>
                    <input type="password" name="password" class="form-control" placeholder="Password" required>
                </div>
            </div>

            <button type="submit" class="btn btn-flutter w-100 shadow-sm mb-3">
                เข้าสู่ระบบ
            </button>

            <div class="mt-2">
                <a href="web_register.php" class="text-btn">ยังไม่มีบัญชี? สมัครสมาชิกที่นี่</a>
            </div>
        </form>
    </div>
</div>

</body>
</html>