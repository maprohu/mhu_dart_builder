import 'package:analyzer/dart/element/element.dart';

import 'class_gen.dart';
import 'typ.dart';

class Prop {
  final String name;
  final Typ type;

  Prop({
    required this.name,
    required this.type,
  });

  Prop.fromParameter(ParameterElement element)
      : this(
          name: element.name,
          type: Typ.fromParameter(element),
        );

  late final typeAndName = '${type.withNullability} $name';

  late final declareFinal = 'final $typeAndName;';
  late final declareFinalNullable = 'final ${type.withoutNullability}? $name;';
  late final declareGetterHeader = '${type.withNullability} get $name';
  late final declareSetterHeader =
      'set $name(${type.withNullability} $valueVar)';

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
      );

  late final escapedName = name.startsWith('_') ? name.substring(1) : name;

  Prop withEscapedName() => copyWith(name: escapedName);

  Prop copyWith({
    String? name,
    Typ? type,
    String? defaultValue,
  }) {
    return Prop(
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

extension PropIterableX on Iterable<Prop> {
  Iterable<String> get declareFinals => map((e) => e.declareFinal);

  Iterable<String> get namedArgPasses => map((e) => e.namedArgPass);

  Iterable<String> get unnamedArgPasses => map((e) => e.unnamedArgPass);
}
