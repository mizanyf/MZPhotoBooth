// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraHelper {
  html.VideoElement? videoElement;
  html.MediaStream? mediaStream;
  late final String viewType;
  bool isInitialized = false;
  bool hasPermissionError = false;
  bool isFrontCamera = true;

  CameraHelper() {
    viewType = 'webcam-view-${DateTime.now().microsecondsSinceEpoch}';
  }

  bool _factoryRegistered = false;

  Future<bool> startCamera({bool? frontCamera}) async {
    if (!kIsWeb) return false;
    if (frontCamera != null) {
      isFrontCamera = frontCamera;
    }
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        hasPermissionError = true;
        return false;
      }

      // Stop previous stream tracks if any before requesting camera
      try {
        mediaStream?.getTracks().forEach((track) => track.stop());
      } catch (_) {}
      mediaStream = null;

      try {
        mediaStream = await mediaDevices.getUserMedia({
          'video': {
            'facingMode': isFrontCamera ? 'user' : 'environment',
          },
          'audio': false,
        });
      } catch (_) {
        // Fallback if specific facingMode is not supported on this device/browser
        mediaStream = await mediaDevices.getUserMedia({
          'video': true,
          'audio': false,
        });
      }

      final transform = isFrontCamera ? 'scaleX(-1)' : 'scaleX(1)';

      if (videoElement == null) {
        videoElement = html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..srcObject = mediaStream
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.transform = transform;

        if (!_factoryRegistered) {
          ui_web.platformViewRegistry.registerViewFactory(
            viewType,
            (int viewId) => videoElement!,
          );
          _factoryRegistered = true;
        }
      } else {
        videoElement!
          ..srcObject = mediaStream
          ..style.transform = transform;
        await videoElement!.play();
      }

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
    if (!kIsWeb) return;
    try {
      if (videoElement != null && mediaStream != null) {
        final tracks = mediaStream?.getVideoTracks() ?? [];
        final hasLiveTrack = tracks.any((t) => t.readyState == 'live');

        if (!hasLiveTrack) {
          await startCamera();
          return;
        }

        if (videoElement!.srcObject != mediaStream) {
          videoElement!.srcObject = mediaStream;
        }

        videoElement!.style.transform = isFrontCamera ? 'scaleX(-1)' : 'scaleX(1)';

        if (videoElement!.paused) {
          await videoElement!.play();
        }
      } else {
        await startCamera();
      }
    } catch (_) {
      try {
        await videoElement?.play();
      } catch (_) {}
    }
  }

  Future<Uint8List?> captureFrame() async {
    if (videoElement == null || videoElement!.videoWidth == 0) return null;
    try {
      final canvas = html.CanvasElement(
        width: videoElement!.videoWidth,
        height: videoElement!.videoHeight,
      );
      final ctx = canvas.context2D;
      if (isFrontCamera) {
        // Mirror horizontally to match mirrored live preview for front camera
        ctx.translate(canvas.width!, 0);
        ctx.scale(-1, 1);
      }
      ctx.drawImage(videoElement!, 0, 0);

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
      final base64String = dataUrl.split(',').last;
      return Uint8List.fromList(base64Decode(base64String));
    } catch (e) {
      return null;
    }
  }

  Widget buildPreview({Key? key}) {
    if (!isInitialized) return const SizedBox.shrink();
    return HtmlElementView(
      key: key ?? const ValueKey('live-camera-persistent-view'),
      viewType: viewType,
      onPlatformViewCreated: (_) {
        resumeCamera();
      },
    );
  }

  void dispose() {
    try {
      mediaStream?.getTracks().forEach((track) => track.stop());
      videoElement?.srcObject = null;
    } catch (_) {}
  }
}

typedef WebCameraHelper = CameraHelper;
