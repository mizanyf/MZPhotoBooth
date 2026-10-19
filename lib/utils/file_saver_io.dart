import 'dart:io';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class FileSaver {
  static Future<void> saveFile(List<int> bytes, String fileName) async {
    final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    try {
      await Gal.putImageBytes(uint8List, name: fileName);
    } catch (_) {
      try {
        final dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(uint8List);
      } catch (e) {
        rethrow;
      }
    }
  }
}
