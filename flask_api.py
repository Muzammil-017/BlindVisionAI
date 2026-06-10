from flask import Flask, request, jsonify
import torch
from PIL import Image
import io

app = Flask(__name__)

# Load YOLOv5 model ONCE
model = torch.hub.load(
    'ultralytics/yolov5',
    'custom',
    path='yolov5s.pt',
    force_reload=False
)
model.conf = 0.4
model.iou = 0.45
model.max_det = 5

@app.route('/detect', methods=['POST'])
def detect():
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    file = request.files['image']
    image_bytes = file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    results = model(image)

    detections = results.pandas().xyxy[0].to_dict(orient="records")

    return jsonify(detections)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
