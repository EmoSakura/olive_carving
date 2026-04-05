import 'dart:typed_data';

import 'export_support_stub.dart'
    if (dart.library.io) 'export_support_io.dart'
    as impl;

Future<String?> saveCanvasPng(Uint8List bytes, String fileName) {
  return impl.saveCanvasPng(bytes, fileName);
}

Future<bool> openSavedExport(String path) {
  return impl.openSavedExport(path);
}

Future<String?> saveTextDocument(String content, String fileName) {
  return impl.saveTextDocument(content, fileName);
}
