import 'package:collection/collection.dart';
import 'package:mhu_dart_builder/src/proto_meta/proto_meta_generator.dart';
import 'package:mhu_dart_builder/src/source_gen/gen.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';
import 'package:protobuf/protobuf.dart';
import 'package:recase/recase.dart';

import '../source_gen/class/constr.dart';
import '../source_gen/class_gen.dart';
import 'proto_enum.dart';
import 'proto_field.dart';
import 'proto_message.dart';

final pmMessageCls = ClassGen.fromTypeDynamic(PmMessage).fromProtoMeta;
final pmEnumCls = ClassGen.fromTypeDynamic(PmEnum).fromProtoMeta;
final pmLibCls = ClassGen.fromTypeDynamic(PmLib).fromProtoMeta;
final pmMessageOfTypeCls =
    ClassGen.fromTypeDynamic(PmMessageOfType).fromProtoMeta;
final generatedMessageCls =
    ClassGen.fromTypeDynamic(GeneratedMessage).fromProtobuf;
final pmFieldOfMessageCls =
    ClassGen.fromTypeDynamic(PmFieldOfMessage).fromProtoMeta;
final pmOneofOfMessageCls =
    ClassGen.fromTypeDynamic(PmOneofOfMessage).fromProtoMeta;
final pmTopLevelMessageCls =
    ClassGen.fromTypeDynamic(PmTopLevelMessage).fromProtoMeta;
final pmNestedMessageCls =
    ClassGen.fromTypeDynamic(PmNestedMessage).fromProtoMeta;
final pmMapFieldCls = ClassGen.fromTypeDynamic(PmMapField).fromProtoMeta;
final pmMessageFieldCls =
    ClassGen.fromTypeDynamic(PmMessageField).fromProtoMeta;
final pmSingleFieldCls = ClassGen.fromTypeDynamic(PmSingleField).fromProtoMeta;
final pmRepeatedFieldCls =
    ClassGen.fromTypeDynamic(PmRepeatedField).fromProtoMeta;
final pmOneofOfMessageOfTypeCls =
    ClassGen.fromTypeDynamic(PmOneofOfMessageOfType).fromProtoMeta;

class PmgRoot extends PdRoot<PmgMsg, PmgFld, PmgEnum> {
  final PmgCtx ctx;
  final List<int> descriptorFileBytes;

  final Iterable<PmgCtx> importedLibs;

  PmgRoot(
    this.descriptorFileBytes,
    this.ctx, {
    this.importedLibs = const Iterable.empty(),
  }) : super(
          descriptorProto:
              FileDescriptorSet.fromBuffer(descriptorFileBytes).file.single,
          enm: (enm) => PmgEnum.create(enm, ctx),
          fld: (fld) => PmgFld.create(fld, ctx),
          msg: (msg) => PmgMsg.create(msg, ctx),
          importedDescriptorProtos: importedLibs.map(
            (bytes) => FileDescriptorSet.fromBuffer(bytes.descriptorFileBytes)
                .file
                .single,
          ),
        );

  late final pmgMessages = messages.expand(
      (e) => e.hierarchy.whereNot((e) => e.isMapEntry).map((e) => e.payload));

  late final pmgEnums = enums.payloads;

  late final descriptorJson = descriptorProto.writeToJson();

  late final staticFileClassName = ctx.libStaticClassName;
  late final instanceFileClassName = ctx.libInstanceClassName;

  late final staticLibSrc = 'abstract class $staticFileClassName'.andCurly([
    'const $staticFileClassName._();',
    'static const messages\$ = <$messageTypeSrc>'.andSquare(
      messages.map((e) => '${e.payload.nameUncap},'),
    ),
    ';',
    'static const enums\$ = <$enumTypeSrc>'.andSquare(
      enums.map((e) => '${e.payload.nameUncap},'),
    ),
    ';',
    'static const importedLibs\$ = <${pmLibCls.nameWithPrefix}>'.andSquare(
      importedLibs.map((e) => '${e.libInstanceVarName},'),
    ),
    ';',
    'static const descriptor\$ = r\'$descriptorJson\';'
        "static const instance\$ = $instanceFileClassName._();",
    ...pmgMessages
        .map((e) => 'static const ${e.nameUncap} = ${e.instanceReference};'),
    ...pmgEnums
        .map((e) => 'static const ${e.nameUncap} = ${e.instanceReference};'),
  ]);

  late final messageTypeSrc = pmMessageCls.nameWithPrefix;
  late final enumTypeSrc = pmEnumCls.nameWithPrefix;

  // late final messageOfType = [
  //   'static final messageByType = {',
  //   for (final msg in pmgMessages)
  //     '${msg.messageClassName}: ${msg.instanceReference},',
  //   '}.toIMap();',
  //   '${pmMessageOfTypeCls.nameWithPrefix}<T>? messageOfType<T extends ${generatedMessageCls.nameWithPrefix}>() => messageByType[T]?.cast();',
  // ];

  late final instanceLibClassGen = ClassGen(
    name: instanceFileClassName,
    superClass: pmLibCls,
    constructorsFn: (self) => [Constr(owner: self, name: '_', cnst: true)],
    content: (self) => [
      'static const instance = ${self.name}._();',
      '${core(List)}<$messageTypeSrc> get messages => $staticFileClassName.messages\$;',
      '${core(List)}<$enumTypeSrc> get enums => $staticFileClassName.enums\$;',
      '${core(List)}<${pmLibCls.nameWithPrefix}> get importedLibs => $staticFileClassName.importedLibs\$;',
      '${core(String)} get fileDescriptorProtoJson => $staticFileClassName.descriptor\$;',
      // ...messageOfType,
    ].join().asContent,
  );

  late final instanceLibSrc = instanceLibClassGen.src;

  String generate() => [
        '// ignore_for_file: annotate_overrides',
        '// ignore_for_file: unnecessary_this',
        '// ignore_for_file: camel_case_types',
        '// ignore_for_file: camel_case_extensions',
        '// ignore_for_file: unused_field',
        '// ignore_for_file: unused_import',
        'const ${ctx.libInstanceVarName} = $instanceFileClassName.instance;',
        staticLibSrc,
        instanceLibSrc,
        pmgMessages.map((e) => e.src).join(),
        ...enums.map((e) => e.payload.globalSrc),
      ].join('\n');
}
