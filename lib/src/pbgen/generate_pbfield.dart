import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mhu_dart_builder/src/protoc.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_builder/src/srcgen.dart';
import 'package:mhu_dart_commons/io.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';
import 'package:protobuf/protobuf.dart';
import 'package:recase/recase.dart';

import '../resources.dart';

Future<void> runPbFieldGenerator({
  String? packageName,
  required PbiLib lib,
}) async {
  packageName ??= await packageNameFromPubspec();

  final cwd = Directory.current;

  final metaFile = cwd.pbfieldFile(packageName);

  final content = generatePbFieldDart(
    package: packageName,
    lib: lib,
  );

  await metaFile.parent.create(recursive: true);
  await metaFile.writeAsString(
    content.formattedDartCode(
      cwd.fileTo(
        ['.dart_tool', 'mhu', metaFile.filename],
      ),
    ),
  );
  stdout.writeln(
    "wrote: ${metaFile.uri}",
  );
}

String generatePbFieldDart({
  required String package,
  required PbiLib lib,
}) {
  const mdp = r"$mdp";
  const mdc = r"$mdc";

  String fldgen(PbiMessage msg, FieldInfo fieldInfo) {
    final access = fieldInfo.accessForMessage(msg);
    final msgCls = msg.instance.runtimeType.toString();

    final fieldInfoRef =
        "$msgCls.getDefault().info_.byIndex[${fieldInfo.index}].cast()";

    final accessClassName = access.runtimeType;

    return "$mdp.$accessClassName($fieldInfoRef,)";
  }

  String oogen(PbiMessage msg, int oneofIndex, String name) {
    final msgCls = msg.instance.runtimeType.toString();
    return [
      "$mdp.OneofFieldAccess(",
      "oneofIndex: $oneofIndex,",
      "builderInfo: $msgCls.getDefault().info_,",
      "options: ${msgCls}_${name.pascalCase}.values,"
          ")",
    ].joinLines;
  }

  return [
    "import 'package:mhu_dart_proto/mhu_dart_proto.dart' as $mdp;",
    "import 'package:mhu_dart_commons/commons.dart' as $mdc;",
    for (final dep in lib.allImportedLibraries)
      "import '${protoImportUri(dep.name)}';",
    "import '$package.pb.dart';",
    for (final msg in lib.messages) ...[
      'class ${msg.instance.runtimeType}\$ {',
      for (final fld in msg.builderInfo.byIndex) ...[
        'static final ${fld.name} = ${fldgen(msg, fld)};'
      ],
      ...msg.oneofs.mapIndexed(
        (index, oo) =>
            'static final ${oo.camelCase} = ${oogen(msg, index, oo)};',
      ),
      '}',
    ],
  ].joinLines;
}
