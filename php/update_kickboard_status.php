<?php
$servername = "localhost";
$username = "root";
$password = "1220";
$dbname = "mydb";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

if(isset($_POST['kickboard_id']) && isset($_POST['new_status'])) {
    $kickboard_id = $_POST['kickboard_id'];
    $new_status = $_POST['new_status'];

    $sql = "UPDATE kickboard SET status = ? WHERE kickboard_id = ?";
    $stmt = $conn->prepare($sql);

    if ($stmt) {
        $stmt->bind_param("ss", $new_status, $kickboard_id);

        if ($stmt->execute()) {
            echo "Record updated successfully";
        } else {
            error_log("Error updating record: " . $stmt->error);
            echo "Error updating record: " . $stmt->error;
        }

        $stmt->close();
    } else {
        echo "Error preparing statement: " . $conn->error;
    }
} else {
    echo "kickboard_id or new_status not set in POST data";
}

$conn->close();
?>
