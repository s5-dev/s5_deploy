import 'dart:io';

class ProcessedDirectory {
  Map<String, Stream<List<int>>> fileStreams = {};
  Map<String, int> lengths = {};

  ProcessedDirectory();
}

ProcessedDirectory processDirectory(Directory dir, String topDir) {
  ProcessedDirectory procDir = ProcessedDirectory();
  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      processDirectory(entity, topDir);
    } else if (entity is File) {
      final file = entity;
      String path = file.path;
      path = path.substring(topDir.length).replaceAll('\\', '/');

      if (path.startsWith('/')) path = path.substring(1);

      procDir.lengths[path] = file.lengthSync();
      procDir.fileStreams[path] = file.openRead();
    }
  }

  return procDir;
}
