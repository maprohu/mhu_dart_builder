import 'package:mhu_dart_builder/src/proto_meta/proto_meta_generator.dart';
import 'package:mhu_dart_builder/src/source_gen/class/method.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_builder/src/source_gen/typ.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';
import '../source_gen/class/constr.dart';
import '../source_gen/class_gen.dart';
import '../source_gen/gen.dart';
import '../source_gen/generic.dart';
import '../source_gen/mthd.dart';
import '../source_gen/param.dart';
import '../source_gen/prop.dart';
import '../source_gen/reflect.dart';
import 'proto_enum.dart';
import 'proto_message.dart';
import 'proto_root.dart';


class PmgFld extends TopGen {
  final PdFld<PmgMsg, PmgFld, PmgEnum> fld;
  final PmgCtx ctx;

  PmgFld.create(this.fld, this.ctx);

  late final descriptor = fld.descriptor;

  late final name = fld.name;
  late final nameCap = name.capitalize();
  late final nameUncap = name.uncapitalize();
  late final qualifiedNameUncap = '${msg.qualifiedNameUncap}\$\$$nameUncap';

  late final getterName = name;

  late final msg = fld.msg.payload;
  late final messageClassName = msg.messageClassName;

  // late final fieldClassName = '${msg.metaClassName}Field\$$name';
  late final fieldClassName = '${msg.messageClassName}\$\$$name';
  late final staticRef = '${msg.staticClassName}.$name';

  late final staticSrc = 'static const $name = $fieldClassName._();';
  late final metaSrc = '$fieldClassName get $name => $staticRef;';

  late final mapKeyField = fld.mapKeyField.payload;
  late final mapValueField = fld.mapValueField.payload;
  late final mapFields = [mapKeyField, mapValueField];

  // late final Iterable<String> mapFieldTypeSrcs =
  //     mapFields.map((e) => e.typeSrc);

  late final Iterable<Generic> mapFieldGenerics =
      mapFields.map((e) => e.typeGeneric);

  late final superClass = () {
    if (fld.isMap) {
      return pmMapFieldCls.copyWith(
        generics: [
          messageGeneric,
          ...mapFieldGenerics,
        ],
      );
    } else if (fld.isSingle) {
      if (fld.isTypeMessage) {
        return pmMessageFieldCls.copyWith(generics: [
          messageGeneric,
          typeGeneric,
        ]);
      } else {
        return pmSingleFieldCls.copyWith(generics: [
          messageGeneric,
          typeGeneric,
        ]);
      }
    } else {
      return pmRepeatedFieldCls.copyWith(generics: [
        messageGeneric,
        singleTypeGeneric,
      ]);
    }
  }();

  late final extensionSrc = [
    if (fld.isSingle) ...[
      '${typ.withNullable(true).withNullability} get ${name}Opt => $staticRef.getOpt(this);',
      'set ${name}Opt(${typ.withNullable(true).withNullability} value) => $staticRef.setOpt(this, value);',
    ]
  ].join();

  // late final singleTypeSrc = () {
  //   if (fld.isTypeMessage) {
  //     return fld.resolvedMessage.payload.messageClassName;
  //   } else if (fld.isTypeEnum) {
  //     return fld.resolvedEnum.payload.enumClassName;
  //   } else {
  //     return ctx.protoc.typeOfField(descriptor);
  //   }
  // }();

  late final singleTyp = switch (fld.singleValueType) {
    PdfMessageType(:final pdMsg) => pdMsg.payload.messageClassGen.typ,
    PdfEnumType(:final pdEnum) => pdEnum.payload.enumClassGen.typ,
    PdfValueType() =>
      ctx.protoc.typeOfField(fld.singleValueField.descriptor).toTyp(),
  };

  late final singleTypeGeneric = singleTyp.asGeneric;

  // late final typeSrc = () {
  //   if (fld.isSingle) {
  //     return singleTypeSrc;
  //   } else if (fld.isMap) {
  //     return '${core(Map)}${mapFieldTypeSrcs.commasGenerics}';
  //   } else {
  //     return '${core(List)}<$singleTypeSrc>';
  //   }
  // }();

  late final Typ typ = switch (fld.cardinality) {
    PdfSingle() => singleTyp,
    PdfMapOf(:final fields) => ClassGen(
        name: core(Map),
        generics: [
          fields.key.payload.typeGeneric,
          fields.value.payload.typeGeneric,
        ],
      ).typ,
    PdfRepeated() => ClassGen(
        name: core(List),
        generics: [
          singleTypeGeneric,
        ],
      ).typ,
  };

  late final Generic typeGeneric = typ.asGeneric;

  late final prop = Prop(type: typ, name: name);

  late final param = Param.simple(name: name, type: typ);

  late final oneofIndex =
      descriptor.hasOneofIndex() ? descriptor.oneofIndex : null;

  late final messageGeneric = msg.messageGeneric;

  late final createBody = switch (fld.singleValueType) {
    PdfMessageType(:final pdMsg) =>
      pdMsg.payload.instanceReference.callMethod('emptyMessage\$.deepCopy'),
    PdfStringType() => "''",
    PdfIntType() => "0",
    PdfEnumType(:final pdEnum) =>
      '${pdEnum.payload.enumClassName}.values.first',
    PdfBoolType() => 'false',
    PdfBytesType() => 'const []',
    PdfDoubleType() => '0',

    // valueType: () => 'throw this',
    PdfValueType() => 'xxx',
  }
      .asExpressionBody;

  late final thisTypeGen = GenString(
    'R thisType\$<R>(R Function<TF>() fn) => fn<$fieldClassName>();',
  );

  late final classGen = ClassGen(
    name: fieldClassName,
    superClass: superClass,
    constructorsFn: (self) => [
      Constr(
        owner: self,
        name: '_',
        cnst: true,
      ),
    ],
    content: (self) => [
      [
        'final name = "$name";',
        '${pmMessageOfTypeCls.nameWithPrefix}${<String>[
          messageClassName,
          ...msg.libMetaGenerics
        ].commasGenerics} get message => ${msg.instanceReference};',
        '${core(int)} get index => ${fld.index};',
        '${core(int)} get globalIndex => ${fld.globalIndex};',
        '${typ.withNullability} get(${msg.messageClassName} message) => message.$name;',
        if (fld.isSingle) ...[
          'void set(${msg.messageClassName} message, ${typ.withNullability} value) => message.$name = value;',
          'void clear(${msg.messageClassName} message) => message.clear$nameCap();',
          '${core(bool)} has(${msg.messageClassName} message) => message.has$nameCap();',
          if (fld.isTypeMessage)
            '${typ.withNullability} ensure(${msg.messageClassName} message) => message.ensure$nameCap();',
        ],
      ].join().asGen,
      MethodGen(
        mthd: Mthd(
          name: 'create',
          type: singleTyp,
          params: [],
        ),
        body: createBody,
      ),
      thisTypeGen,
    ],
  );

  @override
  late final src = [
    classGen,
  ].srcsJoin;
}
