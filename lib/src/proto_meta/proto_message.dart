import 'package:collection/collection.dart';
import 'package:mhu_dart_builder/src/proto_meta/proto_meta_generator.dart';
import 'package:mhu_dart_builder/src/proto_meta/proto_root.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_builder/src/source_gen/typ.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';
import '../source_gen/class_gen.dart';
import '../source_gen/data_class_gen.dart';
import '../source_gen/gen.dart';
import '../source_gen/generic.dart';
import '../source_gen/param.dart';
import '../source_gen/prop.dart';
import 'proto_enum.dart';
import 'proto_field.dart';
import 'proto_frp.dart';
import 'proto_oneof.dart';

class PmgMsg extends TopGen {
  final PdMsg<PmgMsg, PmgFld, PmgEnum> msg;
  final PmgCtx ctx;

  PmgMsg.create(this.msg, this.ctx);

  late final messageName = msg.name;
  late final nameUncap = messageName.uncapitalize();
  late final descriptor = msg.descriptor;

  late final fields = msg.fields.map((e) => e.payload);

  late final singleFields = fields.where((f) => f.fld.isSingle);
  late final collectionFields = fields.where((f) => f.fld.isCollection);

  late final oneOfs =
      descriptor.oneofDecl.mapIndexed((i, e) => PmgOneOf(this, e, i));

  late final messageClassName = msg.path.map((e) => e.name).join('_');

  late final messageClassGen = ClassGen(name: messageClassName);
  late final qualifiedNameUncap =
      msg.path.map((e) => e.payload.nameUncap).join('\$');
  late final varName = messageClassName.uncapitalize();
  late final staticClassName = '$messageClassName\$';
  late final metaClassName = '$messageClassName\$\$';

  // late final metaClassName = '$messageClassName\$Meta\$';
  late final instanceVarName = 'instance\$';
  late final instanceReference = '$staticClassName.$instanceVarName';

  late final libName = ctx.libInstanceClassName;
  late final libInstanceGeneric = ctx.libInstanceGeneric;

  late final nestedMessages =
      msg.messages.whereNot((e) => e.isMapEntry).map((e) => e.payload);

  late final nestedEnums = msg.enums.payloads;

  late final nestedMessageType = pmMessageCls.nameWithPrefix;

  late final createMethod = [
    'static $messageClassName create(',
    fields
        .map((f) => '${f.typ.withoutNullability}? ${f.name}')
        .plusCommas
        .paramsCurly,
    ') {',
    'final o = $messageClassName();',
    for (final f in fields) ...[
      'if (${f.name} != null) {',
      switch (f.fld.cardinality) {
        PdfSingle() => 'o.${f.name} = ${f.name};',
        _ => 'o.${f.name}.addAll(${f.name});'
      },
      '}',
    ],
    'return o;',
    '}',
  ];

  late final staticClassSrc = 'abstract class $staticClassName'.andCurly([
    'const $staticClassName._();',
    'static const index\$ = ${msg.index};',
    'static const globalIndex\$ = ${msg.globalIndex};',
    'static const $instanceVarName = $metaClassName();',
    ...fields.map((e) => e.staticSrc),
    ...oneOfs.map((e) => e.staticSrc),
    'static const nestedMessages\$ = ${nestedMessageType.chevrons}'.andSquare(
      nestedMessages.map((e) => '${e.instanceReference},'),
    ),
    ';',
    'static const nestedEnums\$ = ${pmEnumCls.nameWithPrefix.chevrons}'
        .andSquare(
      nestedEnums.map((e) => '${e.instanceReference},'),
    ),
    ';',
    'static const fields\$ = <${pmFieldOfMessageCls.nameWithPrefix}${messageLibMetaGenerics.commasGenerics}>'
        .andSquare(
      fields.map((e) => '${e.name},'),
    ),
    ';',
    'static const oneofs\$ = <${pmOneofOfMessageCls.nameWithPrefix}<$messageClassName>>'
        .andSquare(
      oneOfs.map((e) => '${e.name},'),
    ),
    ';',
    ...createMethod,
  ]);

  // TODO migrate staticClassSrc
  late final staticClassGen = ClassGen(
    name: staticClassName,
  );

  late final messageGeneric = messageClassGen.asGenericArg;

  late final messageLibGenerics = [messageGeneric, libInstanceGeneric];

  late final parentMessage = msg.parent.toMessage().payload;

  late final libMetaGenerics = <String>[];
  late final prxLibMetaGenericNames = [libName];
  late final messageLibMetaGenerics = <String>[messageClassName];

  late final superClass = msg.isTopLevel
      ? '${pmTopLevelMessageCls.nameWithPrefix}${messageLibMetaGenerics.commasGenerics}'
      : '${pmNestedMessageCls.nameWithPrefix}${[
          messageClassName,
          ...libMetaGenerics
        ].commasGenerics}';

  late final thisTypeGen = GenString(
    'R thisType\$<R>(R Function<TF>() fn) => fn<$metaClassName>();',
  );

  late final metaClassSrc =
      'class $metaClassName extends $superClass'.andCurly([
    'const $metaClassName();',
    '${pmLibCls.nameWithPrefix} get pmLib\$ => ${ctx.libInstanceVarName};',
    'final index\$ = $staticClassName.index\$;',
    'final globalIndex\$ = $staticClassName.globalIndex\$;',
    '$messageClassName get emptyMessage\$ => $messageClassName()..freeze();',
    '${core(List)}${nestedMessageType.chevrons} get nestedMessages\$ => $staticClassName.nestedMessages\$;',
    '${core(List)}${pmEnumCls.nameWithPrefix.chevrons} get nestedEnums\$ => $staticClassName.nestedEnums\$;',
    if (!msg.isTopLevel)
      '${parentMessage.metaClassName} get parent\$ => ${parentMessage.instanceReference};',
    ...fields.map((e) => e.metaSrc),
    '$protoMetaPrefix.FieldsList${messageLibMetaGenerics.commasGenerics} get fields\$ => $staticClassName.fields\$;',
    '$protoMetaPrefix.OneOfs<$messageClassName> get oneofs\$ => $staticClassName.oneofs\$;',
    thisTypeGen.src
  ]);

  // TODO migrate metaClassSrc
  late final metaClassGen = ClassGen(
    name: metaClassName,
  );

  late final messageClassExtensionGen = messageClassGen.extensionGen([
    ...oneOfs.map((e) => e.extensionSrc),
    ...fields.map((e) => e.extensionSrc),
  ].join());

  late final extensionSrc = messageClassExtensionGen.src;

  late final fieldOverridesClassName = '$messageClassName\$FieldOverrides';

  late final fieldOverridesGen = RecordGen(
    name: fieldOverridesClassName,
    params: fields
        .map((e) => Param.simple(type: result.toTyp(), name: e.nameUncap)),
    generics: [Generic(result)],
    intType: core(int),
    commonType: '$result?',
  );

  late final overridesSrc = [
    fieldOverridesGen.dataClassSrc,
    fieldOverridesGen.indexOperatorExtensionSrc,
  ].join();

  late final frp = ProtoFrp(this);

  @override
  late final src = [
    staticClassSrc,
    metaClassSrc,
    extensionSrc,
    overridesSrc,
    oneOfs.srcsJoin,
    fields.srcsJoin,
    frp.src,
  ].join();

  late final prop = Prop(type: messageClassName.toTyp(), name: varName);
}
