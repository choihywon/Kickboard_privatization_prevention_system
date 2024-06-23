<?php
// 데이터베이스 연결 및 기타 설정
$host = 'localhost';
$db_user = 'root';
$db_password = '1220';
$db_name = 'mydb';

$conn = new mysqli($host, $db_user, $db_password, $db_name);

if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}

function getNextLogId($conn) {
    $result = $conn->query("SELECT MAX(log_id) as max_log_id FROM user_log");
    if ($row = $result->fetch_assoc()) {
        $maxId = $row['max_log_id'];
        $number = intval(substr($maxId, 1)) + 1; // Increment the number part
        return 'L' . str_pad($number, 4, '0', STR_PAD_LEFT);
    } else {
        return 'L0001'; // Default starting value
    }
}

function getTotalUsageTime($conn, $user_id, $kickboard_id) {
    $sql = "SELECT SUM(TIMESTAMPDIFF(MINUTE, start_time, end_time)) as total_time FROM user_log WHERE user_id = ? AND kickboard_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $user_id, $kickboard_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    return $row['total_time'];
}

function getUsageCount($conn, $user_id, $kickboard_id) {
    $sql = "SELECT COUNT(*) as usage_count FROM user_log WHERE user_id = ? AND kickboard_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $user_id, $kickboard_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    return $row['usage_count'];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_id = $_POST['user_id'];
    $start_time = $_POST['start_time'];
    $end_time = $_POST['end_time'];
    $kickboard_id = $_POST['kickboard_id'];

    // Generate next log_id
    $log_id = getNextLogId($conn);

    // user_log 테이블에 기록하는 쿼리
    $sql = "INSERT INTO user_log (log_id, user_id, kickboard_id, start_time, end_time) VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sssss", $log_id, $user_id, $kickboard_id, $start_time, $end_time);

    if ($stmt->execute()) {
        echo "User log recorded successfully";

        // 조건 검사 및 status 업데이트
            // 조건 검사 및 status 업데이트
        $totalUsageTime = getTotalUsageTime($conn, $user_id, $kickboard_id);
        $usageCount = getUsageCount($conn, $user_id, $kickboard_id);

        if ($usageCount >= 5 && $totalUsageTime <= 30) {
            $updateSql = "UPDATE user SET status = 'stop' WHERE user_id = ?";
            $updateStmt = $conn->prepare($updateSql);
            $updateStmt->bind_param("s", $user_id);
            if ($updateStmt->execute()) {
                echo "User status updated to 'inaccessible'\n";
            } else {
                echo "Error updating user status: " . $updateStmt->error;
            }
            $updateStmt->close();
        }
        else if ($usageCount >= 3 && $totalUsageTime <= 30) {
            // 'warning' 상태로 업데이트
            $updateSql = "UPDATE user SET status = 'warning' WHERE user_id = ?";
            $updateStmt = $conn->prepare($updateSql);
            $updateStmt->bind_param("s", $user_id);
            if ($updateStmt->execute()) {
                echo "User status updated to 'warning'\n"; // 메시지를 'warning'으로 변경
            } else {
                echo "Error updating user status: " . $updateStmt->error;
            }
            $updateStmt->close();
        }

    } else {
        echo "Error: " . $stmt->error;
    }

    $stmt->close();
    $conn->close();
}
?>