import 'dart:io';

import 'package:mhu_dart_commons/io.dart';

import 'pblib_model_a.dart' as lib;

Future<void> main() async {
  await lib.main();

  Directory.current.run(
    'dart',
    ['tool/pbfield_model_a.dart'],
  );

}