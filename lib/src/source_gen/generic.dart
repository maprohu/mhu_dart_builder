import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';

import 'class_gen.dart';
import 'typ.dart';

class Generic {
  final String name;
  final String? bound;

  Generic(this.name, [this.bound]);

  Generic.simple(this.name) : bound = null;

  late final param = bound != null ? '$name extends $bound' : name;
  late final arg = name;

  factory Generic.fromParameter(TypeParameterElement param) =>
      Generic(param.name, param.bound?.toString());

  factory Generic.fromDartType(DartType type) =>
      Generic(type.getDisplayString(withNullability: true));

  factory Generic.fromClassGen(ClassGen classGen) =>
      Generic(classGen.nameWithArgs);

  late final typ = Typ(withoutNullability: name, nullable: false);

  static Generic ofVoid = Typ.voidType().asGeneric;
  static Generic ofDynamicCore = Typ.dynamicType().ofCore.asGeneric;
  static Generic ofDynamic = Typ.dynamicType().asGeneric;

  static Iterable<Generic> downCast(ClassElement sup, ClassElement sub) {
    InterfaceType t = sub.thisType;

    while (t.element != sup) {
      t = t.superclass!;
    }

    return sub.typeParameters.map((p) {
      final found = t.typeArguments.indexWhere((a) {
        return a is TypeParameterType && a.element == p;
      });
      if (found < 0) return Generic.ofDynamic;
      return sup.typeParameters[found].toGeneric;
    }).toList();
  }

  Generic copyWith({
    String? name,
    String? bound,
  }) {
    return Generic(
      name ?? this.name,
      bound ?? this.bound,
    );
  }
}

extension IterableGenericX on Iterable<Generic> {
  Iterable<String> get params => map((e) => e.param);

  Iterable<String> get args => map((e) => e.arg);

  String get paramsBrackets => params.commasGenerics;

  String get argsBrackets => args.commasGenerics;
}

extension TypeParameterElementX on TypeParameterElement {
  Generic get toGeneric => Generic.fromParameter(this);
}
