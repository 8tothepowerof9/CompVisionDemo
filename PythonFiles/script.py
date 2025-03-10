import json
import cv2
import socket
import mediapipe as mp
import threading
import time

# UDP setup
IP = "127.0.0.1"
PORT = 4242

# Initialize Mediapipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
    model_complexity=1,
    max_num_hands=1,
)

# Initialize UDP socket
client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client_socket.settimeout(1)

# Start capturing video
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)  # Reduce resolution for faster processing
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# Lock for threading
lock = threading.Lock()
running = True


def get_hand_landmarks(frame):
    """Processes a frame and extracts hand landmark data."""
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(rgb_frame)
    landmark_data = []

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            hand_info = [
                {"id": idx, "x": lm.x, "y": lm.y}
                for idx, lm in enumerate(hand_landmarks.landmark)
            ]
            landmark_data.append(hand_info)

    return landmark_data


def send_data(data):
    """Sends data to the UDP server."""
    try:
        message = json.dumps({"hands": data}).encode()
        client_socket.sendto(message, (IP, PORT))
    except Exception as e:
        print(f"Error sending data: {e}")


def video_capture_thread():
    """Captures video frames and processes hand tracking in a separate thread."""
    global running

    while running:
        ret, frame = cap.read()
        if not ret:
            print("Error: Failed to capture frame.")
            break

        with lock:
            landmark_data = get_hand_landmarks(frame)
            send_data(landmark_data)

        time.sleep(0.01)  # Reduce CPU usage


# Start the processing thread
thread = threading.Thread(target=video_capture_thread, daemon=True)
thread.start()

try:
    while True:
        time.sleep(1)  # Keep main thread alive

except KeyboardInterrupt:
    running = False
    thread.join()

finally:
    cap.release()
    client_socket.close()
    print("Resources released. Exiting...")
