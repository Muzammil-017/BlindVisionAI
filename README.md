# BlindVisionAI

BlindVisionAI is an assistive object-detection project for visually impaired users. It combines a Flutter mobile app with a Flask and YOLOv5 backend to detect objects from the phone camera and announce results using text-to-speech.

## Features

- Real-time camera preview in a Flutter mobile app
- Automatic image capture and object detection requests
- YOLOv5-based backend object detection
- Bounding boxes and confidence labels on detected objects
- Voice feedback for detected object names
- Flask API endpoint for image uploads

## Tech Stack

- Flutter / Dart
- Flask / Python
- PyTorch
- YOLOv5
- Camera, HTTP, permission handling, path provider, and Flutter TTS packages

## Project Structure

```text
BlindVisionAI/
|-- frontend_flutter/        # Flutter mobile app
|   |-- lib/main.dart        # Main app UI, camera, detection flow, TTS
|   `-- lib/services/        # Detection API service
|-- flask_api.py             # Flask detection API
|-- app.py                   # Additional backend/app script
|-- real_time_detection.py   # Real-time detection script
|-- yolov5s.pt               # YOLOv5 model weights
|-- requirements.txt         # Python dependencies
|-- requirements_locked.txt  # Locked Python environment output
`-- PPT/                     # Project presentation files
```

## Backend Setup

Create and activate a Python virtual environment:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

Run the Flask API:

```powershell
python flask_api.py
```

The backend runs on:

```text
http://0.0.0.0:8000
```

Detection endpoint:

```text
POST /detect
```

The request must include an image file with the form field name `image`.

## Flutter App Setup

Move into the Flutter app folder:

```powershell
cd frontend_flutter
```

Install packages:

```powershell
flutter pub get
```

Run the app:

```powershell
flutter run
```

## Backend URL

The Flutter app currently sends detection requests to:

```text
http://10.125.118.142:8000/detect
```

Update this IP address in the Flutter code if your computer or server IP changes.

Files that currently reference the backend URL:

- `frontend_flutter/lib/main.dart`
- `frontend_flutter/lib/services/detection_service.dart`

## GitHub About

Suggested repository description:

```text
Assistive Flutter and YOLOv5 object-detection app for visually impaired users, with Flask backend and text-to-speech feedback.
```

Suggested topics:

```text
flutter, dart, flask, python, yolov5, pytorch, object-detection, assistive-technology, accessibility, text-to-speech
```

## Notes

- Camera and microphone permissions are requested by the Flutter app.
- The backend must be running and reachable from the phone or emulator.
- For a physical phone, use the computer's local network IP address in the Flutter backend URL.
