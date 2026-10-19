import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraHelper {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  bool isInitialized = false;
  bool hasPermissionError = false;
  bool isFrontCamera = true;

  Future<bool> startCamera({bool? frontCamera}) async {
    if (frontCamera != null) {
      isFrontCamera = frontCamera;
    }
    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.isEmpty) {
        hasPermissionError = true;
        isInitialized = false;
        return false;
      }

      final targetDirection = isFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final camera = _availableCameras.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => _availableCameras.first,
      );

      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = controller;
      await controller.initialize();

      isInitialized = true;
      hasPermissionError = false;
      return true;
    } catch (e) {
      hasPermissionError = true;
      isInitialized = false;
      return false;
    }
  }

  Future<bool> switchCamera() async {
    isFrontCamera = !isFrontCamera;
    return await startCamera();
  }

  Future<void> resumeCamera() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await startCamera();
      return;
    }
    try {
      await _controller!.resumePreview();
    } catch (_) {
      await startCamera();
    }
  }

  Future<Uint8List?> captureFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    try {
      final XFile photo = await _controller!.takePicture();
      return await photo.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  Widget buildPreview({Key? key}) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final double rawAspect = _controller!.value.aspectRatio;
        // In landscape, visual ratio is rawAspect (> 1.0); in portrait it is 1.0 / rawAspect (< 1.0)
        final double previewAspect =
            isLandscape ? rawAspect : (1.0 / rawAspect);

        return ClipRect(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / previewAspect,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        );
      },
    );
  }

  void dispose() {
    try {
      _controller?.dispose();
      _controller = null;
    } catch (_) {}
  }
}

typedef WebCameraHelper = CameraHelper;
