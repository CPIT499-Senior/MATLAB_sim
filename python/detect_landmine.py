# detect_landmine.py

import os
import json
from ultralytics import YOLO
import cv2
import utm

model = YOLO("models/best.pt")
image_dir = "data/frames_for_detection"
output_json = "data/detected_landmines.json"
scan_region_path = "data/scan_region.json"

with open(scan_region_path, 'r') as f:
    scan_region = json.load(f)

top_left = scan_region["topLeft"]
bottom_right = scan_region["bottomRight"]

topLeftX, topLeftY, zone, _ = utm.from_latlon(*top_left)
bottomRightX, bottomRightY, _, _ = utm.from_latlon(*bottom_right)

utmWidth = abs(bottomRightX - topLeftX)
utmHeight = abs(bottomRightY - topLeftY)

results = []
for fname in sorted(os.listdir(image_dir)):
    if not fname.lower().endswith(".jpg"):
        continue

    path = os.path.join(image_dir, fname)
    img = cv2.imread(path)
    h, w = img.shape[:2]

    detections = model(path)[0].boxes.xywh.cpu().numpy()

    for (cx, cy, _, _) in detections:
        relX = cx / w
        relY = cy / h
        utm_x = topLeftX + relX * utmWidth
        utm_y = topLeftY + relY * utmHeight
        lat, lon = utm.to_latlon(utm_x, utm_y, zone, northern=True)
        results.append({
            "lat": lat,
            "lon": lon,
            "source": fname
        })

# Save and print
with open(output_json, "w") as f:
    json.dump(results, f, indent=2)

print(f"✅ YOLO detected {len(results)} landmines from drone-collected images:\n")
for r in results:
    print(f"- {r['source']}: ({r['lat']:.6f}, {r['lon']:.6f})")
