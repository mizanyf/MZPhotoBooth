import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3000,
        maxHeight: 3000,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
