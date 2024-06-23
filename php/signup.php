<?php
$host = 'localhost';
$db_user = 'root';
$db_password = '1220';
$db_name = 'mydb';

// 데이터베이스 연결
$conn = new mysqli($host, $db_user, $db_password, $db_name);

// 연결 오류 확인
if ($conn->connect_error) {
    die("Database connection failed.");
}

// POST 데이터 받기
$name = isset($_POST['name']) ? $_POST['name'] : '';
$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : '';
$password = isset($_POST['password']) ? $_POST['password'] : '';
$phone = isset($_POST['phone']) ? $_POST['phone'] : '';


echo "Received data: ";
print_r($_POST);

// user_id 유효성 검사
if (empty($user_id)) {
    echo "Error: user_id is required.";
    $conn->close();
    exit;
}

// 비밀번호 해시 처리
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

// user 테이블에 사용자 정보 저장
$sql_user = "INSERT INTO user (user_id, name, phone, status) VALUES (?, ?, ?, 'active')";
$stmt_user = $conn->prepare($sql_user);

if (!$stmt_user) {
    echo "Error preparing statement.";
    $conn->close();
    exit;
}

$stmt_user->bind_param("sss", $user_id, $name, $phone);

if (!$stmt_user->execute()) {
    echo "Error: " . $stmt_user->error;
    $stmt_user->close();
    $conn->close();
    exit;
}

//$user_id = $stmt_user->insert_id;
// userAuth 테이블에 사용자 인증 정보 저장
$sql_auth = "INSERT INTO userAuth (user_id, password) VALUES (?, ?)";
$stmt_auth = $conn->prepare($sql_auth);

if (!$stmt_auth) {
    echo "Error preparing statement.";
    $conn->close();
    exit;
}

$stmt_auth->bind_param("ss", $user_id, $hashed_password);

if (!$stmt_auth->execute()) {
    echo "Error: " . $stmt_auth->error;
} else {
    echo "New user and authentication record created successfully";
}



// 연결 닫기
$stmt_user->close();
$stmt_auth->close();
$conn->close();
?>