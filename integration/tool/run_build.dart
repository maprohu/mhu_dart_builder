import 'dart:io';

import 'package:mhu_dart_commons/io.dart';

import '../.dart_tool/build/entrypoint/build.dart' as build;

void main()  {
  final buildDir = Directory(".dart_tool/build");
  for (final dir in buildDir.listSync()) {
    if (dir.name == "entrypoint") continue;

    dir.deleteSync(recursive: true);
  }

  build.main([
    "build",
    "--delete-conflicting-outputs",
  ]);
}
