import os
import urllib.request
import cv2
import httpx
import time

BASE_URL = "http://127.0.0.1:8000/api/v1"
TRIP_ID = 1

# Ensure cascade XML files are available locally
FACE_XML = "haarcascade_frontalface_default.xml"
EYE_XML = "haarcascade_eye.xml"

CASCADES = {
    FACE_XML: "https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_frontalface_default.xml",
    EYE_XML: "https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_eye.xml",
}

for xml_file, url in CASCADES.items():
    if not os.path.exists(xml_file):
        print(f"Downloading {xml_file}...")
        urllib.request.urlretrieve(url, xml_file)

face_cascade = cv2.CascadeClassifier(FACE_XML)
eye_cascade = cv2.CascadeClassifier(EYE_XML)

def report_fatigue_to_backend(ear_est, duration_ms):
    try:
        with httpx.Client(timeout=2.0) as client:
            payload = {
                "trip_id": TRIP_ID,
                "event_type": "MICROSLEEP",
                "severity": "HIGH",
                "ear": ear_est,
                "blink_duration_ms": int(duration_ms),
                "head_pose": "FORWARD",
                "latitude": 21.1458,
                "longitude": 79.0882
            }
            client.post(f"{BASE_URL}/fatigue/events", json=payload)
            print(f"🚨 [ALERT] Fatigue Event Synced to Backend! Duration: {int(duration_ms)}ms")
    except Exception as e:
        print(f"⚠️ [WARNING] Could not reach backend: {e}")

cap = cv2.VideoCapture(0)
closed_frame_count = 0
drowsy_start_time = None
last_alert_time = 0

print("🎥 Starting Camera... Look into webcam. Press 'q' to quit.")

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    frame = cv2.flip(frame, 1)
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.2, minNeighbors=5, minSize=(100, 100))

    status_text = "Status: Alert (Eyes Open)"
    status_color = (0, 255, 0)
    eyes_detected = False

    for (x, y, w, h) in faces:
        cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 200, 0), 2)
        
        roi_gray = gray[y:y + int(h * 0.6), x:x + w]
        roi_color = frame[y:y + int(h * 0.6), x:x + w]
        
        eyes = eye_cascade.detectMultiScale(roi_gray, scaleFactor=1.1, minNeighbors=4, minSize=(25, 25))
        
        if len(eyes) > 0:
            eyes_detected = True
            for (ex, ey, ew, eh) in eyes:
                cv2.rectangle(roi_color, (ex, ey), (ex + ew, ey + eh), (0, 255, 0), 2)

    if len(faces) > 0 and not eyes_detected:
        closed_frame_count += 1
        if drowsy_start_time is None:
            drowsy_start_time = time.time()

        if closed_frame_count >= 18:
            status_text = "DROWSINESS DETECTED!"
            status_color = (0, 0, 255)
            
            if time.time() - last_alert_time > 3.0:
                duration_ms = (time.time() - drowsy_start_time) * 1000
                report_fatigue_to_backend(0.16, duration_ms)
                last_alert_time = time.time()
    else:
        closed_frame_count = 0
        drowsy_start_time = None

    cv2.putText(frame, "FADER Edge Vision Monitor", (30, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
    cv2.putText(frame, status_text, (30, 85), cv2.FONT_HERSHEY_SIMPLEX, 0.8, status_color, 2)

    cv2.imshow("FADER Driver Safety Monitor", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
