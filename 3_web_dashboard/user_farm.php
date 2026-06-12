<?php
session_start();

// ตรวจสอบ Login ผู้ใช้งาน
if (!isset($_SESSION['user_logged'])) { 
    header("Location: web_login.php");
    exit();
}

require_once 'api/db_config.php';

$user_id = $_SESSION['user_id'];
$token_id = $_SESSION['token_id']; 

// ดึงค่า Serial Number จาก URL
$current_sn = isset($_GET['sn']) ? trim($_GET['sn']) : '';

// ตรวจความปลอดภัยของฟาร์ม
$farm_stmt = $conn->prepare("SELECT * FROM user_farms WHERE user_id = ? AND serial_number = ? LIMIT 1");
$farm_stmt->bind_param("ss", $user_id, $current_sn);
$farm_stmt->execute();
$farm_result = $farm_stmt->get_result();

if ($farm_result->num_rows == 0) {
    header("Location: user_home.php");
    exit();
}

$farm_data = $farm_result->fetch_assoc();
$farm_name = $farm_data['farm_name'];
$farm_stmt->close();
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartFarm | ควบคุม <?php echo htmlspecialchars($farm_name); ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <script src="https://cdn.jsdelivr.net/npm/mqtt/dist/mqtt.min.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        body { 
            font-family: 'Sarabun', sans-serif; 
            background-color: #f1f5f9; 
        }
        .navbar-custom {
            background-color: #198754;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }
        .card-panel {
            border: none;
            border-radius: 20px;
            background-color: white;
            box-shadow: 0 4px 20px rgba(0,0,0,0.02);
        }
        .sensor-val {
            font-size: 2.8rem;
            font-weight: 700;
        }
        .moisture-input {
            border: 1px solid #e2e8f0; border-radius: 12px;
            padding: 10px; text-align: center;
            font-weight: bold; font-size: 1.1rem; background-color: #f8fafc;
        }
        .moisture-input:focus { border-color: #198754; outline: none; background-color: white; }
    </style>
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-dark navbar-custom py-3">
    <div class="container">
        <a class="navbar-brand fw-bold fs-4" href="user_home.php"><i class="bi bi-leaf-fill me-2"></i>SmartFarm System</a>
        <div class="d-flex align-items-center text-white">
            <a href="user_home.php" class="btn btn-sm btn-light rounded-pill px-4 fw-bold text-success shadow-sm"><i class="bi bi-chevron-left me-1"></i> กลับหน้าหลัก</a>
        </div>
    </div>
</nav>

<div class="container my-5">
    <div class="card card-panel p-4 mb-4 bg-dark text-white border-0">
        <div class="row align-items-center">
            <div class="col-md-8">
                <h1 class="fw-bold mt-1 text-white mb-1"><?php echo htmlspecialchars($farm_name); ?></h1>
                <p class="m-0 text-white-50"><i class="bi bi-cpu-fill"></i> อุปกรณ์ Serial Number: <strong class="text-success"><?php echo $current_sn; ?></strong></p>
            </div>
            <div class="col-md-4 text-md-end mt-3 mt-md-0">
                <div class="p-2 px-3 rounded-pill d-inline-flex align-items-center text-start" id="mqtt-status-alert" style="background-color: rgba(255,255,255,0.1);">
                    <i class="bi bi-arrow-clockwise text-warning fs-4 me-2 animate-spin" id="status-icon"></i>
                    <div>
                        <small class="d-block text-white-50" style="font-size:10px;">เครือข่าย MQTT</small>
                        <strong class="small" id="status-title">กำลังเชื่อมต่อ...</strong>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-lg-8">
            <div class="row g-3">
                <div class="col-sm-6">
                    <div class="card card-panel p-4 text-center border-bottom border-success border-4">
                        <div class="text-success mb-2"><i class="bi bi-droplet-half fs-1"></i></div>
                        <h6 class="text-muted fw-bold mb-1">ความชื้นในดิน</h6>
                        <div class="sensor-val text-success" id="soil-moisture-val">--<span class="fs-4">%</span></div>
                    </div>
                </div>
                <div class="col-sm-6">
                    <div class="card card-panel p-4 text-center border-bottom border-warning border-4">
                        <div class="text-warning mb-2"><i class="bi bi-thermometer-half fs-1"></i></div>
                        <h6 class="text-muted fw-bold mb-1">อุณหภูมิอากาศ</h6>
                        <div class="sensor-val text-warning" id="temp-val">--<span class="fs-4">°C</span></div>
                    </div>
                </div>
                <div class="col-sm-6">
                    <div class="card card-panel p-4 text-center border-bottom border-info border-4">
                        <div class="text-info mb-2"><i class="bi bi-cloud-sun fs-1"></i></div>
                        <h6 class="text-muted fw-bold mb-1">ความชื้นอากาศ</h6>
                        <div class="sensor-val text-info" id="humi-val">--<span class="fs-4">%</span></div>
                    </div>
                </div>
                <div class="col-sm-6">
                    <div class="card card-panel p-4 text-center border-bottom border-primary border-4" id="pump-card-bg">
                        <div class="text-primary mb-2" id="pump-icon-color"><i class="bi bi-water fs-1"></i></div>
                        <h6 class="text-muted fw-bold mb-1">สถานะระบบปั๊มน้ำ</h6>
                        <div class="sensor-val text-secondary" id="pump-status-val" style="font-size: 2.2rem; padding: 5px 0;">ปิดอยู่</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card card-panel p-4 mb-4">
                <h5 class="fw-bold mb-3 text-dark">แผงสวิตช์ควบคุมระบบ</h5>
                
                <div class="d-flex align-items-center justify-content-between mb-3 p-3 bg-light rounded-3">
                    <div class="d-flex align-items-center">
                        <i class="bi bi-lightbulb-fill fs-4 text-warning me-3"></i>
                        <span class="fw-bold text-dark">เปิดระบบหลอดไฟฟาร์ม</span>
                    </div>
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input fs-4" type="checkbox" role="switch" id="manualLightSwitch" onchange="publishManualControl('light')">
                    </div>
                </div>
                
                <div class="d-flex align-items-center justify-content-between p-3 bg-light rounded-3">
                    <div class="d-flex align-items-center">
                        <i class="bi bi-droplet-fill fs-4 text-primary me-3"></i>
                        <span class="fw-bold text-dark" id="pump-hint-text">เปิดปั๊มน้ำด้วยตนเอง</span>
                    </div>
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input fs-4" type="checkbox" role="switch" id="manualPumpSwitch" onchange="publishManualControl('pump')">
                    </div>
                </div>
            </div>

            <div class="card card-panel p-4 mb-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <h5 class="fw-bold m-0 text-dark">ควบคุมน้ำอัตโนมัติ</h5>
                        <small class="text-muted" id="auto-mode-hint">บอร์ดตัดสินใจเปิด-ปิดปั๊มน้ำเอง</small>
                    </div>
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input fs-3" type="checkbox" role="switch" id="autoModeSwitch" onchange="toggleAutoMode()">
                    </div>
                </div>
                
                <div class="row g-2 mt-2">
                    <div class="col-6">
                        <label class="form-label text-muted small fw-bold mb-1">ความชื้นต่ำสุด %</label>
                        <input type="number" class="w-100 moisture-input" id="soilLowInput" placeholder="รอค่า..." oninput="saveInputsRealtime()">
                    </div>
                    <div class="col-6">
                        <label class="form-label text-muted small fw-bold mb-1">ความชื้นสูงสุด %</label>
                        <input type="number" class="w-100 moisture-input" id="soilHighInput" placeholder="รอค่า..." oninput="saveInputsRealtime()">
                    </div>
                </div>
            </div>

            <a href="user_history.php?sn=<?php echo $current_sn; ?>" class="btn btn-outline-success btn-lg w-100 rounded-pill py-3 fw-bold shadow-sm bg-white border-2">
                <i class="bi bi-clock-history me-2"></i> ดูสถิติประวัติย้อนหลัง (History)
            </a>
        </div>
    </div>
</div>

<script>
const userToken = "<?php echo $token_id; ?>"; 
const currentSN = "<?php echo $current_sn; ?>";
let isAutoMode = false;

const statusTopic = `user/${userToken}/farm/${currentSN}/status`;
const controlTopic = `user/${userToken}/farm/${currentSN}/control`;

const brokerUrl = 'ws://172.20.10.4:9001'; 
const options = {
    clientId: 'web_desktop_' + Math.random().toString(16).substr(2, 8),
    keepalive: 60
};

const client = mqtt.connect(brokerUrl, options);

client.on('connect', () => {
    updateConnectionStatus(true);
    client.subscribe(statusTopic);
});

client.on('close', () => {
    updateConnectionStatus(false);
});

client.on('message', (topic, message) => {
    try {
        const payload = JSON.parse(message.toString());
        
        if (topic === statusTopic) {
            // ดึงสถานะโหมด Auto ล่าสุดก่อนทำงานส่วนอื่น
            if (payload.auto_mode !== undefined) {
                isAutoMode = (payload.auto_mode === true || payload.auto_mode === 1);
            }

            // 1. อัปเดตค่า Sensor
            document.getElementById('soil-moisture-val').innerHTML = `${Math.round(payload.soil_moisture)}<span class="fs-4">%</span>`;
            document.getElementById('temp-val').innerHTML = `${payload.temp.toFixed(1)}<span class="fs-4">°C</span>`;
            document.getElementById('humi-val').innerHTML = `${payload.humi.toFixed(1)}<span class="fs-4">%</span>`;
            
            // 2. อัปเดตสถานะการทำงานจริงของปั๊มน้ำ (แสดงผลบนแผงการ์ดทางซ้าย)
            const pumpStatus = (payload.pump === true || payload.pump === 1);
            const pumpCard = document.getElementById('pump-card-bg');
            const pumpTxt = document.getElementById('pump-status-val');
            
            if (pumpStatus) {
                pumpCard.style.backgroundColor = '#e0f2fe';
                pumpTxt.innerText = 'กำลังทำงาน';
                pumpTxt.style.color = '#0284c7';
            } else {
                pumpCard.style.backgroundColor = 'white';
                pumpTxt.innerText = 'ปิดอยู่';
                pumpTxt.style.color = '#64748b';
            }

            // 🟢 3. อัปเดตตัวปุ่มสวิตช์เปิดปิดด้วยตนเอง (Manual Switch)
            // ปรับปรุงใหม่: ถ้าอยู่ในโหมด Auto ตัวสวิตช์นี้จะถูกล็อกให้นิ่งสนิท ไม่เคลี่อนไหวตามบอร์ด
            if (!isAutoMode) {
                document.getElementById('manualPumpSwitch').checked = pumpStatus;
            }

            // 4. อัปเดตสถานะไฟ
            document.getElementById('manualLightSwitch').checked = payload.light;
            
            // 5. อัปเดตหน้าตา UI ของระบบ Auto
            document.getElementById('autoModeSwitch').checked = isAutoMode;
            toggleInputsAndButtons(isAutoMode);

            // ดึงค่าจำกัดความชื้นจากบอร์ด
            if (document.activeElement !== document.getElementById('soilLowInput') && payload.soil_low !== undefined) {
                document.getElementById('soilLowInput').value = payload.soil_low === -1 ? '' : payload.soil_low;
            }
            if (document.activeElement !== document.getElementById('soilHighInput') && payload.soil_high !== undefined) {
                document.getElementById('soilHighInput').value = payload.soil_high === -1 ? '' : payload.soil_high;
            }
        }
    } catch (e) {
        console.error("MQTT Payload error", e);
    }
});

function toggleAutoMode() {
    const switchBtn = document.getElementById('autoModeSwitch');
    const lowVal = document.getElementById('soilLowInput').value;
    const highVal = document.getElementById('soilHighInput').value;

    if (switchBtn.checked && (lowVal === '' || highVal === '')) {
        alert("⚠️ กรุณากรอกเงื่อนไขความชื้นต่ำสุดและสูงสุดก่อนเปิดใช้งานระบบออโต้!");
        switchBtn.checked = false;
        return;
    }

    isAutoMode = switchBtn.checked;
    
    // 🟢 เมื่อสับสวิตช์ปิด Auto ให้เซ็ตปุ่มสวิตช์ Manual บนเว็บคืนค่ากลับเป็น "ปิด" (False) สแตนบายรอทันที
    if (!isAutoMode) {
        document.getElementById('manualPumpSwitch').checked = false;
    }

    toggleInputsAndButtons(isAutoMode);
    sendConfigurationToESP32();
}

function saveInputsRealtime() {
    sendConfigurationToESP32();
}

function sendConfigurationToESP32() {
    const lowVal = document.getElementById('soilLowInput').value;
    const highVal = document.getElementById('soilHighInput').value;
    const manualPump = document.getElementById('manualPumpSwitch').checked;

    const message = JSON.stringify({
        auto_mode: isAutoMode,
        soil_low: lowVal !== '' ? parseInt(lowVal) : -1,
        soil_high: highVal !== '' ? parseInt(highVal) : -1,
        // ถ้าปิดออโต้ บังคับส่งค่า 0 ไปสั่งหยุดปั๊มที่ค้างอยู่ในบอร์ดทันที
        pump: isAutoMode ? (manualPump ? 1 : 0) : 0 
    });

    client.publish(controlTopic, message, { qos: 1 });
}

function publishManualControl(device) {
    let message = {};
    if (device === 'pump') {
        message = { 
            pump: document.getElementById('manualPumpSwitch').checked ? 1 : 0,
            auto_mode: false 
        };
        isAutoMode = false;
        toggleInputsAndButtons(false);
    } else if (device === 'light') {
        message = { light: document.getElementById('manualLightSwitch').checked ? 1 : 0 };
    }

    client.publish(controlTopic, JSON.stringify(message), { qos: 1 });
}

function toggleInputsAndButtons(disabled) {
    document.getElementById('soilLowInput').disabled = disabled;
    document.getElementById('soilHighInput').disabled = disabled;
    
    // จัดการล็อกตัวปุ่มสวิตช์ปั๊มน้ำแมนนวล
    const manualPumpSwitch = document.getElementById('manualPumpSwitch');
    manualPumpSwitch.disabled = disabled;

    const hintText = document.getElementById('pump-hint-text');
    if (disabled) {
        hintText.innerHTML = "เปิดปั๊มน้ำด้วยตนเอง <span class='text-danger small d-block' style='font-size: 11px;'>🔴 ระบบอัตโนมัติกำลังทำงาน</span>";
    } else {
        hintText.innerHTML = "เปิดปั๊มน้ำด้วยตนเอง";
    }
}

function updateConnectionStatus(isConnected) {
    const alertBox = document.getElementById('mqtt-status-alert');
    const icon = document.getElementById('status-icon');
    const title = document.getElementById('status-title');

    if (isConnected) {
        alertBox.style.backgroundColor = "rgba(25, 135, 84, 0.2)";
        icon.className = "bi bi-check-circle-fill text-success fs-4 me-2";
        title.innerText = "เชื่อมต่อสำเร็จ (LIVE)";
        title.className = "small text-success";
    } else {
        alertBox.style.backgroundColor = "rgba(255, 193, 7, 0.1)";
        icon.className = "bi bi-arrow-clockwise text-warning fs-4 me-2 animate-spin";
        title.innerText = "กำลังเชื่อมต่อเซิร์ฟเวอร์...";
        title.className = "small text-warning";
    }
}
</script>
</body>
</html>