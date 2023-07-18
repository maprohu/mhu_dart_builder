import 'dart:io';

import 'package:mhu_dart_builder/src/resources.dart';
import 'package:mhu_dart_commons/io.dart';

extension ProtocDirectoryX on Directory {
  Directory get dartOut => dirTo(['lib', 'src', 'generated']);

  File get descriptorSetOut => fileTo([
        'proto',
        'generated',
        'descriptor',
      ]);

  Directory get protoPath => dirTo(['proto']);

  File pbFile(String package) => dartOut.file('$package.pb.dart');

  File pbenumFile(String package) => dartOut.file('$package.pbenum.dart');

  File pbmetaFile(String package) => dartOut.file('$package.pbmeta.dart');
}

Future<void> runProtoc({
  String? packageName,
  List<String> dependencies = const [],
}) async {
  packageName ??= await packageNameFromPubspec();
  final cwd = Directory.current;
  final dartOut = cwd.dartOut;
  await dartOut.create(recursive: true);
  await cwd.descriptorSetOut.parent.create(recursive: true);

  await cwd.run(
    "protoc",
    [
      "--dart_out=${dartOut.path}",
      '--descriptor_set_out=${cwd.descriptorSetOut.path}',
      "--proto_path=${cwd.protoPath.path}",
      for (final dep in dependencies) "--proto_path=${await _protoPath(dep)}",
      cwd.protoPath.file("$packageName.proto").path,
    ],
  );

  for (final dep in dependencies) {
    Future<void> create(File Function(Directory dir) type) async {
      final file = type(cwd);
      final content = "export 'package:$dep/$dep.dart';";
      await file.writeAsString(content);
    }

    await create((d) => d.pbFile(dep));
    await create((d) => d.pbenumFile(dep));
  }
}

Future<String> _protoPath(String package) async {
  final root = await packageRootDir(package);
  return root.protoPath.path;
}
