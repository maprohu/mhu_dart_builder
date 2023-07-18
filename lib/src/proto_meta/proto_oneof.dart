
import 'package:mhu_dart_builder/src/proto_meta/proto_meta_generator.dart';
import 'package:mhu_dart_builder/src/source_gen/gen.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';
import '../source_gen/class/constr.dart';
import '../source_gen/class/field.dart';
import '../source_gen/class/method.dart';
import '../source_gen/class_gen.dart';
import '../source_gen/generic.dart';
import '../source_gen/mthd.dart';
import '../source_gen/param.dart';
import '../source_gen/source_generator.dart';
import '../source_gen/typ.dart';
import '../source_gen/when_class_gen.dart';
import '../source_gen/when_method_gen.dart';
import 'proto_field.dart';
import 'proto_message.dart';
import 'proto_root.dart';


const notSet = 'notSet';

class PmgOneOf extends TopGen {
  final PmgMsg msg;
  final OneofDescriptorProto descriptor;
  final int index;

  PmgOneOf(this.msg, this.descriptor, this.index);

  late final name = descriptor.name;
  late final nameCap = name.capitalize();
  late final messageClassName = msg.messageClassName;

  late final fieldClassName = '${msg.metaClassName}OneOf\$$name';

  late final staticSrc = 'static const $name = $fieldClassName._();';

  late final enumName = '${messageClassName}_$nameCap';

  late final enumClassGen = ClassGen(name: enumName);

  late final fields = msg.fields.where((e) => e.oneofIndex == index);

  late final whenMethodName = 'when$nameCap';

  late final instanceReference = '${msg.staticClassName}.$name';

  late final extensionSrc = [
    '$result $whenMethodName<$result>'.andParenCurly([
      '$result Function()? $fallbackVar,',
      '$result Function()? $notSet,',
      ...fields
          .map((e) => '$result Function(${e.param.declare})? ${e.prop.name},'),
    ]),
    [
      'switch ($whichMethodName())'.andCurly([
        ...fields.map((e) =>
            'case $enumName.${e.name}: if (${e.prop.name} != null) { return ${e.prop.name}(this.${e.getterName}); } else if ($fallbackVar != null) { return $fallbackVar(); } else { throw this; }'),
        'case $enumName.$notSet: if ($notSet != null) { return $notSet(); } else if ($fallbackVar != null) { return $fallbackVar(); } else { throw this; }',
      ]),
    ].curly,
  ].join();

  late final whichMethodName = 'which$nameCap';

  late final classGen = ClassGen(
    name: fieldClassName,
    superClass: pmOneofOfMessageOfTypeCls.copyWith(
      generics: [
        msg.messageGeneric,
        enumClassGen.asGenericArg,
      ],
    ),
    constructorsFn: (self) => [
      Constr(
        owner: self,
        name: '_',
        cnst: true,
      ),
    ],
    content: (self) => [
      MethodGen(
        mthd: Mthd(
          name: 'which',
          type: enumClassGen.typ,
          params: [
            Param.simple(
              name: 'message',
              type: msg.prop.type,
            ),
          ],
        ),
        body: (self) => self.firstParam.name
            .callMethod(whichMethodName)
            .asExpressionBody(self),
      ),
      MethodGen(
        mthd: Mthd(
          name: 'clear',
          type: Typ.voidType(),
          params: [
            Param.simple(
              name: 'message',
              type: msg.prop.type,
            ),
          ],
        ),
        body: (self) => self.firstParam.name
            .callMethod('clear$nameCap')
            .asExpressionBody(self),
      ),
      MethodGen(
        mthd: Mthd(
          name: 'values',
          type: listClass.copyWith(generics: [enumClassGen.asGenericArg]).typ,
          params: [
            // Param.fromProp(msg.prop),
          ],
        ),
        body: '$enumName.values'.asExpressionBody,
      ),
      MethodGen(
        mthd: Mthd(
          name: 'get',
          type: valueClassGen.typ,
          params: [
            Param.fromProp(msg.prop),
          ],
        ),
        body: (self) => self.firstParam.name.callMethod(
          whenMethodName,
          [
            'notSet: () => const ${whenClassGen.classes.first.classGen.name}._(null),',
            ...whenClassGen.classes.tail.map(
              (e) => '${e.alias}: ${e.classGen.name}._,',
            ),
          ],
        ).asExpressionBody(self),
      )
    ],
  );

