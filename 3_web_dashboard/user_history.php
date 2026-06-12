<?php
session_start();

// ตรวจสอบ Login ผู้ใช้งาน
if (!isset($_SESSION['user_logged'])) { 
    header("Location: web_login.php");
    exit();
}

require_once 'api/db_config.php';

$user_id = $_SESSION['user_id'];
$current_sn = isset($_GET['sn']) ? trim($_GET['sn']) : '';

// ตรวจความปลอดภัย: บอร์ดนี้ต้องเป็นของ User คนนี้จริงๆ
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
    <title>SmartFarm | ประวัติย้อนหลัง <?php echo htmlspecialchars($farm_name); ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
        .filter-banner {
            background-color: #115e59;
            color: white;
            border-radius: 0 0 20px 20px;
        }
        .card-custom {
            border: none;
            border-radius: 20px;
            background-color: white;
            box-shadow: 0 4px 20px rgba(0,0,0,0.04);
        }
        .btn-period {
            border: 1px solid #e2e8f0;
            background: white;
            color: #64748b;
            font-size: 0.85rem;
            padding: 8px 16px;
            border-radius: 10px;
            transition: all 0.2s;
        }
        .btn-period.active {
            background-color: #d1fae5;
            color: #065f46;
            border-color: #a7f3d0;
            font-weight: bold;
        }
        .table-responsive {
            border-radius: 12px;
            overflow: hidden;
        }
        .badge-sensor {
            font-size: 0.85rem;
            padding: 6px 12px;
            border-radius: 8px;
        }
    </style>
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-dark navbar-custom py-3">
    <div class="container">
        <a class="navbar-brand fw-bold fs-4" href="user_home.php"><i class="bi bi-leaf-fill me-2"></i>SmartFarm System</a>
        <div class="d-flex align-items-center">
            <a href="user_farm.php?sn=<?php echo $current_sn; ?>" class="btn btn-sm btn-light rounded-pill px-4 fw-bold text-success shadow-sm">
                <i class="bi bi-chevron-left me-1"></i> กลับหน้าควบคุมบอร์ด
            </a>
        </div>
    </div>
</nav>

<div class="filter-banner py-4 px-3 mb-4">
    <div class="container">
        <div class="row align-items-center g-3">
            <div class="col-md-6">
                <h2 class="fw-bold m-0"><?php echo htmlspecialchars($farm_name); ?></h2>
                <small class="opacity-50">S/N: <?php echo $current_sn; ?></small>
            </div>
            <div class="col-md-6">
                <form id="filterForm" class="row g-2 justify-content-md-end" onsubmit="event.preventDefault(); fetchHistory();">
                    <div class="col-6 col-sm-5 col-md-4">
                        <label class="form-label small opacity-75 mb-1">วันที่เริ่มต้น</label>
                        <input type="date" id="startDate" class="form-control form-control-sm border-0 rounded-3 shadow-none text-center" onchange="changeCustomDate()">
                    </div>
                    <div class="col-6 col-sm-5 col-md-4">
                        <label class="form-label small opacity-75 mb-1">วันที่สิ้นสุด</label>
                        <input type="date" id="endDate" class="form-control form-control-sm border-0 rounded-3 shadow-none text-center" onchange="changeCustomDate()">
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="container pb-5">
    <div class="row g-4">
        <div class="col-lg-12">
            <div class="card card-custom p-4 mb-4">
                <div class="d-flex flex-column flex-sm-row justify-content-between align-items-start align-items-sm-center gap-3 mb-4">
                    
                    <div class="d-flex flex-wrap gap-3">
                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="checkbox" id="chkTemp" checked onchange="updateChartVisibility()">
                            <label class="form-check-label small fw-bold text-warning" for="chkTemp"><i class="bi bi-thermometer-half"></i> อุณหภูมิ (°C)</label>
                        </div>
                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="checkbox" id="chkHumi" checked onchange="updateChartVisibility()">
                            <label class="form-check-label small fw-bold text-primary" for="chkHumi"><i class="bi bi-cloud-sun"></i> ความชื้นอากาศ (%)</label>
                        </div>
                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="checkbox" id="chkSoil" checked onchange="updateChartVisibility()">
                            <label class="form-check-label small fw-bold text-success" for="chkSoil"><i class="bi bi-droplet-half"></i> ความชื้นในดิน (%)</label>
                        </div>
                    </div>

                    <div class="bg-light p-1 rounded-3 d-inline-flex">
                        <button class="btn btn-sm btn-white text-success shadow-sm px-3" id="btnLineChart" onclick="switchChartType('line')">
                            <i class="bi bi-show-chart me-1"></i> กราฟเส้น
                        </button>
                        <button class="btn btn-sm text-secondary px-3" id="btnBarChart" onclick="switchChartType('bar')">
                            <i class="bi bi-bar-chart me-1"></i> กราฟแท่ง
                        </button>
                    </div>
                </div>

                <div style="position: relative; height:350px; width:100%;">
                    <div id="chartLoading" class="position-absolute top-50 start-50 translate-middle text-center d-none">
                        <div class="spinner-border text-success" role="status"></div>
                        <p class="text-muted small mt-2">กำลังดึงฐานข้อมูลประวัติ...</p>
                    </div>
                    <div id="chartEmpty" class="position-absolute top-50 start-50 translate-middle text-center d-none">
                        <i class="bi bi-file-earmark-bar-graph text-muted fs-1"></i>
                        <p class="text-muted small m-0">ไม่มีข้อมูลบันทึกในช่วงเวลาที่เลือก</p>
                    </div>
                    <canvas id="historyChart"></canvas>
                </div>

                <hr class="my-4 text-black-50">

                <div class="d-flex flex-wrap gap-2 justify-content-center justify-content-sm-start">
                    <button class="btn-period active" id="p_Today" onclick="updatePeriod('Today')">วันนี้</button>
                    <button class="btn-period" id="p_1W" onclick="updatePeriod('1W')">1 สัปดาห์</button>
                    <button class="btn-period" id="p_1M" onclick="updatePeriod('1M')">1 เดือน</button>
                    <button class="btn-period" id="p_3M" onclick="updatePeriod('3M')">3 เดือน</button>
                </div>
            </div>

            <div class="card card-custom p-4">
                <h5 class="fw-bold mb-3 text-dark"><i class="bi bi-list-ul text-success me-2"></i>ประวัติรายการบันทึกย้อนหลัง <span id="logCount" class="badge bg-secondary-subtle text-secondary rounded-pill fs-6 ms-1">0</span></h5>
                
                <div class="table-responsive">
                    <table class="table table-hover align-middle m-0 bg-white">
                        <thead class="table-light text-secondary small">
                            <tr>
                                <th>เวลาบันทึก</th>
                                <th class="text-center">อุณหภูมิอากาศ</th>
                                <th class="text-center">ความชื้นอากาศ</th>
                                <th class="text-center">ความชื้นดิน</th>
                                <th class="text-center">ระบบปั๊มน้ำ</th>
                                <th class="text-center">หลอดไฟฟาร์ม</th>
                            </tr>
                        </thead>
                        <tbody id="dataTableBody" class="small">
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
const currentSN = "<?php echo $current_sn; ?>";
let historyChart = null;
let currentChartType = 'line'; 
let rawLogsData = []; 

