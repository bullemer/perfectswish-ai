import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Converts a [CameraImage] in YUV420 format to [img.Image] in RGB format
/// Note: YUV420 has 3 separate planes (Y, U, V)
img.Image? convertYUV420ToImage(CameraImage cameraImage) {
  if (cameraImage.planes.length < 3) return null;
  
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

/// Converts a [CameraImage] in NV21 format to [img.Image] in RGB format
/// Note: NV21 has 2 planes: Y plane and interleaved VU plane (V first, then U)
/// Optimized with proper row stride handling
img.Image? convertNV21ToImage(CameraImage cameraImage) {
  if (cameraImage.planes.isEmpty) return null;
  
  final int width = cameraImage.width;
  final int height = cameraImage.height;

  final yPlane = cameraImage.planes[0].bytes;
  final yRowStride = cameraImage.planes[0].bytesPerRow;
  
  // NV21 has interleaved VU in the second plane
  final vuPlane = cameraImage.planes.length > 1 
      ? cameraImage.planes[1].bytes 
      : yPlane;
  final vuRowStride = cameraImage.planes.length > 1 
      ? cameraImage.planes[1].bytesPerRow 
      : yRowStride;

  final img.Image image = img.Image(width: width, height: height);

  for (int h = 0; h < height; h++) {
    final int yRowOffset = h * yRowStride;
    final int vuRowOffset = (h >> 1) * vuRowStride;
    
    for (int w = 0; w < width; w++) {
      final int yIndex = yRowOffset + w;
      // VU plane is interleaved: V, U, V, U, ...
      // Each 2x2 block of Y shares one V and one U
      final int vuIndex = vuRowOffset + (w & ~1);

      // Bounds check to prevent crashes
      if (yIndex >= yPlane.length) continue;
      
      final y = yPlane[yIndex];
      final v = vuIndex < vuPlane.length ? vuPlane[vuIndex] : 128;
      final u = vuIndex + 1 < vuPlane.length ? vuPlane[vuIndex + 1] : 128;

      // YUV to RGB conversion (ITU-R BT.601)
      final r = (y + 1.402 * (v - 128)).toInt().clamp(0, 255);
      final g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).toInt().clamp(0, 255);
      final b = (y + 1.772 * (u - 128)).toInt().clamp(0, 255);
      
      image.setPixelRgb(w, h, r, g, b);
    }
  }
  return image;
}