  late final valueClassGen = whenClassGen.classGen.copyWith(
    generics: [
      Generic.ofDynamicCore,
      Generic.ofVoid,
      ...fields.map((e) => e.typ.asGeneric),
    ],
  );

  static const valueFieldName = '_value';

  WhenMethodClassGen baseWhenMethodClassGen({
    required WhenMethodGen gen,
    required bool responder,
  }) =>
      WhenMethodClassGen(
        gen: gen,
        alias: 'notSet',
        callbackParams: (self) => [],
        responder: responder,
      );

  WhenMethodClassGen concreteWhenMethodClassGen({
    required WhenMethodGen gen,
    required bool responder,
    required PmgFld field,
  }) =>
      WhenMethodClassGen(
        gen: gen,
        alias: field.nameUncap,
        callbackParams: (self) => [field.param],
        responder: responder,
      );

  late final WhenMethodGen baseWhenMethodGen = WhenMethodGen(
    methodName: 'when',
    classes: (gen) => [
      baseWhenMethodClassGen(gen: gen, responder: true),
      ...fields.map(
        (f) => concreteWhenMethodClassGen(
          gen: gen,
          responder: false,
          field: f,
        ),
      ),
    ],
    callbackValues: (self) => [],
  );

  // late final extGetter = GetterGen(
  //   prop: Prop(
  //     name: name.andDollar,
  //     type: iRxValOptOf(valueClassGen).typ,
  //   ),
  //   body: 'mapOpt($instanceReference.get)'.asExpressionBody,
  // );

  // late final prxItemOfLib = itemOfLib.copyWith(generics: [
  //   msg.messageRxValOptClassGen.asGenericArg,
  //   msg.libInstanceGeneric,
  // ]);

  // late final rxValExtension = msg.messageRxValOptClassGen.extensionGen(
  //   [
  //     extGetter,
  //   ].srcsJoin,
  //   suffix: '\$${classGen.name}Ext',
  //   generics: [],
  // );

  // late final libRxValExtension = prxItemOfLib.extensionGen(
  //   [
  //     extGetter.copyWith(
  //       body: 'item'.andDot.followedBy(extGetter.prop.name).asExpressionBody,
  //     ),
  //   ].srcsJoin,
  //   suffix: '\$${classGen.name}LibExt',
  //   generics: [],
  // );

  late final whenClassGen = WhenClassGen(
    name: fieldClassName.followedBy('\$When'),
    options: [
      notSet,
      ...fields.map((e) => e.name),
    ],
  );

  @override
  late final src = [
    classGen,
    whenClassGen,
  ].srcsJoin;
}

class PmgOneOfOption extends TopGen {
  final PmgOneOf oneof;
  final PmgFld field;

  late final valueClassGen = oneof.valueClassGen;

  late final prop = field.prop.copyWith(name: PmgOneOf.valueFieldName);

  late final param = Param.fromProp(prop);
  late final classGen = ClassGen(
    name: '${valueClassGen.name}\$${field.name}',
    superClass: valueClassGen,
    constructorsFn: (self) => [
      Constr(
        owner: self,
        params: [
          param.copyWith(target: ParamTarget.thisTarget),
        ],
        cnst: true,
        name: '_',
        body: (self) => ': super._();',
      ),
    ],
    content: (self) => [
      FieldGen(prop),
      WhenMethodGen(
        methodName: 'when',
        classes: (gen) => [
          oneof.baseWhenMethodClassGen(
            gen: gen,
            responder: false,
          ),
          ...oneof.fields.map(
            (f2) => oneof.concreteWhenMethodClassGen(
              gen: gen,
              responder: field == f2,
              field: f2,
            ),
          ),
        ],
        callbackValues: (self) => [PmgOneOf.valueFieldName],
      )
    ],
  );

  @override
  late final src = classGen.src;

  PmgOneOfOption({
    required this.oneof,
    required this.field,
  });
}
