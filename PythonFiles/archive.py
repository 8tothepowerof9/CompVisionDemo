import json
import cv2
import socket
import mediapipe as mp

# UDP setup
IP = "127.0.0.1"
PORT = 4242
BUFFER_SIZE = 1024

# Initialize Mediapipe Hands
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
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


def get_hand_landmarks(frame):
    """Processes a frame and extracts hand landmark data."""
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(rgb_frame)
    landmark_data = []

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            hand_info = []
            for idx, landmark in enumerate(hand_landmarks.landmark):
                # Convert 3d to 2d top down view
                hand_info.append({"id": idx, "x": landmark.x, "y": landmark.y})
            landmark_data.append(hand_info)

            # Draw landmarks on frame
            # mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

    return landmark_data, frame


def send_data(data):
    """Sends data to the UDP server."""
    try:
        message = json.dumps({"hands": data}).encode()
        client_socket.sendto(message, (IP, PORT))
    except Exception as e:
        print(f"Error sending data: {e}")


try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("Error: Failed to capture frame.")
            break

        landmark_data, frame = get_hand_landmarks(frame)

        send_data(landmark_data)

        # Display the frame with drawn landmarks
        # cv2.imshow("Hand Tracking", frame)

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

except Exception as e:
    print(f"Unexpected error: {e}")

finally:
    cap.release()
    cv2.destroyAllWindows()
    client_socket.close()
    print("Resources released. Exiting...")
