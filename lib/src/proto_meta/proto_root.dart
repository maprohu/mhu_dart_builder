import 'package:collection/collection.dart';
import 'package:mhu_dart_builder/src/proto_meta/proto_meta_generator.dart';
import 'package:mhu_dart_builder/src/source_gen/gen.dart';
import 'package:mhu_dart_builder/src/source_gen/reflect.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_builder/src/source_gen/typ.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';
import 'package:protobuf/protobuf.dart';

import '../source_gen/class/constr.dart';
import '../source_gen/class_gen.dart';
import '../source_gen/data_class_gen.dart';
import '../source_gen/generic.dart';
import '../source_gen/mthd.dart';
import '../source_gen/param.dart';
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

  // final String name;

  PmgRoot(this.descriptorFileBytes, this.ctx)
      : super(
          descriptorSet: FileDescriptorSet.fromBuffer(descriptorFileBytes),
          enm: (enm) => PmgEnum.create(enm),
          fld: (fld) => PmgFld.create(fld, ctx),
          msg: (msg) => PmgMsg.create(msg, ctx),
        );

  late final pmgMessages = messages.expand(
      (e) => e.hierarchy.whereNot((e) => e.isMapEntry).map((e) => e.payload));

  late final pmgEnums = enums.payloads;

  late final descriptorJson = descriptorSet.writeToJson();

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
    'static const descriptor\$ = r\'$descriptorJson\';'
        "static const instance\$ = $instanceFileClassName._();",
    ...pmgMessages
        .map((e) => 'static const ${e.nameUncap} = ${e.instanceReference};'),
    ...pmgEnums
        .map((e) => 'static const ${e.nameUncap} = ${e.instanceReference};'),
  ]);

  late final messageTypeSrc = pmMessageCls.nameWithPrefix;
  late final enumTypeSrc = pmEnumCls.nameWithPrefix;

  late final messageOfType = [
    'static final messageByType = {',
    for (final msg in pmgMessages)
      '${msg.messageClassName}: ${msg.instanceReference},',
    '}.toIMap();',
    '${pmMessageOfTypeCls.nameWithPrefix}<T> messageOfType<T extends ${generatedMessageCls.nameWithPrefix}>() => messageByType[T]!.cast();',
  ];

  late final instanceLibClassGen = ClassGen(
    name: instanceFileClassName,
    superClass: pmLibCls,
    constructorsFn: (self) => [Constr(owner: self, name: '_', cnst: true)],
    content: (self) => [
      'static const instance = ${self.name}._();',
      '${core(List)}<$messageTypeSrc> get messages => $staticFileClassName.messages\$;',
      '${core(List)}<$enumTypeSrc> get enums => $staticFileClassName.enums\$;',
      '${core(String)} get descriptor => $staticFileClassName.descriptor\$;',
      ...messageOfType,
    ].join().asContent,
  );

  /*
    static final messageByType = {
    CmnTimestampMsg:  CmnTimestampMsg$.instance$,
  }.toIMap();

  PmMessageOfType<T> messageOfType<T extends GeneratedMessage>() => messageByType[T]!.cast();
   */
  late final libExtensionSrc = instanceLibClassGen.extension([
    // '$messageFieldOverridesClassName<T> fieldOverrides<T>() => $messageFieldOverridesClassName();',
  ].join());

  late final instanceLibSrc = instanceLibClassGen.src;

  // late final messageOverridesClassName = '${ctx.nameCap}\$MessageOverrides';

  // late final messageFieldOverridesClassName =
  //     '${ctx.nameCap}\$MessageFieldOverrides';

  // late final enumOverridesClassName = '${ctx.nameCap}\$EnumOverrides';

  // late final messageOverridesGen = RecordGen(
  //   name: messageOverridesClassName,
  //   params: nonMapEntryMessagesFlattened.payloads.mapIndexed((i, e) {
  //     assert(i == e.msg.globalIndex);
  //
  //     final mthd = Mthd(
  //       params: [
  //         Param.simple(
  //           name: 'msg',
  //           type: e.metaClassGen.typ,
  //         )
  //       ],
  //       name: e.qualifiedNameUncap,
  //       type: result.toTyp(nullable: false),
  //     );
  //
  //     return Param.fromProp(
  //       mthd.functionProp.withNullable(true),
  //     ).copyWith(
  //       requirement: ParamRequirement.optional,
  //     );
  //
  //     // return Param.simple(
  //     //   type: result.toTyp(nullable: true),
  //     //   name: e.qualifiedNameUncap,
  //     // ).copyWith(
  //     //   requirement: ParamRequirement.optional,
  //     // );
  //   }),
  //   generics: [Generic(result)],
  //   intType: core(int),
  //   commonType: '$result?',
  //   returnValue: (index, param, ref) =>
  //       '$ref?.call(${nonMapEntryMessagesFlattened[index].payload.instanceReference})',
  // );

  // late final messageFieldOverridesGen = RecordGen(
  //   name: messageFieldOverridesClassName,
  //   params: nonMapEntryFieldsFlattened.payloads.mapIndexed(
  //     (i, e) {
  //       assert(i == e.fld.globalIndex);
  //
  //       final mthd = Mthd(
  //         params: [
  //           Param.simple(
  //             name: 'fld',
  //             type: e.classGen.typ,
  //           )
  //         ],
  //         name: e.qualifiedNameUncap,
  //         type: result.toTyp(nullable: false),
  //       );
  //
  //       return Param.fromProp(
  //         mthd.functionProp.withNullable(true),
  //       ).copyWith(
  //         requirement: ParamRequirement.optional,
  //       );
  //     },
  //   ),
  //   intType: core(int),
  //   commonType: '$result?',
  //   generics: [Generic(result)],
  //   returnValue: (index, param, ref) =>
  //       '$ref?.call(${nonMapEntryFieldsFlattened[index].payload.staticRef})',
  // );

  late final overridesSrc = [
    // messageFieldOverrideFactoryClassGen.src,
    // messageOverridesGen.dataClassSrc,
    // messageOverridesGen.indexOperatorExtensionSrc,
    // messageFieldOverridesGen.indexOperatorExtensionSrc,
    // messageFieldOverridesGen.dataClassSrc,
    // messageFieldOverridesIndexOperatorExtensionSrc,
  ].join();

  String generate() => [
        '// ignore_for_file: annotate_overrides',
        '// ignore_for_file: unnecessary_this',
        '// ignore_for_file: camel_case_types',
        '// ignore_for_file: camel_case_extensions',
        'const ${ctx.nameUncap} = $instanceFileClassName.instance;',
        staticLibSrc,
        instanceLibSrc,
        libExtensionSrc,
        overridesSrc,
        pmgMessages.map((e) => e.src).join(),
        ...enums.map((e) => e.payload.globalSrc),
      ].join('\n');

/*
            PdRoot$Data(
            msgPayload: (msg) => PmgMsg.create(msg, ctx),
            fldPayload: (fld) => PmgFld.create(fld, ctx),
            enumPayload: PmgEnum.create,
            descriptorSet:
                FileDescriptorSet.fromBuffer(descriptorFileBytes).asConstant(),
          ),
   */
}
