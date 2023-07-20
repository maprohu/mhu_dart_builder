import 'dart:io';

import 'package:mhu_dart_commons/io.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:resource_portable/resource_portable.dart';

Future<Directory> packageRootDir(String package) async {
  final resource = Resource("package:$package/.");
  final uri = await resource.uriResolved;
  return Directory(uri.toFilePath()).parent;
}

Future<String> packageNameFromPubspec([Directory? cwd]) async {
  cwd ??= Directory.current;
  final pubSpecYaml = cwd.file('pubspec.yaml');
  final pubspec = Pubspec.parse(await pubSpecYaml.readAsString());
  return pubspec.name;
}
