import 'dart:io';

import 'package:mhu_dart_builder/mhu_dart_builder.dart';
import 'package:mhu_dart_builder/src/resources.dart';
import 'package:mhu_dart_commons/io.dart';

import 'protoc.dart';

// Future<void> runCompleteProtoGenerator({
//   String? packageName,
//   List<String> dependencies = const [],
// }) async {
//   packageName ??= await packageNameFromPubspec();
//
//   await runProtoc(
//     packageName: packageName,
//     dependencies: dependencies,
//   );
//
//   await runPbLibGenerator(
//     packageName: packageName,
//     dependencies: dependencies,
//   );
// }

Future<void> generateExportFile({
  String? packageName,
  required File Function(Directory dir) file,
}) async {
  packageName ??= await packageNameFromPubspec();

  final cwd = Directory.current;
  final privateFile = file(Directory('.'));

  final publicFile = cwd.fileTo(['lib', privateFile.filename]);

  final content = "export '${privateFile.filePath.skip(2).join('/')}';";

  await publicFile.writeAsString(content);
}
