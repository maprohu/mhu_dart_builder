part of 'has_compose.dart';

Builder delegateHasClassBuilder(BuilderOptions options) => PartBuilder(
      [DelegateHasClassGenerator()],
      '.g.has.dart',
    );

class DelegateHasClassGenerator extends Generator {
  TypeChecker get typeCheckerHas => TypeChecker.fromRuntime(Has);

  TypeChecker get typeCheckerHasOf => TypeChecker.fromRuntime(HasOf);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    return generateStrings(library).join('\n\n');
  }

  Strings generateStrings(LibraryReader library) sync* {
    for (var annotatedElement in library.annotatedWith(typeCheckerHas)) {
      final element = annotatedElement.element as TypeParameterizedElement;
      yield* generateHas(element: element);
    }

    for (final element in library.allElements) {
      for (final annotation in typeCheckerHasOf.annotationsOf(element)) {
        final reader = ConstantReader(annotation);
        final type = reader.objectValue.type as InterfaceType;

        final target = type.typeArguments.first;
        final element = target.element as TypeParameterizedElement;
        yield* generateHas(element: element);
      }
    }
  }

  // String generateForAnnotatedElement(
  //   Element element,
  //   ConstantReader annotation,
  // ) {
  //   element as TypeParameterizedElement;
  //
  //   return generateHas(element: element).joinLines;
  //
  //   // var output = <String>[];
  //   //
  //   // final name = element.displayName;
  //   // final params = element.parametersDart;
  //   // final args = element.argumentsDart;
  //   //
  //   // final indirectName = "Call$name";
  //   //
  //   // void hasClass(String name) {
  //   //   final camelName = name.camelCase;
  //   //
  //   //   "abstract class $prefixOfHas$name$params".plusCurlyLines([
  //   //     "$name$args get $camelName;",
  //   //   ]).addTo(output);
  //   //   "mixin $prefixOfMix$name$params"
  //   //       .plus(" implements $prefixOfHas$name$args")
  //   //       .plusCurlyLines([
  //   //     "@override late final $name$args $camelName;",
  //   //   ]).addTo(output);
  //   //   "extension $prefixOfHas$name\$Ext$params"
  //   //       .plus(" on $name$args")
  //   //       .plusCurlyLines([
  //   //     "void init$prefixOfMix$name"
  //   //         .plusParen("$prefixOfMix$name$args mix")
  //   //         .plusCurlyLines([
  //   //       "mix.$camelName = this;",
  //   //     ]),
  //   //   ]).addTo(output);
  //   // }
  //   //
  //   // final defaultValue = element.defaultValue;
  //   // if (defaultValue != null) {
  //   //   "@HasDefault($defaultValue)".addTo(output);
  //   // }
  //   //
  //   // hasClass(name);
  //   // "typedef $indirectName$params = $name$args Function();".addTo(output);
  //   // hasClass(indirectName);
  //   //
  //   // return output.joinLines;
  // }

  Strings generateHas({
    required TypeParameterizedElement element,
    // required List<DartType> typeArgs,
  }) sync* {
    final name = element.displayName;
    final params = element.parametersDart;
    final args = element.argumentsDart;

    final indirectName = "Call$name";

    Strings hasClass(String name) sync* {
      final camelName = name.camelCase;

      yield "abstract class $prefixOfHas$name$params".plusCurlyLines([
        "$name$args get $camelName;",
      ]);
      yield "mixin $prefixOfMix$name$params"
          .plus(" implements $prefixOfHas$name$args")
          .plusCurlyLines([
        "@override late final $name$args $camelName;",
      ]);
      yield "extension $prefixOfHas$name\$Ext$params"
          .plus(" on $name$args")
          .plusCurlyLines([
        "void init$prefixOfMix$name"
            .plusParen("$prefixOfMix$name$args mix")
            .plusCurlyLines([
          "mix.$camelName = this;",
        ]),
      ]);
    }

    final defaultValue = element.defaultValue;
    if (defaultValue != null) {
      yield "@HasDefault($defaultValue)";
    }

    yield* hasClass(name);
    yield "typedef $indirectName$params = $name$args Function();";
    yield* hasClass(indirectName);
  }
}
