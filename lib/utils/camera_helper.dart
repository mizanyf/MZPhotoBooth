// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';

class WebCameraHelper {
  html.VideoElement? videoElement;
  html.MediaStream? mediaStream;
  late final String viewType;
  bool isInitialized = false;
  bool hasPermissionError = false;

  WebCameraHelper() {
    viewType = 'webcam-view-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<bool> startCamera() async {
    if (!kIsWeb) return false;
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        hasPermissionError = true;
        return false;
      }

      mediaStream = await mediaDevices.getUserMedia({'video': true, 'audio': false});

      videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = mediaStream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'; // mirror effect like photobooth

      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => videoElement!,
      );

      isInitialized = true;
      hasPermissionError = false;
      return true;
    } catch (e) {
      hasPermissionError = true;
      isInitialized = false;
      return false;
    }
  }

  Uint8List? captureFrame() {
    if (videoElement == null || videoElement!.videoWidth == 0) return null;
    try {
      final canvas = html.CanvasElement(
        width: videoElement!.videoWidth,
        height: videoElement!.videoHeight,
      );
      final ctx = canvas.context2D;
      // Mirror horizontally to match mirrored live preview
      ctx.translate(canvas.width!, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(videoElement!, 0, 0);

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
      final base64String = dataUrl.split(',').last;
      return Uint8List.fromList(base64Decode(base64String));
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    try {
      mediaStream?.getTracks().forEach((track) => track.stop());
      videoElement?.srcObject = null;
    } catch (_) {}
  }
}
