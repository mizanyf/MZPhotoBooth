import 'dart:typed_data';
import 'package:flutter/widgets.dart';

class CameraHelper {
  bool isInitialized = false;
  bool hasPermissionError = false;
  bool isFrontCamera = true;
  bool mirrorFrontCameraPreview = false;
  bool mirrorFrontCameraCapture = false;

  Future<bool> startCamera({bool? frontCamera}) async => false;
  Future<bool> switchCamera() async => false;
  Future<void> resumeCamera() async {}
  Future<Uint8List?> captureFrame() async => null;
  Widget buildPreview({Key? key}) => const SizedBox.shrink();
  void dispose() {}
}

typedef WebCameraHelper = CameraHelper;
