import socket
import smbus
import time
import RPi.GPIO as GPIO
import threading

# LCD 및 초음파 센서 설정 값
LCD_ADDR = 0x27
I2C_BUS = 1
LCD_CHR = 1
LCD_CMD = 0
LCD_CHARS = 16
LCD_LINE_1 = 0x80
LCD_LINE_2 = 0xC0
E_PULSE = 0.0005
E_DELAY = 0.0005

TRIG = 12
ECHO = 40

current_status = "idle"
status_lock = threading.Lock()
socket_lock = threading.Lock()

running_threads = []

def cho_setup():
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(TRIG, GPIO.OUT)
    GPIO.setup(ECHO, GPIO.IN)

def get_distance():
    GPIO.output(TRIG, True)
    time.sleep(0.00001)
    GPIO.output(TRIG, False)
   
    start_time = time.time()
    while GPIO.input(ECHO) == 0:
        start_time = time.time()

    end_time = time.time()
    while GPIO.input(ECHO) == 1:
        end_time = time.time()

    duration = end_time - start_time
    distance = (duration * 34300) / 2
    print(f"Distance: {distance}cm")
    return distance

def lcd_init():
    lcd_byte(0x33, LCD_CMD)
    lcd_byte(0x32, LCD_CMD)
    lcd_byte(0x06, LCD_CMD)
    lcd_byte(0x0C, LCD_CMD)
    lcd_byte(0x28, LCD_CMD)
    lcd_byte(0x01, LCD_CMD)
    time.sleep(E_DELAY)

def lcd_byte(bits, mode):
    high_bits = mode | (bits & 0xF0) | 0x08
    low_bits = mode | ((bits << 4) & 0xF0) | 0x08

    bus.write_byte(LCD_ADDR, high_bits)
    lcd_toggle_enable(high_bits)
    bus.write_byte(LCD_ADDR, low_bits)
    lcd_toggle_enable(low_bits)

def lcd_toggle_enable(bits):
    time.sleep(E_DELAY)
    bus.write_byte(LCD_ADDR, (bits | 0x04))
    time.sleep(E_PULSE)
    bus.write_byte(LCD_ADDR, (bits & ~0x04))
    time.sleep(E_DELAY)

def lcd_string(message, line):
    message = message.ljust(LCD_CHARS, " ")
    lcd_byte(line, LCD_CMD)
    for i in range(LCD_CHARS):
        lcd_byte(ord(message[i]), LCD_CHR)

def continuous_distance_check(client_socket, stop_event):
    global current_status
    warning_timer = 0
    notuse_timer = 0
    while not stop_event.is_set():
        with status_lock:
            if current_status != "using":
                continue
        distance = get_distance()
       
        if distance >= 20:
            warning_timer += 1
            notuse_timer += 1
            print(f"warning_timer: {warning_timer}")
        else:
            warning_timer = 0
            notuse_timer = 0
        if warning_timer == 7:
            with socket_lock:
                try:
                    client_socket.sendall("kis_wwarning".encode())
                    print("Sent 'warning' to client")
                except Exception as e:
                    print(f"Error sending 'warning' message: {e}")
                    break
        if notuse_timer == 12:
            with socket_lock:
                try:
                    client_socket.sendall("notuse".encode())
                    print("Sent 'notuse' to client")
                    warning_timer = 0  # Reset warning_timer after sending notuse
                    notuse_timer = 0   # Reset notuse_timer after sending notuse
                except Exception as e:
                    print(f"Error sending 'notuse' message: {e}")
                    break
        time.sleep(1)
    print("Stopping distance check thread")

def handle_client(client_socket, client_address):
    global current_status
    print(f"Connected with {client_address}")
    stop_event = threading.Event()
    distance_thread = threading.Thread(target=continuous_distance_check, args=(client_socket, stop_event))
    running_threads.append((distance_thread, stop_event))
    distance_thread.start()

    try:
        while True:
            data = client_socket.recv(1024)
            if not data:
                break
            received_message = data.decode()
            print(f"Received: {received_message}")
            try:
                command, kickboard_id = received_message.split(',')
                if kickboard_id == '1':
                    with status_lock:
                        if command == 'stop':
                            current_status = "idle"
                            client_socket.sendall("ok".encode())
                        elif command == '2':
                            current_status = "reserving"
                            lcd_string("reserving", LCD_LINE_1)
                            client_socket.sendall("2".encode())
                        elif command == '3':
                            current_status = "using"
                            lcd_string("using", LCD_LINE_1)
                        elif command == '4':
                            current_status = "idle"
                            lcd_string("you can use", LCD_LINE_1)
                else:
                    print("Received command for non-1")
            except ValueError:
                print("received malformed message")
    finally:
        with socket_lock:
            client_socket.close()
        print(f"Connection with {client_address} closed")
        stop_event.set()
        distance_thread.join()
        running_threads.remove((distance_thread, stop_event))

bus = smbus.SMBus(I2C_BUS)
lcd_init()
cho_setup()

def main():
    host = '0.0.0.0'
    port = 8000

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((host, port))
    server_socket.listen(5)
    print(f"Listening on {port}...")

    try:
        while True:
            client_socket, client_address = server_socket.accept()
            client_thread = threading.Thread(target=handle_client, args=(client_socket, client_address))
            client_thread.start()
    except KeyboardInterrupt:
        print("Program exited by user")
    finally:
        for thread, stop_event in running_threads:
            stop_event.set()
            thread.join()
        GPIO.cleanup()
        server_socket.close()

if __name__ == "__main__":
    try:
        GPIO.setmode(GPIO.BOARD)
        main()
    finally:
        GPIO.cleanup()
