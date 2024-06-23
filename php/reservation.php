<?php
$host = 'localhost';
$db_user = 'root';
$db_password = '1220';
$db_name = 'mydb';

$conn = new mysqli($host, $db_user, $db_password, $db_name);

if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}

// POST 데이터 존재 여부 확인
if (empty($_POST['user_id']) || empty($_POST['kickboard_id'])) {
    echo "Missing or invalid user_id or kickboard_id";
    exit;
}

$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : '';
$kickboard_id = isset($_POST['kickboard_id']) ? $_POST['kickboard_id'] : '';
$start_time = date('Y-m-d H:i:s');
$status = 'reserved';

$reservation_id = create_short_reservation_id($conn);

if (!checkKickboardUsage($conn, $user_id, $kickboard_id)) {
    // 특정 조건을 충족하는 경우, 사용자의 status를 'inaccessible'로 업데이트
    updateReservationStatus($user_id);
    echo "Cannot reserve: Usage limit exceeded";
    exit;
}

$sql = "INSERT INTO reservation (reservation_id, user_id, kickboard_id, start_time, status) VALUES (?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo "Error preparing statement: " . $conn->error;
    exit;
}

$stmt->bind_param("sssss", $reservation_id, $user_id, $kickboard_id, $start_time, $status);

if ($stmt->execute()) {
    echo "Reservation successful";
    updateKickboardStatus($conn, $kickboard_id, $status); // 킥보드 상태 업데이트 함수 호출
} else {
    echo "Error: " . $stmt->error;
}

$stmt->close();
$conn->close();

function create_short_reservation_id($conn) {
    $date = new DateTime();
    $timestamp = $date->getTimestamp();
    return "res" . substr($timestamp, -5); // 마지막 5자리만 사용
}

function updateKickboardStatus($conn, $kickboard_id, $status) {
    $sql = "UPDATE kickboard SET status = ? WHERE kickboard_id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo "Error preparing statement: " . $conn->error;
        return;
    }
    $stmt->bind_param("ss", $status, $kickboard_id);
    if (!$stmt->execute()) {
        echo "Error updating kickboard status: " . $stmt->error;
    }
    $stmt->close();
}

function checkKickboardUsage($conn, $user_id, $kickboard_id) {
    // SQL query to count the number of uses and calculate total duration
    $sql = "SELECT COUNT(*) AS use_count, SUM(TIMESTAMPDIFF(MINUTE, start_time, end_time)) AS total_duration 
            FROM user_log 
            WHERE user_id = ? 
            AND kickboard_id = ? 
            AND start_time >= NOW() - INTERVAL 30 MINUTE";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $user_id, $kickboard_id);
    $stmt->execute();
    
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    
    // Check if the conditions are met
    if ($row['use_count'] >= 5 && $row['total_duration'] <= 30) {
        return false; // Conditions met, don't allow reservation
    } else {
        return true; // Conditions not met, allow reservation
    }
}


// 사용자의 예약 가능 여부를 업데이트하는 함수
function updateReservationStatus($user_id) {
    global $conn;

    $sql = "UPDATE user SET status = 'inaccessible' WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $user_id);
    $stmt->execute();
    $stmt->close();
}


?>