import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Input data for the isolate
class ImageProcessInput {
  final Uint8List frameData;
  final int targetSize;
  
  ImageProcessInput({
    required this.frameData,
    this.targetSize = 640,
  });
}

/// Result from the isolate
class ImageProcessResult {
  final Uint8List inferenceInput;
  final int width;
  final int height;
  final int padX;
  final int padY;
  final int newW;
  final int newH;
  
  ImageProcessResult({
    required this.inferenceInput,
    required this.width,
    required this.height,
    required this.padX,
    required this.padY,
    required this.newW,
    required this.newH,
  });
}

/// The entry point for the isolate
Future<ImageProcessResult?> processImageInIsolate(ImageProcessInput input) async {
  try {
    // 1. Decode
    final img.Image? decoded = img.decodeJpg(input.frameData);
    if (decoded == null) return null;
    
    // 2. Letterbox logic to match Python/Live
    final int fullW = decoded.width;
    final int fullH = decoded.height;
    final int targetSize = input.targetSize;
    
    final double aspectSrc = fullW / fullH;
    int newW, newH;
    int padX, padY;
    
    if (aspectSrc > 1.0) {
      // Landscape: fit to width
      newW = targetSize;
      newH = (targetSize / aspectSrc).round();
      padX = 0;
      padY = (targetSize - newH) ~/ 2;
    } else {
      // Portrait: fit to height
      newH = targetSize;
      newW = (targetSize * aspectSrc).round();
      padY = 0;
      padX = (targetSize - newW) ~/ 2;
    }
    
    // 3. Resize and Pad
    final img.Image resized = img.copyResize(decoded, width: newW, height: newH);
    final img.Image letterboxed = img.Image(width: targetSize, height: targetSize);
    
    // Fill with YOLO gray (114)
    img.fill(letterboxed, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(letterboxed, resized, dstX: padX, dstY: padY);
    
    // 4. Encode to JPG for Inference
    // YOLO package expects Uint8List of image data (likely JPG/PNG bytes for standard prediction)
    // Or raw bytes? The local_yolo_model.dart usually takes image bytes.
    // Based on previous code: Uint8List.fromList(img.encodeJpg(letterboxed, quality: 90));
    final Uint8List inferenceInput = Uint8List.fromList(img.encodeJpg(letterboxed, quality: 90));
    
    return ImageProcessResult(
      inferenceInput: inferenceInput,
      width: targetSize,
      height: targetSize,
      padX: padX,
      padY: padY,
      newW: newW,
      newH: newH,
    );
    
  } catch (e) {
    print("Error in isolate: $e");
    return null;
  }
}
