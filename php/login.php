<?php
$host = 'localhost';
$db_user = 'root';
$db_password = '1220';
$db_name = 'mydb';

$conn = new mysqli($host, $db_user, $db_password, $db_name);

if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}

// POST 데이터 받기
$user_id = $_POST['user_id'] ?? '';
$password = $_POST['password'] ?? '';

// 입력값 검증
if (empty($user_id) || empty($password)) {
    http_response_code(400);
    echo "User ID and password are required";
    exit;
}

// userAuth 테이블에서 사용자 인증 정보 조회
$sql = "SELECT password FROM userAuth WHERE user_id = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo "Error preparing statement: " . $conn->error;
    exit;
}

$stmt->bind_param("s", $user_id);
$stmt->execute();

$result = $stmt->get_result();
if ($row = $result->fetch_assoc()) {
    if (password_verify($password, $row['password'])) {
        // user 테이블과 조인하여 status를 가져옵니다.
        $statusQuery = "SELECT u.status FROM userAuth ua JOIN user u ON ua.user_id = u.user_id WHERE ua.user_id = ?";
        $statusStmt = $conn->prepare($statusQuery);
        $statusStmt->bind_param("s", $user_id);
        $statusStmt->execute();
        $statusResult = $statusStmt->get_result();
        $statusRow = $statusResult->fetch_assoc();
        
        // 응답에 status를 포함합니다.
        echo json_encode([
            'message' => 'Login successful',
            'status' => $statusRow['status'] // 'status' 필드를 포함
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['message' => 'Invalid credentials']);
    }
} else {
    http_response_code(404);
    echo json_encode(['message' => 'User not found']);
}


$stmt->close();
$conn->close();
?>
