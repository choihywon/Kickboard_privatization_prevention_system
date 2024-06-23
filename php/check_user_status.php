<?php
// 사용자 ID를 받아 사용자의 상태를 반환하는 API

// 데이터베이스 연결 설정
$host = 'localhost';
$db_user = 'root';
$db_password = '1220';
$db_name = 'mydb';

$conn = new mysqli($host, $db_user, $db_password, $db_name);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_id = $_POST['user_id'];

    $sql = "SELECT status FROM user WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $user_id);
    $stmt->execute();

    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        echo json_encode($row);
    } else {
        echo json_encode(["status" => "unknown"]);
    }

    // 추가: 상태를 출력하여 확인
    echo "Status: " . $row['status'];

    $stmt->close();
    $conn->close();
}

?>
