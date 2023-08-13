part of 'has_compose.dart';

Builder delegateComposeBuilder(BuilderOptions options) => PartBuilder(
      [DelegateComposeGenerator()],
      '.g.compose.dart',
    );

class DelegateComposeGenerator extends GeneratorForAnnotation<Compose> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    buildStep,
  ) {
    if (element is ClassElement) {
      final List<Iface> ifaces = element.interfaces.map((e) {
        return Iface(
          single: e.isSingle,
          methods: [...e.collectMethods],
          name: e.nameWithoutHas,
          type: e.toString(),
        );
      }).toList();

      final className = element.displayName;
      final params = element.parametersDart;
      final args = element.argumentsDart;

      return generateComposedClasses(
        className: className,
        ifaces: ifaces,
        params: params,
        args: args,
      );
    }

    if (element is TypeAliasElement) {
      final className = element.displayName;
      final params = element.parametersDart;
      final args = element.argumentsDart;

      final aliasedType = element.aliasedType;

      final hasClassName = "$prefixOfHas$className";

      final fullType = "$className$params";

      final List<Iface> ifaces = [
        Iface(
          single: true,
          methods: [
            Mthd(
              type: fullType,
              name: className.camelCase,
              defaultValue: element.defaultValue,
              nullable:
                  aliasedType.nullabilitySuffix == NullabilitySuffix.question,
            ),
          ],
          name: className,
          type: fullType,
        ),
      ];

      return generateComposedClasses(
        className: className,
        baseClassName: hasClassName,
        ifaces: ifaces,
        params: params,
        args: args,
      );
    }
  }

  String generateComposedClasses({
    required String className,
    required List<Iface> ifaces,
    required String params,
    required String args,
    String? baseClassName,
  }) {
    final output = <String>[];
    final name = className.camelCase;
    final composedClassName = "Composed$className";
    baseClassName ??= className;

    final mthds = ifaces
        .expand((element) => element.methods)
        .groupFoldBy(
          (mthd) => mthd.name,
          (previous, element) => element,
        )
        .values
        .toList();

    Iterable<String> merge() {
      final multis = <Iface>[];
      final multiNames = <String>{};

      for (final iface in ifaces) {
        if (iface.single) break;
        if (multiNames.intersectsWith(iface.methodNames)) break;
        multis.add(iface);
        multiNames.addAll(iface.methodNames);
      }
      if (multis.length <= 1) {
        return const [];
      }

      return [
        composedClassName.plusDot
            .plus(r"merge$")
            .plusParen([
              ...multis.map(
                (iface) => "required ${iface.type} ${iface.name.camelCase},",
              ),
              ...mthds
                  .whereNot((m) => multiNames.contains(m.name))
                  .map((mthd) => mthd.thisParam),
            ].joinLinesInCurlyOrEmpty)
            .plus(
              multis
                  .expand((iface) =>
                      iface.methodNames.map((e) => (iface: iface, mthd: e)))
                  .map(
                    (im) =>
                        "${im.mthd} = ${im.iface.name.camelCase}.${im.mthd}",
                  )
                  .joinEnclosedOrEmpty(":", "", ','),
            )
            .plusSemi,
      ];
    }

    "base class $composedClassName$params"
        .plus(" extends $baseClassName$args")
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
      ...merge(),
    ]).addTo(output);

    final delegateFieldName = "${name}Delegate";
    final mixinName = "Delegated${className}Mixin";
    final delegatedName = "Delegated$className";
    "base mixin $mixinName$params"
        .plus(" implements $baseClassName$args")
        .plusCurlyLines([
      "$baseClassName$args get $delegateFieldName;",
      ...mthds.map((e) {
        return "@override ${e.type} get ${e.name} => $delegateFieldName.${e.name};";
      }),
    ]).addTo(output);
    "base class $delegatedName$params"
        .plus(" extends $baseClassName$args ")
        .plus(" with $mixinName$args")
        .plusCurlyLines([
      "@override final $baseClassName$args $delegateFieldName;",
      delegatedName
          .plusParen(
            "this.$delegateFieldName",
          )
          .plusSemi,
    ]).addTo(output);

    return output.joinLines;
  }
}

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
      type: getDisplayString(withNullability: true).withoutHas,
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
