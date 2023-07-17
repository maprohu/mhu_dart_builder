import 'dart:io';

import 'package:mhu_dart_commons/io.dart';
import 'package:resource_portable/resource_portable.dart';

extension ProtocDirectoryX on Directory {
  Directory get dartOut => dirTo(['lib', 'proto']);

  File get descriptorSetOut => fileTo([
        'proto',
        'generated',
        'descriptor',
      ]);

  Directory get protoPath => dirTo(['proto']);

  File pbFile(String package) => dartOut.file('$package.pb.dart');
  File pbenumFile(String package) => dartOut.file('$package.pbenum.dart');
  File protoMetaFile(String package) =>  dartOut.file('${package}_meta.dart');
}

Future<void> runProtoc(
  String packageName, {
  List<String> dependencies = const [],
}) async {
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
    final depDir = Directory(dep).protoPath;
    Future<void> create(String type) async {
      await dartOut.file("$dep.$type.dart").writeAsString(
          "export 'package:${depDir.file("$dep.$type.dart").uri}';");
    }

    await create('pb');
    await create('pbenum');
  }
}

Future<String> _protoPath(String package) async {
  final resource = Resource("package:$package/.");
  final uri = await resource.uriResolved;
  return Directory(uri.toFilePath()).parent.protoPath.path;
}
