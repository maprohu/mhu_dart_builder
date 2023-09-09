import 'dart:io';

import 'package:path/path.dart' as p;

import '../.dart_tool/build/entrypoint/build.dart' as build;

void main() {
  final buildDir = Directory(".dart_tool/build");
  for (final dir in buildDir.listSync()) {
    if (p.basename(dir.path) == "entrypoint") continue;

    dir.deleteSync(recursive: true);
  }

  build.main([
    "build",
    "--delete-conflicting-outputs",
  ]);
}
