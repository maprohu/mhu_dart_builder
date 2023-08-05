import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:mhu_dart_builder/mhu_dart_builder.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

Builder delegateHasClassBuilder(BuilderOptions options) => PartBuilder(
      [DelegateHasClassGenerator()],
      '.g.has.dart',
    );

Builder delegateComposeBuilder(BuilderOptions options) => PartBuilder(
      [DelegateComposeGenerator()],
      '.g.compose.dart',
    );

final checkerHasDefault = TypeChecker.fromRuntime(HasDefault);

extension ElementX on Element {
  String get hasName => "$prefixOfHas$displayName";

  String? get defaultValue {
    final hasDefault = checkerHasDefault.firstAnnotationOf(this);
    if (hasDefault == null) {
      return null;
    }
    return ConstantReader(hasDefault).defaultValue;
  }
}

class DelegateHasClassGenerator extends GeneratorForAnnotation<Has> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    buildStep,
  ) {
    element as TypeParameterizedElement;

    var output = <String>[];
    void out(String str) => output.add(str);

    final name = element.displayName;
    final params = element.parametersDart;
    final args = element.argumentsDart;
    final indirectName = "$name$suffixOfIndirect";

    void hasClass(String name) {
      final camelName = name.camelCase;

      "abstract class $prefixOfHas$name$params".plusCurlyLines([
        "$name$args get $camelName;",
      ]).also(out);
    }

    final defaultValue = element.defaultValue;
    if (defaultValue != null) {
      "@HasDefault($defaultValue)".also(out);
    }

    hasClass(name);
    "typedef $indirectName$params = $name$args Function();".also(out);
    hasClass(indirectName);

    "extension $prefixOfHas$indirectName\$Ext$params on $prefixOfHas$indirectName$args"
        .plusCurlyLines([
      "$name$args get ${name.camelCase} => ${name.camelCase}$suffixOfIndirect();"
    ]).also(out);

    // final defaultConst = annotation.objectValue.getField("defaultConst")!;
    // if (!defaultConst.isNull) {
    //   final alias = element as TypeAliasElement;
    //   final notNullType = alias.aliasedType.getDisplayString(withNullability: false);
    //   final value = (defaultConst as DartObjectImpl).state.toString();
    //   "extension $prefixOfHas$name\$Ext$params on $prefixOfHas$name$args"
    //       .plusCurlyLines([
    //     "$notNullType get ${name.camelCase}$suffixOfEffective => ${name.camelCase} ?? $value;"
    //   ]).also(out);
    // }

    return output.joinLines;
  }
}

extension ConstantReaderX on ConstantReader {
  String? get defaultValue {
    final defaultConst = objectValue.getField("value")!;
    if (!defaultConst.isNull) {
      return (defaultConst as DartObjectImpl).state.toString();
    } else {
      return null;
    }
  }
}

