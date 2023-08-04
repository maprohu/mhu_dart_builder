import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
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

class DelegateHasClassGenerator extends GeneratorForAnnotation<Has> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    buildStep,
  ) {
    element as TypeParameterizedElement;

    return "abstract class ${element.hasName}${element.parametersDart}"
        .plusCurlyLines([
      "${element.nameWithArguments} get ${element.displayName.camelCase};",
    ]);
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

    "class $composedClassName$params"
        .plus(" extends $className$args")
        .plusCurlyLines([
      ...mthds.map((e) {
        return "@override final ${e.type} ${e.name};";
      }),
      composedClassName
          .plusParen(
            mthds
                .map(
                  (e) =>
                      (e.nullable ? "" : "required ").plus("this.${e.name},"),
                )
                .joinInCurlyOrEmpty(""),
          )
          .plusSemi,
      for (final iface in ifaces.whereNot((e) => e.single))
        composedClassName.plusDot
            .plus(iface.name.camelCase)
            .plusParen([
              "required ${iface.type} ${iface.name.camelCase},",
              ...mthds.whereNot((m) => iface.methodNames.contains(m.name)).map(
                  (mthd) => (mthd.nullable ? "" : "required ")
                      .plus("this.${mthd.name},")),
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
    "mixin $mixinName$params"
        .plus(" implements $className$args")
        .plusCurlyLines([
      "$className$args get $delegateFieldName;",
      ...mthds.map((e) {
        return "@override ${e.type} get ${e.name} => $delegateFieldName.${e.name};";
      }),
    ]).also(out);
    "class $delegatedName$params with $mixinName$args".plusCurlyLines([
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

extension ElementX on Element {
  String get hasName => "$prefixOfHas$displayName";
}

class Mthd {
  final String type;
  final String name;
  final bool nullable;

  const Mthd({
    required this.type,
    required this.name,
    required this.nullable,
  });
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

  Mthd get singleMethod => Mthd(
        type: getDisplayString(withNullability: false).withoutHas,
        name: element.name.withoutHas.camelCase,
        nullable: accessors.first.declaration.returnType.nullabilitySuffix ==
            NullabilitySuffix.question,
      );

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
