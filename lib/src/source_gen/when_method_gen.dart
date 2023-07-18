import 'package:mhu_dart_commons/commons.dart';

import '../proto_meta/proto_meta_generator.dart';
import 'source_generator.dart';
import 'typ.dart';
import 'class/method.dart';
import 'gen.dart';
import 'mthd.dart';
import 'param.dart';

const elseVarName = 'else\$';

class WhenMethodGen extends MemberGen {
  final String methodName;
  final Iterable<WhenMethodClassGen> Function(WhenMethodGen gen) classes;
  final Iterable<String> Function(WhenMethodClassGen self) callbackValues;
  final Typ? commonType;

  late final classGens = classes(this);

  late final optionalWhenParams = classGens.map((e) => e.optionalWhenParam);

  late final requiredWhenParams = classGens.map((e) => e.requiredWhenParam);

  late final responder = classGens.firstWhere((e) => e.responder);

  late final methodGen = MethodGen(
    mthd: Mthd(
      name: methodName,
      type: resultTyp,
      generics: [resultGeneric],
      params: optionalWhenParams,
    ),
    body: responder.alias
        .followedBy('!')
        .andParen(callbackValues(responder))
        .asExpressionBody,
  );

  late final requiredMethodHeaderGen = MethodGen(
    mthd: Mthd(
      name: methodName,
      type: resultTyp,
      generics: [resultGeneric],
      params: requiredWhenParams,
    ),
  );

  late final requiredMethodGen = requiredMethodHeaderGen.copyWith(
    body: responder.alias
        .andParen(
          callbackValues(responder),
        )
        .asExpressionBody,
  );

  late final elseMthd = Mthd(
    name: elseVarName,
    type: resultTyp,
    params: [
      ...commonType?.let((t) => [Param.simple(name: 'value', type: t)]) ?? [],
    ],
  );

  late final elseParam = Param(
    prop: elseMthd.functionProp,
    naming: ParamNaming.named,
    requirement: ParamRequirement.optional,
    defaultValue: '$commonsPrefix.throws1',
  );

  late final maybeMethodGen = MethodGen(
    mthd: Mthd(
      name: 'maybe${methodName.capitalize()}',
      type: resultTyp,
      generics: [resultGeneric],
      params: [
        ...optionalWhenParams,
        elseParam,
      ],
    ),
    body: methodName.thisRef
        .andParen(
          classGens.map((cls) => '${cls.alias}: ${cls.alias} ?? $elseVarName,'),
        )
        .asExpressionBody,
  );

  late final maybeMethodWithoutFallbackGen = MethodGen(
    mthd: Mthd(
      name: 'maybe${methodName.capitalize()}',
      type: resultTyp,
      generics: [resultGeneric],
      params: [
        ...optionalWhenParams,
      ],
    ),
  );

  @override
  late final src = methodGen.src;

  WhenMethodGen({
    required this.methodName,
    required this.classes,
    required this.callbackValues,
    this.commonType,
  });

  WhenMethodGen copyWith({
    String? methodName,
    Iterable<WhenMethodClassGen> Function(WhenMethodGen gen)? classes,
    Iterable<String> Function(WhenMethodClassGen self)? callbackValues,
    Typ? commonType,
  }) {
    return WhenMethodGen(
      methodName: methodName ?? this.methodName,
      classes: classes ?? this.classes,
      callbackValues: callbackValues ?? this.callbackValues,
      commonType: commonType ?? this.commonType,
    );
  }
}

class WhenMethodClassGen {
  final WhenMethodGen gen;
  final String alias;
  final Iterable<Param> Function(WhenMethodClassGen self) callbackParams;
  final bool responder;

  late final optionalWhenParam = Param(
    prop: Mthd(
      name: alias,
      type: resultTyp,
      params: callbackParams(this),
    ).functionProp.withNullable(true),
    naming: ParamNaming.named,
    requirement: ParamRequirement.optional,
  );

  late final requiredWhenParam = optionalWhenParam.copyWith(
    prop: optionalWhenParam.prop.withNullable(false),
    requirement: ParamRequirement.required,
  );

  WhenMethodClassGen({
    required this.gen,
    required this.alias,
    required this.callbackParams,
    required this.responder,
  });
}