class DelegateComposeGenerator extends GeneratorForAnnotation<Compose> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    buildStep,
  ) {
    if (element is! ClassElement) {
      return;
    }

    var output = <String>[];
    void out(String str) => output.add(str);

    final List<Iface> ifaces = element.interfaces.map((e) {
      return Iface(
        single: e.isSingle,
        methods: [...e.collectMethods],
        name: e.nameWithoutHas,
        type: e.toString(),
      );
    }).toList();

    final mthds = ifaces
        .expand((element) => element.methods)
        .groupFoldBy(
          (mthd) => mthd.name,
          (previous, element) => element,
        )
        .values
        .toList();

    final className = element.displayName;
    final name = className.camelCase;
    final composedClassName = "Composed$className";
    final params = element.parametersDart;
    final args = element.argumentsDart;

    "base class $composedClassName$params"
        .plus(" extends $className$args")
        .plusCurlyLines([
      ...mthds.map((e) {
        return "@override final ${e.type} ${e.name};";
      }),
      composedClassName
          .plusParen(
            mthds
                .map(
                  (e) => e.thisParam,
                )
                .joinInCurlyOrEmpty(""),
          )
          .plusSemi,
      for (final iface in ifaces.whereNot((e) => e.single))
        composedClassName.plusDot
            .plus(iface.name.camelCase)
            .plusParen([
              "required ${iface.type} ${iface.name.camelCase},",
              ...mthds
                  .whereNot((m) => iface.methodNames.contains(m.name))
                  .map((mthd) => mthd.thisParam),
            ].joinLinesInCurlyOrEmpty)
            .plus(
              mthds
                  .where((m) => iface.methodNames.contains(m.name))
                  .map(
                    (mthd) =>
                        "${mthd.name} = ${iface.name.camelCase}.${mthd.name}",
                  )
                  .joinEnclosedOrEmpty(":", "", ','),
            )
            .plusSemi,
    ]).also(out);

    final delegateFieldName = "${name}Delegate";
    final mixinName = "Delegated${className}Mixin";
    final delegatedName = "Delegated$className";
    "base mixin $mixinName$params"
        .plus(" implements $className$args")
        .plusCurlyLines([
      "$className$args get $delegateFieldName;",
      ...mthds.map((e) {
        return "@override ${e.type} get ${e.name} => $delegateFieldName.${e.name};";
      }),
    ]).also(out);
    "base class $delegatedName$params"
        .plus(" extends $className$args ")
        .plus(" with $mixinName$args")
        .plusCurlyLines([
      "@override final $className$args $delegateFieldName;",
      delegatedName
          .plusParen(
            "this.$delegateFieldName",
          )
          .plusSemi,
    ]).also(out);

    return output.joinLines;
  }
}

extension TypeParameterizedElementX on TypeParameterizedElement {
  String get parametersDart => typeParameters.parametersDart;

  String get argumentsDart => typeParameters.argumentsDart;

  String get nameWithArguments => "$displayName$argumentsDart";
}

extension ListOfTypeParameterElementX on List<TypeParameterElement> {
  String get parametersDart => isEmpty
      ? ""
      : map((e) {
          return e.toString().removePrefixes(
            [
              "in ",
              "out ",
            ],
          );
        }).join(",").inChevron;

  String get argumentsDart => isEmpty
      ? ""
      : map((e) {
          return e.name;
        }).join(",").inChevron;
}

const prefixOfHas = "Has";
const suffixOfIndirect = "Indirect";
const suffixOfEffective = "Effective";

class Mthd {
  final String type;
  final String name;
  final String? defaultValue;
  final bool nullable;

  const Mthd({
    required this.type,
    required this.name,
    required this.defaultValue,
    required this.nullable,
  });

  String get requiredPrefix =>
      nullable || defaultValue != null ? "" : "required ";

  String get defaultSuffix => defaultValue == null ? "" : " = $defaultValue";

  String get thisParam =>
      requiredPrefix.plus("this.$name").plus(defaultSuffix).plusComma;
}

class Iface {
  final bool single;
  final List<Mthd> methods;
  final String name;
  final String type;

  late final methodNames = methods.map((e) => e.name).toSet();

  Iface({
    required this.methods,
    required this.single,
    required this.name,
    required this.type,
  });
}

extension InterfaceTypeX on InterfaceType {
  bool get isSingle => element.name.startsWith(prefixOfHas);

  Mthd get singleMethod {
    return Mthd(
      type: getDisplayString(withNullability: false).withoutHas,
      name: element.name.withoutHas.camelCase,
      nullable: accessors.first.declaration.returnType.nullabilitySuffix ==
          NullabilitySuffix.question,
      defaultValue: element.defaultValue,
    );
  }

  Iterable<Mthd> get collectMethods sync* {
    if (isSingle) {
      yield singleMethod;
    } else {
      for (final iface in interfaces) {
        yield* iface.collectMethods;
      }
    }
  }

  String get nameWithoutHas =>
      isSingle ? element.name.withoutHas : element.name;
}

extension _StringX on String {
  String get withoutHas => substring(prefixOfHas.length);
}
