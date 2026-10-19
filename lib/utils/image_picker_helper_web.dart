// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class ImagePickerHelper {
  static Future<Uint8List?> pickImage() {
    final completer = Completer<Uint8List?>();
    try {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(files[0]);
          reader.onLoadEnd.listen((e) {
            if (reader.result != null) {
              completer.complete(Uint8List.fromList(reader.result as List<int>));
            } else {
              completer.complete(null);
            }
          });
          reader.onError.listen((e) {
            completer.complete(null);
          });
        } else {
          completer.complete(null);
        }
      });
    } catch (e) {
      completer.complete(null);
    }
    return completer.future;
  }
}
