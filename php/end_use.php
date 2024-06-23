<?php
$host = 'localhost';
$db_user = 'root';
$db_password = '1220';
$db_name = 'mydb';

$conn = new mysqli($host, $db_user, $db_password, $db_name);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$sql = "SELECT kickboard_id, latitude, longitude, status, battary FROM kickboard";
$result = $conn->query($sql);

$kickboards = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        array_push($kickboards, $row);
    }
    echo json_encode($kickboards);
} else {
    echo "0 results";
}
$conn->close();
?>
