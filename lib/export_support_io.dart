import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> saveCanvasPng(Uint8List bytes, String fileName) async {
  final baseDirectory = await getApplicationDocumentsDirectory();
  final exportDirectory = Directory(
    '${baseDirectory.path}${Platform.pathSeparator}exports',
  );
  if (!await exportDirectory.exists()) {
    await exportDirectory.create(recursive: true);
  }
  final safeName = fileName
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(' ', '_');
  final file = File(
    '${exportDirectory.path}${Platform.pathSeparator}$safeName.png',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<bool> openSavedExport(String path) async {
  try {
    if (path.trim().isEmpty) {
      return false;
    }
    final file = File(path);
    if (!await file.exists()) {
      return false;
    }

    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', path], runInShell: true);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [path]);
      return true;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [path]);
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

Future<String?> saveTextDocument(String content, String fileName) async {
  final baseDirectory = await getApplicationDocumentsDirectory();
  final exportDirectory = Directory(
    '${baseDirectory.path}${Platform.pathSeparator}exports',
  );
  if (!await exportDirectory.exists()) {
    await exportDirectory.create(recursive: true);
  }
  final safeName = fileName
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(' ', '_');
  final file = File(
    '${exportDirectory.path}${Platform.pathSeparator}$safeName.txt',
  );
  await file.writeAsString(content, flush: true);
  return file.path;
}
