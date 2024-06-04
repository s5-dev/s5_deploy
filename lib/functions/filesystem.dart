import 'dart:io';

Future<void> ensureDirExistence(Directory directory) async {
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}
