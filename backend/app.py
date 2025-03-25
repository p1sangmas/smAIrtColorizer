from flask import Flask, request, send_file, jsonify, send_from_directory
import cv2
import numpy as np
import os
import torch
from basicsr.archs.ddcolor_arch import DDColor
import torch.nn.functional as F
import time

app = Flask(__name__)

# Define the model path
MODEL_PATH = "./path_to_you_model.pt"

# Check if GPU is available
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {DEVICE}")

# Initialize the colorization pipeline
class ImageColorizationPipeline:
    def __init__(self, model_path, input_size=256, model_size='large'):
        self.input_size = input_size
        self.device = DEVICE  # Use GPU if available

        if model_size == 'tiny':
            self.encoder_name = 'convnext-t'
        else:
            self.encoder_name = 'convnext-l'

        self.decoder_type = "MultiScaleColorDecoder"

        if self.decoder_type == 'MultiScaleColorDecoder':
            self.model = DDColor(
                encoder_name=self.encoder_name,
                decoder_name='MultiScaleColorDecoder',
                input_size=[self.input_size, self.input_size],
                num_output_channels=2,
                last_norm='Spectral',
                do_normalize=False,
                num_queries=100,
                num_scales=3,
                dec_layers=9,
            ).to(self.device)
        else:
            self.model = DDColor(
                encoder_name=self.encoder_name,
                decoder_name='SingleColorDecoder',
                input_size=[self.input_size, self.input_size],
                num_output_channels=2,
                last_norm='Spectral',
                do_normalize=False,
                num_queries=256,
            ).to(self.device)

        self.model.load_state_dict(
            torch.load(model_path, map_location=self.device)['params'],
            strict=False)
        self.model.eval()

    @torch.no_grad()
    def process(self, img):
        start_time = time.time()

        self.height, self.width = img.shape[:2]

        img = (img / 255.0).astype(np.float32)
        orig_l = cv2.cvtColor(img, cv2.COLOR_BGR2Lab)[:, :, :1]  # (h, w, 1)

        img_resized = cv2.resize(img, (self.input_size, self.input_size))
        img_l = cv2.cvtColor(img_resized, cv2.COLOR_BGR2Lab)[:, :, :1]
        img_gray_lab = np.concatenate((img_l, np.zeros_like(img_l), np.zeros_like(img_l)), axis=-1)  # Ensure 3 channels
        img_gray_rgb = cv2.cvtColor(img_gray_lab, cv2.COLOR_LAB2RGB)

        tensor_gray_rgb = torch.from_numpy(img_gray_rgb.transpose((2, 0, 1))).float().unsqueeze(0).to(self.device)
        output_ab = self.model(tensor_gray_rgb).cpu()  # (1, 2, self.height, self.width)

        output_ab_resize = F.interpolate(output_ab, size=(self.height, self.width))[0].float().numpy().transpose(1, 2, 0)
        output_lab = np.concatenate((orig_l, output_ab_resize), axis=-1)
        output_bgr = cv2.cvtColor(output_lab, cv2.COLOR_LAB2BGR)

        output_img = (output_bgr * 255.0).round().astype(np.uint8)

        end_time = time.time()
        print(f"Time taken for colorization: {end_time - start_time:.2f} seconds")

        return output_img

# Initialize the colorization pipeline
colorizer = ImageColorizationPipeline(model_path=MODEL_PATH, input_size=512, model_size='large')

# Helper functions for video processing
def extract_frames(video_path, output_dir):
    """Extracts frames from a video and saves them as .jpg files."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError(f"Error: Could not open video {video_path}.")

    frame_number = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame_filename = os.path.join(output_dir, f"frame_{frame_number:04d}.jpg")
        cv2.imwrite(frame_filename, frame)
        frame_number += 1

    cap.release()
    print(f"Extracted {frame_number} frames to {output_dir}.")
    return frame_number

def colorize_directory(input_dir, output_dir):
    """Colorizes all .jpg images in a directory."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    frame_files = [f for f in os.listdir(input_dir) if f.endswith('.jpg')]
    for frame_file in frame_files:
        input_path = os.path.join(input_dir, frame_file)
        img = cv2.imread(input_path)
        if img is None:
            print(f"Error: Unable to read image {input_path}.")
            continue

        colorized_img = colorizer.process(img)
        output_path = os.path.join(output_dir, f"colorized_{frame_file}")
        cv2.imwrite(output_path, colorized_img)

    print(f"Colorized frames saved to {output_dir}.")

def combine_frames_to_video(frame_dir, output_video_path, fps=30):
    """Combines .jpg frames into a .mp4 video."""
    frame_files = sorted([f for f in os.listdir(frame_dir) if f.endswith('.jpg')])
    if not frame_files:
        raise ValueError(f"No .jpg frames found in {frame_dir}.")

    first_frame_path = os.path.join(frame_dir, frame_files[0])
    first_frame = cv2.imread(first_frame_path)
    if first_frame is None:
        raise ValueError(f"Error: Unable to read frame {first_frame_path}.")

    height, width, _ = first_frame.shape
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video_writer = cv2.VideoWriter(output_video_path, fourcc, fps, (width, height))

    for frame_file in frame_files:
        frame_path = os.path.join(frame_dir, frame_file)
        frame = cv2.imread(frame_path)
        if frame is None:
            print(f"Error: Unable to read frame {frame_path}.")
            continue
        video_writer.write(frame)

    video_writer.release()
    print(f"Video saved to {output_video_path}.")

@app.route("/colorize", methods=["POST"])
def colorize():
    try:
        # Save the uploaded file
        uploaded_file = request.files["file"]
        input_path = "uploaded_image.JPEG"
        uploaded_file.save(input_path)

        # Read the image
        img = cv2.imread(input_path)
        if img is None:
            return jsonify({"error": "Unable to read image file."}), 400

        # Colorize the image
        output_img = colorizer.process(img)

        # Save the colorized image
        output_path = "colorized_image.png"
        cv2.imwrite(output_path, output_img)

        # Return the colorized image
        return send_file(output_path, mimetype="image/png")

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "An error occurred while processing the image."}), 500

@app.route("/colorize-video", methods=["POST"])
def colorize_video():
    try:
        # Save the uploaded video
        uploaded_file = request.files["file"]
        input_video_path = "uploaded_video.mp4"
        uploaded_file.save(input_video_path)

        # Extract frames from the video
        frames_dir = "extracted_frames"
        frame_count = extract_frames(input_video_path, frames_dir)

        # Colorize the frames
        colorized_frames_dir = "colorized_frames"
        colorize_directory(frames_dir, colorized_frames_dir)

        # Combine colorized frames into a video
        output_video_path = "colorized_video.mp4"
        combine_frames_to_video(colorized_frames_dir, output_video_path)

        # Clean up temporary files
        for file in os.listdir(frames_dir):
            os.remove(os.path.join(frames_dir, file))
        os.rmdir(frames_dir)
        for file in os.listdir(colorized_frames_dir):
            os.remove(os.path.join(colorized_frames_dir, file))
        os.rmdir(colorized_frames_dir)

        # Return the colorized video
        full_url = f"http://localhost:3000/colorized_video.mp4"
        return jsonify({"outputURL": full_url}), 200, {"Content-Type": "application/json"}

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500, {"Content-Type": "application/json"}

@app.route("/colorized_video.mp4", methods=["GET"])
def get_colorized_video():
    return send_from_directory(".", "colorized_video.mp4")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
