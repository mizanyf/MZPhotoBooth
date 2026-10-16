// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class FileSaver {
  static void saveFile(List<int> bytes, String fileName) {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