window.addEventListener('DOMContentLoaded', () => {
    updatePeriod('Today');
});

function updatePeriod(period) {
    document.querySelectorAll('.btn-period').forEach(btn => btn.classList.remove('active'));
    const targetButton = document.getElementById(`p_${period}`);
    if (targetButton) targetButton.classList.add('active');

    const now = new Date();
    let startDate = new Date();

    if (period === 'Today') {
        startDate.setHours(0,0,0,0);
    } else if (period === '1W') {
        startDate.setDate(now.getDate() - 7);
    } else if (period === '1M') {
        startDate.setDate(now.getDate() - 30);
    } else if (period === '3M') {
        startDate.setDate(now.getDate() - 90);
    }

    const formatDateLocal = (dateObj) => {
        const offset = dateObj.getTimezoneOffset();
        const localDate = new Date(dateObj.getTime() - (offset * 60 * 1000));
        return localDate.toISOString().split('T')[0];
    };

    document.getElementById('startDate').value = formatDateLocal(startDate);
    document.getElementById('endDate').value = formatDateLocal(now);

    fetchHistory();
}

function changeCustomDate() {
    document.querySelectorAll('.btn-period').forEach(btn => btn.classList.remove('active'));
    fetchHistory();
}

async function fetchHistory() {
    const sDate = document.getElementById('startDate').value;
    const eDate = document.getElementById('endDate').value;
    
    const loadingEl = document.getElementById('chartLoading');
    const emptyEl = document.getElementById('chartEmpty');
    
    loadingEl.classList.remove('d-none');
    emptyEl.classList.add('d-none');
    
    // ยิงไปที่ API ตัวจริงที่คุณส่งมา
    const apiUrl = `api/get_history.php?serial_number=${currentSN}&start=${sDate}&end=${eDate}`;
    
    try {
        const response = await fetch(apiUrl);
        if (response.ok) {
            rawLogsData = await response.json();
            document.getElementById('logCount').innerText = rawLogsData.length;
            renderChart();
            renderTable();
        }
    } catch (error) {
        console.error("Fetch history failed", error);
    } finally {
        loadingEl.classList.add('d-none');
    }
}

