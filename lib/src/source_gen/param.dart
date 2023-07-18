import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_commons/commons.dart';

import 'prop.dart';
import 'typ.dart';

class Param {
  final Prop prop;
  final ParamNaming naming;
  final ParamRequirement requirement;
  final ParamNullability nullability;
  final ParamTarget target;
  final String? defaultValue;

  Param({
    required this.prop,
    required this.naming,
    required this.requirement,
    this.nullability = ParamNullability.ofType,
    this.target = ParamTarget.noTarget,
    this.defaultValue,
  });

  Param.fromProp(Prop prop)
      : this(
          prop: prop,
          naming: ParamNaming.unnamed,
          requirement: ParamRequirement.required,
        );

  Param.simple({
    required String name,
    required Typ type,
  }) : this.fromProp(
          Prop(
            name: name,
            type: type,
          ),
        );

  late final name = prop.name;
  late final nameEscaped = name.startsWith('_') ? '\$$name' : name;

  late final isNamed = naming.isNamed;
  late final isRequired = requirement.isRequired;
  late final isOptional = !isRequired;

  late final defaultValueSuffix = defaultValue?.let((v) => '=$v') ?? '';

  late final declare = requirement.declare(this);

  late final typeOrTargetDotNameDefaultComma =
      '${target.typeOrTargetDot(this)}$name$defaultValueSuffix,';

  late final passArg = arg(name);
  late final passArgEscaped = arg(nameEscaped);

  String passArgDelegated(String delegate) => arg('$delegate.$name');

  String arg(String value) => naming.arg(this, value);

  String targetDotNameDefault(String target) =>
      '$target.$name$defaultValueSuffix,';

  Param.fromElement(ParameterElement element)
      : this(
          prop: Prop(
            name: element.name,
            type: Typ.fromType(element.type),
          ),
          naming: ParamNaming.fromParameter(element),
          requirement: ParamRequirement.fromParameter(element),
          defaultValue: element.defaultValueCode,
        );

  Param.fromElementWithType(ParameterElement element, Typ type)
      : this(
          prop: Prop(name: element.name, type: type),
          naming: ParamNaming.fromParameter(element),
          requirement: ParamRequirement.fromParameter(element),
          defaultValue: element.defaultValueCode,
        );

