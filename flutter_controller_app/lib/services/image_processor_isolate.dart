import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../utils/image_utils.dart'; // Ensure this path is correct relative to services/

/// Input data sent to the isolate
class ImageProcessRequest {
  final int id;
  final int width;
  final int height;
  final List<TransferableTypedData> planes; // ZERO-COPY MOVE
  final List<int> strides; // bytesPerRow for each plane
  final List<int> pixelStrides; // bytesPerPixel for each plane (mostly for UV)
  final int cropSize; // Target square size (e.g. 640)
  final bool returnOriginalJpeg; // Whether to encode/return original frame (for visual debug)

  ImageProcessRequest({
    required this.id,
    required this.width,
    required this.height,
    required this.planes,
    required this.strides,
    required this.pixelStrides,
    this.cropSize = 640,
    this.returnOriginalJpeg = false,
  });
}

/// Output data received from the isolate
class ImageProcessResponse {
  final int id;
  final Uint8List? inferenceBytes; // Letterboxed 640x640 JPEG
  final Uint8List? originalBytes; // Original full-res JPEG (optional)
  final double scale; // Scale factor used
  final int padX;
  final int padY;
  final int originalWidth;
  final int originalHeight;
  final String? error;

  ImageProcessResponse({
    required this.id,
    this.inferenceBytes,
    this.originalBytes,
    required this.scale,
    required this.padX,
    required this.padY,
    required this.originalWidth,
    required this.originalHeight,
    this.error,
  });
}

