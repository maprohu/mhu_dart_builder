
import 'package:analyzer/dart/element/element.dart';

import 'class_gen.dart';
import 'typ.dart';

class Prop {
  final String name;
  final Typ type;

  // @deprecated
  // final String? defaultValue;

  Prop({
    required this.name,
    required this.type,
    // this.defaultValue,
  });

  Prop.fromParameter(ParameterElement element)
      : this(
    name: element.name,
    type: Typ.fromParameter(element),
    // defaultValue: element.defaultValueCode,
  );

  // late final defaultSrc = defaultValue?.let((d) => ' = $d') ?? '';

  late final typeAndName = '${type.withNullability} $name';

  // late final unnamedParam = '$typeAndName$defaultSrc,';
  // late final unnamedThisParam = 'this.$name$defaultSrc,';
  late final declareFinal = 'final $typeAndName;';
  late final declareFinalNullable = 'final ${type.withoutNullability}? $name;';
  late final declareGetterHeader = '${type.withNullability} get $name';
  late final declareSetterHeader =
      'set $name(${type.withNullability} $valueVar)';

  // late final namedParamRequiredIfNotNullable =
  //     '$requiredSrc${type.withNullability} $name$defaultSrc,';
  // late final namedThisParamRequiredIfNotNullable =
  //     '$requiredSrc this.$name$defaultSrc,';
  // late final paramNullable = '${type.withoutNullability}? $name$defaultSrc,';
  // late final namedSuperParamRequiredIfNotNullable =
  // '$requiredSrc super.$name$defaultSrc,';

  late final requiredSrc = type.nullable ? '' : 'required ';

  late final namedArgPass = namedArgPassValue((e) => e);
  late final unnamedArgPass = unnamedArgPassValue((e) => e);

  String namedArgPassValue(String Function(String varname) value) =>
      '$name: ${value(name)},';

  String unnamedArgPassValue(String Function(String varname) value) =>
      '${value(name)},';

  Prop withNullable(bool nullable) => Prop(
    name: name,
    type: type.withNullable(nullable),
    // defaultValue: defaultValue,
  );

  late final escapedName =
  name.startsWith('_') ? '${name.substring(1)}' : name;

  Prop withEscapedName() => copyWith(name: escapedName);

  Prop copyWith({
    String? name,
    Typ? type,
    String? defaultValue,
  }) {
    return Prop(
      name: name ?? this.name,
      type: type ?? this.type,
      // defaultValue: defaultValue ?? this.defaultValue,
    );
  }
}


extension PropIterableX on Iterable<Prop> {
  // Iterable<String> get unnamedParams => map((e) => e.unnamedParam);

  // Iterable<String> get unnamedThisParams => map((e) => e.unnamedThisParam);

  Iterable<String> get declareFinals => map((e) => e.declareFinal);

  // Iterable<String> get paramsNullable => map((e) => e.paramNullable);

  Iterable<String> get namedArgPasses => map((e) => e.namedArgPass);

  Iterable<String> get unnamedArgPasses => map((e) => e.unnamedArgPass);

// Iterable<String> get namedParamsRequiredIfNotNullable =>
//     map((e) => e.namedParamRequiredIfNotNullable);

// Iterable<String> get namedThisParamsRequiredIfNotNullable =>
//     map((e) => e.namedThisParamRequiredIfNotNullable);

// Iterable<String> get namedSuperParamsRequiredIfNotNullable =>
//     map((e) => e.namedSuperParamRequiredIfNotNullable);
}


