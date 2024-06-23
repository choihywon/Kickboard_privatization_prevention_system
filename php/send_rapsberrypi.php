<?php
// send_status_to_flutter.php
$host = 'localhost'; // 데이터베이스 서버 주소
$db_user = 'root'; // 데이터베이스 사용자 이름
$db_password = '1220'; // 데이터베이스 비밀번호
$db_name = 'mydb'; // 데이터베이스 이름

// 데이터베이스 연결
$conn = new mysqli($host, $db_user, $db_password, $db_name);

// 연결 오류 확인
if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}

// HTTP GET 요청 처리
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // 사용자 ID를 받아옵니다.
    $user_id = isset($_GET['user_id']) ? $_GET['user_id'] : '';

    // 사용자 상태를 조회하는 SQL 쿼리
    $sql = "SELECT status FROM user WHERE user_id = '$user_id'";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        // 사용자 상태 정보를 가져옵니다.
        $row = $result->fetch_assoc();
        $data = array('user_id' => $user_id, 'status' => $row['status']);
        echo json_encode($data);
    } else {
        // 사용자 정보가 없는 경우
        echo json_encode(array('user_id' => $user_id, 'status' => 'unknown'));
    }
} else {
    // GET 요청이 아닌 경우 에러 메시지 출력
    http_response_code(405);
    echo 'Method Not Allowed';
}

// 데이터베이스 연결 종료
$conn->close();
?>
