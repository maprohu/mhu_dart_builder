import 'dart:io';

import 'package:mhu_dart_commons/io.dart';
import 'package:mhu_dart_commons/commons.dart';

import '../protoc.dart';
import '../source_gen/source_generator.dart';
import '../source_gen/class_gen.dart';
import 'proto_root.dart';
import 'protoc_plugin.dart';

Future<void> runProtoMetaGenerator(
  String packageName, {
  List<String> dependencies = const [],
}) async {
  final cwd = Directory.current;

  final metaFile = cwd.protoMetaFile(packageName);

  final content = [
    r"import 'dart:core' as $core;",
    r"import 'package:fixnum/fixnum.dart' as $fixnum;",
    r"import 'package:mhu_dart_commons/commons.dart' as $commons;",
    r"import 'package:mhu_dart_proto/mhu_dart_proto.dart' as $proto_meta;",
    r"import 'package:protobuf/protobuf.dart' as $protobuf;",
    r"import 'package:fast_immutable_collections/fast_immutable_collections.dart';",
    "import '${cwd.pbFile(packageName).filename}';",
    generateProtoMeta(
      'MhuLib',
      Directory.current.file('proto/generated/descriptor').readAsBytesSync(),
    ),
  ];

  await metaFile.parent.create(recursive: true);
  await metaFile.writeAsString(
    content.join("\n").formattedDartCode(
          cwd.fileTo(
            ['.dart_tool', 'mhu', metaFile.filename],
          ),
        ),
  );
  stdout.writeln(
    "wrote: ${metaFile.uri}",
  );
}

String generateProtoMeta(String name, List<int> descriptorFileBytes) => PmgRoot(
      descriptorFileBytes,
      PmgCtx(descriptorFileBytes, name),
    ).generate();

const notSet = 'notSet';

/** [RxVarImplOpt] */
const TRxVarOpt = 'RxVarImplOpt';

final listClass = ClassGen(name: core(List));

const commonsPrefix = r'$commons';
const protoMetaPrefix = r'$proto_meta';
const protobufPrefix = r'$protobuf';

extension ClassGenProtoX on ClassGen {
  ClassGen get fromCommons => copyWith(
        prefix: commonsPrefix,
      );

  ClassGen get fromProtobuf => copyWith(
        prefix: protobufPrefix,
      );

  ClassGen get fromProtoMeta => copyWith(
        prefix: protoMetaPrefix,
      );
}

String core(Type type) => ProtocPlugin.core(type);

class PmgCtx {
  final String name;
  final List<int> descriptorFileBytes;

  PmgCtx(this.descriptorFileBytes, this.name);

  late final protoc = ProtocPlugin(descriptorFileBytes);

  late final nameCap = name.capitalize();
  late final nameUncap = name.uncapitalize();

  late final libInstanceClassName = nameCap;
  late final libStaticClassName = "$libInstanceClassName\$";

  late final libInstanceClassGen = ClassGen(name: libInstanceClassName);
  late final libInstanceGeneric = libInstanceClassGen.asGenericArg;
}
