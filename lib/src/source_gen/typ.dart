import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'source_generator.dart';
import 'analyzer.dart';
import 'class_gen.dart';
import 'generic.dart';
import '../reflect.dart';

class Typ {
  final String withoutNullability;
  final bool nullable;

  late final nullabilitySuffix = nullable ? '?' : '';
  late final withNullability = '$withoutNullability$nullabilitySuffix';

  Typ.fromType(DartType type)
      : this(
          nullable: type.isNullable,
          withoutNullability: type.displayWithoutNullability,
        );

  Typ.fromParameter(ParameterElement element)
      : this(
          nullable: element.isOptional || element.type.isNullable,
          withoutNullability: element.type.displayWithoutNullability,
        );

  Typ({
    required this.withoutNullability,
    required this.nullable,
  });

  Typ.voidType() : this(withoutNullability: 'void', nullable: false);

  Typ.dynamicType() : this(withoutNullability: 'dynamic', nullable: false);

  String unnamedParamCalled(String name) => '$withNullability $name';

  Typ withNullable(bool nullable) => Typ(
        withoutNullability: withoutNullability,
        nullable: nullable,
      );

  late final asGeneric = Generic(withNullability);

  ClassGen asTypeArgumentOfType(Type type) => ClassGen(
        name: nm(type),
        generics: [asGeneric],
      );

  Typ get ofCore => copyWith(
        withoutNullability: '\$core.'.followedBy(withoutNullability),
      );

  Typ copyWith({
    String? withoutNullability,
    bool? nullable,
  }) {
    return Typ(
      withoutNullability: withoutNullability ?? this.withoutNullability,
      nullable: nullable ?? this.nullable,
    );
  }
}

extension StringTypX on String {
  Typ toTyp({
    bool nullable = false,
  }) =>
      Typ(withoutNullability: this, nullable: nullable);
}
