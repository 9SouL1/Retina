import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorOverlay extends CustomPainter {
  FaceDetectorOverlay({
    required this.imageSize,
    required this.previewSize,
    required this.rotation,
    required this.faces,
  });

  final Size imageSize;
  final Size previewSize;
  final InputImageRotation rotation;
  final List<Face> faces;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final double scaleX = size.width / previewSize.width;
    final double scaleY = size.height / previewSize.height;

    for (final Face face in faces) {
      final left = face.boundingBox.left * scaleX;
      final top = face.boundingBox.top * scaleY;
      final right = face.boundingBox.right * scaleX;
      final bottom = face.boundingBox.bottom * scaleY;

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

      // Head pose indicators
      final headEulerAngleY = face.headEulerAngleY ?? 0;
      final headEulerAngleZ = face.headEulerAngleZ ?? 0;
      if (headEulerAngleY.abs() < 10 && headEulerAngleZ.abs() < 10) {
        final centerX = (left + right) / 2;
        final centerY = (top + bottom) / 2;
        canvas.drawCircle(Offset(centerX, centerY), 20, Paint()..color = Colors.green.withValues(alpha: 0.5));
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorOverlay oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.faces != faces;
  }
}
