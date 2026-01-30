import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Converts a [CameraImage] in YUV420 format to [img.Image] in RGB format
img.Image? convertYUV420ToImage(CameraImage cameraImage) {
  final int width = cameraImage.width;
  final int height = cameraImage.height;

  final int yRowStride = cameraImage.planes[0].bytesPerRow;
  final int uvRowStride = cameraImage.planes[1].bytesPerRow;
  final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

  final img.Image image = img.Image(width: width, height: height);

  for (int h = 0; h < height; h++) {
    final int uvRowIndex = uvRowStride * (h >> 1);
    final int yRowIndex = yRowStride * h;
    
    for (int w = 0; w < width; w++) {
      final int uvIndex = uvRowIndex + (uvPixelStride * (w >> 1));
      final int index = yRowIndex + w;

      final y = cameraImage.planes[0].bytes[index];
      final u = cameraImage.planes[1].bytes[uvIndex];
      final v = cameraImage.planes[2].bytes[uvIndex];

      image.setPixelRgb(w, h,
          (y + 1.402 * (v - 128)).toInt().clamp(0, 255),
          (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).toInt().clamp(0, 255),
          (y + 1.772 * (u - 128)).toInt().clamp(0, 255));
    }
  }
  return image;
}
