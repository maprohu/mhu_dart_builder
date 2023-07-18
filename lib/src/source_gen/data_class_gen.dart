import 'package:collection/collection.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'class/constr.dart';
import 'class/field.dart';
import 'class/method.dart';
import 'gen.dart';
import 'generic.dart';
import 'mthd.dart';
import 'param.dart';
import 'prop.dart';
import 'source_generator.dart';

import 'class_gen.dart';
import 'typ.dart';

const overrideVar = 'override\$';
const overrideMethodName = 'override\$';
const overrideMethodParamName = 'overriden\$';

class RecordGen {
  final String name;
  final Iterable<Param> params;
  final Iterable<Generic> generics;
  final String commonType;
  final String intType;
  final String Function(int index, Param param, String ref) returnValue;

  static String _defaultReturnValue(int index, Param param, String ref) => ref;

  RecordGen({
    required this.name,
    required this.params,
    required this.generics,
    this.commonType = 'dynamic',
    this.intType = 'int',
    this.returnValue = _defaultReturnValue,
  });

  late final dataClassGen = DataClassGen(
    name: name,
    params: params.map(
      (e) => e.copyWith(nullability: ParamNullability.nullable),
    ),
    generics: generics,
  );

  late final dataClassSrc = dataClassGen.src;

  late final indexOperatorExtensionSrc = dataClassGen.classGen.extension(
    [
      // '$commonType operator []($intType index)'.andCurly([
      '$commonType get($intType index)'.andCurly([
        'switch (index)'.andCurly([
          ...params.mapIndexed((i, e) =>
              'case $i: return ${returnValue(i, e, "this.${e.name}")};'),
        ]),
        'throw index;',
      ]),
    ].join(),
    suffix: '\$IndexOperatorExt',
  );
}

class DataClassGen extends TopGen {
  final String name;
  final Iterable<Generic> generics;
  final Iterable<Param> params;
  final Content extra;
  final String extensionExtra;
  final Iterable<ClassGen> Function(ClassGen self) implements;
  final Iterable<Constr> Function(DataClassGen self) extraConstructors;
  final Typ? overrideTyp;
  final String? comment;
  final String? ovrClassName;

  DataClassGen({
    required this.name,
    this.generics = const [],
    required this.params,
    this.extra = noContent,
    this.extensionExtra = '',
    this.implements = empty1,
    this.extraConstructors = empty1,
    this.overrideTyp,
    this.comment,
    this.ovrClassName,
  });

  late final constrParams = params.map(
    (e) => e.copyWith(
      naming: ParamNaming.named,
      target: ParamTarget.thisTarget,
      nullability: ParamNullability.ofType,
    ),
  );

  late final constrParamsNoTarget = constrParams.map(
    (e) => e.copyWith(
      target: ParamTarget.noTarget,
    ),
  );

  late final constrParamsOptional = constrParamsNoTarget.map(
    (e) => e
        .copyWith(
          requirement: ParamRequirement.optional,
          nullability: ParamNullability.nullable,
        )
        .withDefaultValue(null),
  );

  late final classGen = ClassGen(
    name: name,
    generics: generics,
    implements: implements,
    constructorsFn: (self) => [
      Constr(
        owner: self,
        params: constrParams,
      ),
      ...extraConstructors(this),
    ],
    content: (self) => [
      ...params.map((e) => FieldGen(e.prop)),
      ...extra(self),
    ],
    comment: comment,
  );

  late final constructor = classGen.firstConstructor;

  late final hasNullableProp = params.any((e) => e.prop.type.nullable);

  String overrideSrc(Prop prop) {
    final name = prop.name;
    final thisVar = 'this.$name';
    final ovrVar = '$overrideVar.$name';
    if (prop.type.nullable) {
      return '$thisVar.overrideNullableWith($ovrVar, (s, o) => s.overrideWith(o),)';
    } else {
      return '$thisVar.overrideWith($ovrVar)';
    }
  }

  late final overrideMethodGen = MethodGen(
    mthd: Mthd(
      name: 'overrideWith',
      type: classGen.typ,
      params: [
        Param(
          prop: Prop(
            name: overrideVar,
            type: overrideTyp ?? classGen.typ,
          ),
          naming: ParamNaming.unnamed,
          requirement: ParamRequirement.required,
        )
      ],
    ),
    body: classGen.firstConstructor.ref
        .andParen(
          classGen.firstConstructor.paramsNoTarget.map(
            (e) => e.arg(overrideSrc(e.prop)),
          ),
        )
        .asExpressionBody,
  );

  late final copyExtensionMethods = [
    MethodGen(
      mthd: Mthd(
        name: 'copyWith',
        type: classGen.typ,
        params: constrParamsOptional,
      ),
      body: classGen.name
          .andParen(
            constrParams.map(
              (e) => e.arg(
                '${e.name} ?? this.${e.name}',
              ),
            ),
          )
          .asExpressionBody,
    ),
    if (hasNullableProp) overrideMethodGen,
  ].srcsJoin;

  String copyExtensionsFor(ClassGen target, [String extra = '']) =>
      target.extension([
        extra,
        copyExtensionMethods,
      ].join());

  late final extensionSrc = copyExtensionsFor(classGen, extensionExtra);

  @override
  late final src = [
    classGen.src,
    extensionSrc,
  ].join();
}