/// Helper class to manage the Isolate lifecycle
class ImageProcessorIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  StreamSubscription? _subscription;
  final ReceivePort _receivePort = ReceivePort();
  
  final Map<int, Completer<ImageProcessResponse>> _activeRequests = {};
  int _idCounter = 0;
  bool _isReady = false;

  Future<void> start() async {
    _isolate = await Isolate.spawn(_entryPoint, _receivePort.sendPort);
    _subscription = _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _isReady = true;
      } else if (message is ImageProcessResponse) {
        final completer = _activeRequests.remove(message.id);
        if (completer != null) {
          completer.complete(message);
        }
      }
    });
  }

  Future<ImageProcessResponse> processFrame(CameraImage image, {bool returnOriginal = false}) {
    if (!_isReady || _sendPort == null) {
      return Future.error('Isolate not ready');
    }

    // Zero-copy packing using TransferableTypedData
    final id = _idCounter++;
    final req = ImageProcessRequest(
      id: id,
      width: image.width,
      height: image.height,
      planes: image.planes.map((p) => TransferableTypedData.fromList([p.bytes])).toList(),
      strides: image.planes.map((p) => p.bytesPerRow).toList(),
      pixelStrides: image.planes.map((p) => p.bytesPerPixel ?? 1).toList(),
      returnOriginalJpeg: returnOriginal,
    );

    final completer = Completer<ImageProcessResponse>();
    _activeRequests[id] = completer;
    _sendPort!.send(req);

    return completer.future;
  }

  void dispose() {
    _subscription?.cancel();
    _activeRequests.clear(); // Clear pending
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
    _isReady = false;
  }

  /// The entry point for the background Isolate
  static void _entryPoint(SendPort mainSendPort) {
    final ReceivePort isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((message) {
      if (message is ImageProcessRequest) {
        try {
          final result = _processImage(message);
          mainSendPort.send(result);
        } catch (e) {
          mainSendPort.send(ImageProcessResponse(
            id: message.id,
            scale: 1.0, padX: 0, padY: 0, 
            originalWidth: message.width, originalHeight: message.height,
            error: e.toString()
          ));
        }
      }
    });
  }

  static ImageProcessResponse _processImage(ImageProcessRequest req) {
    final sw = Stopwatch()..start();
    
    // Unpack TransferableTypedData (Zero-copy materialize)
    final List<Uint8List> rawPlanes = req.planes.map((t) => t.materialize().asUint8List()).toList();
    
    // 1. Convert NV21/YUV to RGB
    final img.Image? rawImage = _convertYUVtoRGB(
        req.width, req.height, rawPlanes, req.strides, req.pixelStrides);
        
    if (rawImage == null) throw Exception('Failed to decode YUV image');
    
    final t1 = sw.elapsedMilliseconds;

    final int fullW = rawImage.width;
    final int fullH = rawImage.height;
    
    // 2. Letterbox Logic
    final int targetSize = req.cropSize;
    final double aspectSrc = fullW / fullH;
    final double aspectDst = 1.0; 
    
    int newW, newH;
    int padX, padY;
     
    if (aspectSrc > aspectDst) {
      // Source is wider
      newW = targetSize;
      newH = (targetSize / aspectSrc).round();
      padX = 0;
      padY = (targetSize - newH) ~/ 2;
    } else {
      // Source is taller
      newH = targetSize;
      newW = (targetSize * aspectSrc).round();
      padY = 0;
      padX = (targetSize - newW) ~/ 2;
    }

    // Resize
    final img.Image resizedImage = img.copyResize(rawImage, width: newW, height: newH);
    
    // Compose on gray canvas
    final img.Image letterboxed = img.Image(width: targetSize, height: targetSize);
    img.fill(letterboxed, color: img.ColorRgb8(114, 114, 114)); // YOLO gray
    img.compositeImage(letterboxed, resizedImage, dstX: padX, dstY: padY);
    
    final t2 = sw.elapsedMilliseconds;
    
    // 3. Encode to JPEG (High Quality!)
    final Uint8List inferenceBytes = Uint8List.fromList(
      img.encodeJpg(letterboxed, quality: 95)
    );
    
    final t3 = sw.elapsedMilliseconds;
    
    Uint8List? originalBytes;
    if (req.returnOriginalJpeg) {
       // Lower quality for visual debug to save bandwidth/time
       originalBytes = Uint8List.fromList(img.encodeJpg(rawImage, quality: 50));
    }
    
    // Helpful log to see stage timings
    // print('Isolate Timing: YUV->RGB=${t1}ms Resize=${t2-t1}ms Encode=${t3-t2}ms Total=${t3}ms');

    return ImageProcessResponse(
      id: req.id,
      inferenceBytes: inferenceBytes,
      originalBytes: originalBytes,
      scale: newW / fullW.toDouble(),
      padX: padX,
      padY: padY,
      originalWidth: fullW,
      originalHeight: fullH,
    );
  }
  
  // Re-implementation of YUV converter for Isolate context
  static img.Image? _convertYUVtoRGB(int width, int height, List<Uint8List> planes, List<int> strides, List<int> pixelStrides) {
    if (planes.isEmpty) return null;
    
    final yPlane = planes[0];
    final yRowStride = strides[0];
    
    // Basic NV21 implementation
    final vuPlane = planes.length > 1 ? planes[1] : yPlane;
    final vuRowStride = strides.length > 1 ? strides[1] : yRowStride;
    
    final img.Image image = img.Image(width: width, height: height);

    for (int h = 0; h < height; h++) {
      final int yRowOffset = h * yRowStride;
      final int vuRowOffset = (h >> 1) * vuRowStride;
      
      for (int w = 0; w < width; w++) {
        final int yIndex = yRowOffset + w;
        final int vuIndex = vuRowOffset + (w & ~1);
        
        if (yIndex >= yPlane.length) continue;
        
        final y = yPlane[yIndex];
        final v = (vuIndex < vuPlane.length) ? vuPlane[vuIndex] : 128;
        final u = (vuIndex + 1 < vuPlane.length) ? vuPlane[vuIndex + 1] : 128;
        
        // YUV to RGB (BT.601) - Integer optimized
        final int c = y - 16;
        final int d = u - 128;
        final int e = v - 128;

        int r = (298 * c + 409 * e + 128) >> 8;
        int g = (298 * c - 100 * d - 208 * e + 128) >> 8;
        int b = (298 * c + 516 * d + 128) >> 8;
        
        image.setPixelRgb(w, h, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
      }
    }
    return image;
  }
}
