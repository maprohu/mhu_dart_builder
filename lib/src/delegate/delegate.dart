import 'package:analyzer/dart/element/element.dart';
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

    final className = "Composed${element.displayName}";

    "class $className${element.parametersDart}"
        .plus(" implements ${element.displayName}${element.argumentsDart}")
        .plusCurlyLines([
      ...mthds.map((e) {
        return "@override final ${e.type} ${e.name};";
      }),
      "const $className"
          .plusParen(
            mthds.map((e) => "required this.${e.name},").joinInCurlyOrEmpty(""),
          )
          .plusSemi,
      for (final iface in ifaces.whereNot((e) => e.single))
        className.plusDot
            .plus(iface.name.camelCase)
            .plusParen([
              "required ${iface.type} ${iface.name.camelCase},",
              ...mthds
                  .whereNot((m) => iface.methodNames.contains(m.name))
                  .map((mthd) => "required this.${mthd.name},"),
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

  const Mthd({
    required this.type,
    required this.name,
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