  Param copyWith({
    Prop? prop,
    ParamNaming? naming,
    ParamRequirement? requirement,
    ParamNullability? nullability,
    ParamTarget? target,
    String? defaultValue,
  }) {
    return Param(
      prop: prop ?? this.prop,
      naming: naming ?? this.naming,
      requirement: requirement ?? this.requirement,
      nullability: nullability ?? this.nullability,
      target: target ?? this.target,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  Param withDefaultValue(String? defaultValue) => Param(
        prop: prop,
        naming: naming,
        requirement: requirement,
        nullability: nullability,
        target: target,
        defaultValue: defaultValue,
      );
}

class ParamList {
  final Iterable<Param> params;

  ParamList(this.params);

  late final unnamed = params.whereNot((e) => e.isNamed);
  late final unnamedRequired = unnamed.where((e) => e.isRequired);
  late final unnamedOptional = unnamed.whereNot((e) => e.isRequired);
  late final named = params.where((e) => e.isNamed);

  late final declare = [
    ...unnamedRequired.map((e) => e.declare),
    unnamedOptional.map((e) => e.declare).squareIfNotEmpty,
    named.map((e) => e.declare).curlyIfNotEmpty,
  ].join();

  late final passArgs = params.map((e) => e.passArg).join();

  String passArgsDelegated(String delegate) =>
      params.map((e) => e.passArgDelegated(delegate)).join();
  late final passArgsEscaped = params.map((e) => e.passArgEscaped).join();
}

extension IterableParamX on Iterable<Param> {
  ParamList get toParamList => ParamList(this);

  String get passArgs => toParamList.passArgs;

  String passArgsDelegated(String delegate) =>
      toParamList.passArgsDelegated(delegate);

  String get passArgsEscaped => toParamList.passArgsEscaped;
}

abstract class ParamNaming {
  const ParamNaming._();

  static const named = ParamNamed.instance;
  static const unnamed = ParamUnnamed.instance;

  String requiredPrefix();

  String arg(Param param, String value);

  bool get isNamed;

  factory ParamNaming.fromIsNamed(bool isNamed) => isNamed ? named : unnamed;

  factory ParamNaming.fromParameter(ParameterElement element) =>
      ParamNaming.fromIsNamed(element.isNamed);
}

class ParamUnnamed extends ParamNaming {
  const ParamUnnamed._() : super._();
  static const instance = ParamUnnamed._();

  @override
  bool get isNamed => false;

  @override
  String requiredPrefix() => '';

  @override
  String arg(Param param, String value) => '$value,';
}

class ParamNamed extends ParamNaming {
  const ParamNamed._() : super._();
  static const instance = ParamNamed._();

  @override
  bool get isNamed => true;

  @override
  String requiredPrefix() => 'required ';

  @override
  String arg(Param param, String value) => '${param.name}: $value,';
}

abstract class ParamRequirement {
  const ParamRequirement._();

  static const required = ParamRequired.instance;
  static const optional = ParamOptional.instance;

  String declare(Param param);

  bool get isRequired;

  factory ParamRequirement.fromIsRequired(bool isRequired) =>
      isRequired ? required : optional;

  factory ParamRequirement.fromParameter(ParameterElement element) =>
      ParamRequirement.fromIsRequired(element.isRequired);

  factory ParamRequirement.fromIsNullable(bool isNullable) =>
      ParamRequirement.fromIsRequired(!isNullable);

  factory ParamRequirement.fromTyp(Typ type) =>
      ParamRequirement.fromIsNullable(type.nullable);

  factory ParamRequirement.fromProp(Prop prop) =>
      ParamRequirement.fromTyp(prop.type);
}

class ParamOptional extends ParamRequirement {
  const ParamOptional._() : super._();
  static const instance = ParamOptional._();

  @override
  bool get isRequired => false;

  @override
  String declare(Param param) => param.typeOrTargetDotNameDefaultComma;
}

class ParamRequired extends ParamRequirement {
  const ParamRequired._() : super._();
  static const instance = ParamRequired._();

  @override
  bool get isRequired => true;

  @override
  String declare(Param param) =>
      '${param.naming.requiredPrefix()}${param.typeOrTargetDotNameDefaultComma}';
}

abstract class ParamTarget {
  const ParamTarget._();

  static const noTarget = ParamNoTarget.instance;
  static const thisTarget = ParamThis.instance;
  static const superTarget = ParamSuper.instance;

  String typeOrTargetDot(Param param);
}

class ParamNoTarget extends ParamTarget {
  const ParamNoTarget._() : super._();
  static const instance = ParamNoTarget._();

  @override
  String typeOrTargetDot(Param param) => '${param.nullability.type(param)} ';
}

class ParamThis extends ParamTarget {
  const ParamThis._() : super._();
  static const instance = ParamThis._();

  @override
  String typeOrTargetDot(Param param) => 'this.';
}

class ParamSuper extends ParamTarget {
  const ParamSuper._() : super._();
  static const instance = ParamSuper._();

  @override
  String typeOrTargetDot(Param param) => 'super.';
}

abstract class ParamNullability {
  const ParamNullability._();

  static const nullable = ParamNullable.instance;
  static const ofType = ParamTypeNullability.instance;

  String type(Param param);
}

class ParamNullable extends ParamNullability {
  const ParamNullable._() : super._();
  static const instance = ParamNullable._();

  @override
  String type(Param param) =>
      param.prop.type.withNullable(true).withNullability;
}

class ParamTypeNullability extends ParamNullability {
  const ParamTypeNullability._() : super._();
  static const instance = ParamTypeNullability._();

  @override
  String type(Param param) => param.prop.type.withNullability;
}