function renderChart() {
    const emptyEl = document.getElementById('chartEmpty');
    if (rawLogsData.length === 0) {
        emptyEl.classList.remove('d-none');
        if (historyChart) historyChart.destroy();
        return;
    }
    emptyEl.classList.add('d-none');

    // 🟢 ยิงค่า log.time ที่มาจาก API ตรงๆ (เพราะ API จัดการตัดแบ่งโหมดมาให้จากหลังบ้านเรียบร้อยแล้ว)
    const labels = rawLogsData.map(log => log.time);
    const tempData = rawLogsData.map(log => log.temp);
    const humiData = rawLogsData.map(log => log.humi);
    const soilData = rawLogsData.map(log => log.soil);

    const chartData = {
        labels: labels,
        datasets: [
            {
                label: 'อุณหภูมิอากาศ (°C)',
                data: tempData,
                borderColor: '#f97316',
                backgroundColor: currentChartType === 'bar' ? '#f97316' : 'rgba(249, 115, 22, 0.1)',
                borderWidth: 2,
                hidden: !document.getElementById('chkTemp').checked,
                tension: 0.3
            },
            {
                label: 'ความชื้นอากาศ (%)',
                data: humiData,
                borderColor: '#3b82f6',
                backgroundColor: currentChartType === 'bar' ? '#3b82f6' : 'rgba(59, 130, 246, 0.1)',
                borderWidth: 2,
                hidden: !document.getElementById('chkHumi').checked,
                tension: 0.3
            },
            {
                label: 'ความชื้นในดิน (%)',
                data: soilData,
                borderColor: '#10b981',
                backgroundColor: currentChartType === 'bar' ? '#10b981' : 'rgba(16, 185, 129, 0.1)',
                borderWidth: 2,
                hidden: !document.getElementById('chkSoil').checked,
                tension: 0.3
            }
        ]
    };

    if (historyChart) {
        historyChart.destroy(); 
    }

    const ctx = document.getElementById('historyChart').getContext('2d');
    historyChart = new Chart(ctx, {
        type: currentChartType,
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false } 
            },
            scales: {
                y: {
                    min: 0,
                    max: 100,
                    ticks: { stepSize: 20 }
                },
                x: {
                    grid: { display: false }
                }
            }
        }
    });
}

function switchChartType(type) {
    currentChartType = type;
    
    const btnLine = document.getElementById('btnLineChart');
    const btnBar = document.getElementById('btnBarChart');
    
    if(type === 'line') {
        btnLine.className = "btn btn-sm btn-white text-success shadow-sm px-3";
        btnBar.className = "btn btn-sm text-secondary px-3";
    } else {
        btnBar.className = "btn btn-sm btn-white text-success shadow-sm px-3";
        btnLine.className = "btn btn-sm text-secondary px-3";
    }
    renderChart();
}

function updateChartVisibility() {
    if (historyChart) {
        historyChart.setDatasetVisibility(0, document.getElementById('chkTemp').checked);
        historyChart.setDatasetVisibility(1, document.getElementById('chkHumi').checked);
        historyChart.setDatasetVisibility(2, document.getElementById('chkSoil').checked);
        historyChart.update();
    }
}

function renderTable() {
    const tbody = document.getElementById('dataTableBody');
    tbody.innerHTML = '';

    if (rawLogsData.length === 0) {
        tbody.innerHTML = `<tr><td colspan="6" class="text-center py-4 text-muted">ไม่พบข้อมูลประวัติในช่วงเวลาดังกล่าว</td></tr>`;
        return;
    }

    const sDate = document.getElementById('startDate').value;
    const eDate = document.getElementById('endDate').value;
    const isSingleDay = (sDate === eDate);

    rawLogsData.forEach(log => {
        const tr = document.createElement('tr');
        const pumpOn = (log.pump == 1 || log.pump == true);
        const lightOn = (log.light == 1 || log.light == true);

        // 🟢 ปรับตรงนี้: ถ้าสัญญานเวลามาแค่ H:i:s ให้แปะวันที่จากปฏิทินนำหน้า เพื่อให้ตารางรายงานดูสมบูรณ์เข้าใจง่าย
        const displayTime = isSingleDay ? `${sDate} ${log.time}` : log.time;

        tr.innerHTML = `
            <td class="fw-bold">${displayTime}</td>
            <td class="text-center text-warning fw-semibold">${log.temp}°C</td>
            <td class="text-center text-primary fw-semibold">${log.humi}%</td>
            <td class="text-center text-success fw-semibold">${log.soil}%</td>
            <td class="text-center">
                ${pumpOn ? '<span class="badge bg-info-subtle text-info badge-sensor"><i class="bi bi-water"></i> ทำงาน</span>' : '<span class="badge bg-light text-secondary badge-sensor">ปิด</span>'}
            </td>
            <td class="text-center">
                ${lightOn ? '<span class="badge bg-warning-subtle text-warning badge-sensor"><i class="bi bi-lightbulb-fill"></i> เปิด</span>' : '<span class="badge bg-light text-secondary badge-sensor">ปิด</span>'}
            </td>
        `;
        tbody.appendChild(tr);
    });
}
</script>
</body>
</html>