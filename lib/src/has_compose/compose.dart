part of 'has_compose.dart';

Builder delegateComposeBuilder(BuilderOptions options) => SharedPartBuilder(
      [DelegateComposeGenerator()],
      'compose',
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
        typParams: params,
        typeArgs: args,
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
        typParams: params,
        typeArgs: args,
      );
    }
  }

  String generateComposedClasses({
    required String className,
    required List<Iface> ifaces,
    required String typParams,
    required String typeArgs,
    String? baseClassName,
  }) {
    final output = <String>[];
    final classCamelName = className.camelCase;
    final composedClassName = "Composed$className";
    final effectiveBaseClassName = baseClassName ?? className;

    final mthds = ifaces
        .expand((element) => element.methods)
        .groupFoldBy(
          (mthd) => mthd.name,
          (previous, element) => element,
        )
        .values
        .toList();

    Iterable<String> merge() sync* {
      final multis = <Iface>[];
      final multiNames = <String>{};

      final multiMap = <String, Iface>{};

      for (final iface in ifaces) {
        if (iface.single) break;
        if (multiNames.intersectsWith(iface.methodNames)) break;
        multis.add(iface);
        multiNames.addAll(iface.methodNames);
        for (final methodName in iface.methodNames) {
          multiMap[methodName] = iface;
        }
      }
      if (multis.length <= 1) {
        return;
      }

      yield "factory";
      yield composedClassName;
      yield '.';
      yield r'merge$';

      yield* run(() sync* {
        for (final iface in multis) {
          yield "required";
          yield iface.type;
          yield iface.name.camelCase;
          yield ',';
        }

        for (final mthd in mthds) {
          if (!multiNames.contains(mthd.name)) {
            yield mthd.namedParam;
          }
        }
      }).enclosedInCurlyOrEmpty.enclosedInParen;

      yield "=>";
      yield composedClassName;

      yield* run(() sync* {
        for (final mthd in mthds) {
          yield mthd.name;
          yield ":";

          final iface = multiMap[mthd.name];
          if (iface != null) {
            yield iface.name.camelCase;
            yield '.';
          }
          yield mthd.name;
          yield ',';
        }
      }).enclosedInParen;
      yield ';';
    }

    Strings composedContent() sync* {
      // yield "factory";
      for (final mthd in mthds) {
        yield "@override";
        yield "final";
        yield mthd.type;
        yield mthd.name;
        yield ';';
      }

      yield composedClassName;
      yield* [
        for (final mthd in mthds) mthd.thisParam,
      ].enclosedInCurlyOrEmpty.enclosedInParen;
      // yield " = _$composedClassName";
      yield ';';
      for (final iface in ifaces.whereNot((e) => e.single)) {
        yield "factory";
        yield composedClassName;
        yield '.';
        yield iface.name.camelCase;

        yield* run(() sync* {
          yield "required";
          yield iface.type;
          yield iface.name.camelCase;
          yield ',';

          for (final mthd in mthds) {
            if (!iface.methodNames.contains(mthd.name)) {
              yield mthd.namedParam;
            }
          }
        }).enclosedInCurlyOrEmpty.enclosedInParen;

        yield "=>";
        yield composedClassName;

        yield* run(() sync* {
          for (final mthd in mthds) {
            yield mthd.name;
            yield ":";
            if (iface.methodNames.contains(mthd.name)) {
              yield iface.name.camelCase;
              yield '.';
            }
            yield mthd.name;
            yield ',';
          }
        }).enclosedInParen;
        yield ';';
      }

      yield* merge();
    }

    Strings composed() sync* {
      // yield "@freezedStruct";
      yield "base class $composedClassName$typParams";
      // yield "with _\$$composedClassName$typeArgs";
      yield "implements $effectiveBaseClassName$typeArgs";

      yield* composedContent().enclosedInCurly;

      yield "extension";
      yield '$effectiveBaseClassName\$CopyExt\$';
      yield typParams;
      yield "on";
      yield effectiveBaseClassName;
      yield typeArgs;

      yield* run(() sync* {
        for (final mthd in mthds) {
          yield effectiveBaseClassName;
          yield typeArgs;
          yield "${effectiveBaseClassName.camelCase}With${mthd.name.pascalCase}";

          yield* run(() sync* {
            yield mthd.type;
            yield mthd.name;
          }).enclosedInParen;
          yield "=>";
          yield composedClassName;
          yield* run(() sync* {
            for (final mthd in mthds) {
              yield mthd.name;
              yield ':';
              yield mthd.name;
              yield ',';
            }
          }).enclosedInParen;
          yield ';';
        }
      }).enclosedInCurly;
    }

    composed().joinLines.addTo(output);

    final delegateFieldName = "${classCamelName}Delegate";
    final mixinName = "Delegated${className}Mixin";
    final delegatedName = "Delegated$className";
    "base mixin $mixinName$typParams"
        .plus(" implements $effectiveBaseClassName$typeArgs")
        .plusCurlyLines([
      "$effectiveBaseClassName$typeArgs get $delegateFieldName;",
      ...mthds.map((e) {
        return "@override ${e.type} get ${e.name} => $delegateFieldName.${e.name};";
      }),
    ]).addTo(output);
    "base class $delegatedName$typParams"
        .plus(" extends $effectiveBaseClassName$typeArgs ")
        .plus(" with $mixinName$typeArgs")
        .plusCurlyLines([
      "@override final $effectiveBaseClassName$typeArgs $delegateFieldName;",
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

  String get freezedDefault =>
      defaultValue == null ? "" : "@Default($defaultValue) ";

  String get freezedParam =>
      freezedDefault.plus(requiredPrefix).plus("$type $name").plusComma;

  String get namedParam =>
      requiredPrefix.plus("$type $name").plus(defaultSuffix).plusComma;

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
