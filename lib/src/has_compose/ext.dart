import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';
import 'package:mhu_dart_builder/src/has_compose/has_compose.dart';
import 'package:mhu_dart_builder/src/parameter_element.dart';
import 'package:mhu_dart_sourcegen/mhu_dart_sourcegen.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

Builder extBuilder(BuilderOptions options) =>
    SharedPartBuilder([ExtGenerator()], "ext");

class ExtGenerator extends Generator {
  TypeChecker get typeChecker => TypeChecker.fromRuntime(Ext);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    return generateExtMethods(library).join();
  }

  Iterable<String> generateExtMethods(LibraryReader library) sync* {
    for (final element in library.allElements) {
      if (element case FunctionElement()) {
        for (final parameter in element.parameters) {
          final ext = typeChecker.firstAnnotationOf(parameter);
          if (ext != null) {
            yield* generateExtMethod(element, parameter, ext);
          }
        }
      }
    }
  }

  Iterable<String> generateExtMethod(
    FunctionElement function,
    ParameterElement parameter,
    DartObject annotation,
  ) sync* {
    final parameterType = parameter.type;
    final parameterGenericNames =
        parameterType.findTypeParameters.map((e) => e.element.name).toSet();
    final extensionGenerics = function.typeParameters
        .where(
          (e) => parameterGenericNames.contains(e.name),
        )
        .toList();

    final methodGenerics = function.typeParameters
        .whereNot(
          (e) => parameterGenericNames.contains(e.name),
        )
        .toList();

    final methodParams =
        function.parameters.where((e) => e != parameter).toList();

    final plainParamCount =
        methodParams.takeWhile((e) => e.isRequiredPositional).length;

    final plainParams = methodParams.sublist(0, plainParamCount);
    final specialParams = methodParams.sublist(plainParamCount);

    Iterable<String> paramListOf(Iterable<ParameterElement> params) sync* {
      for (final param in params) {
        yield* param.declareDartParts;
      }
    }

    // Iterable<String> specialParamListOf(
    //     Iterable<ParameterElement> params) sync* {
    //   for (final param in params) {
    //     yield param.getDisplayString(withNullability: true).unenclosed;
    //     yield ",";
    //   }
    // }

    Iterable<String> paramList() sync* {
      yield* paramListOf(plainParams);
      final firstSpecialParam = specialParams.firstOrNull;
      if (firstSpecialParam != null) {
        final specials = paramListOf(specialParams);

        if (firstSpecialParam.isNamed) {
          yield* specials.enclosedInCurly;
        } else {
          yield* specials.enclosedInBracket;
        }
      }
    }

    Iterable<String> argList({String thisName = "this"}) sync* {
      for (final param in function.parameters) {
        if (param.isNamed) {
          yield param.name;
          yield ":";
        }
        if (param == parameter) {
          yield thisName;
        } else {
          yield param.name;
        }

        yield ",";
      }
    }

    Strings createExtension({
      required String onType,
      Strings nameSuffix = const [],
      String thisName = "this",
    }) sync* {
      yield r"extension ";
      yield r'$';
      yield function.name;
      yield r'$';
      yield parameter.name;
      yield r'$';
      yield nm(Ext);
      yield* nameSuffix;
      yield extensionGenerics.parametersDart;
      yield r" on ";
      yield onType;
      yield [
        function.returnType.getDisplayString(withNullability: true),
        " ",
        function.displayName,
        methodGenerics.parametersDart,
        ...paramList().enclosedInParen,
        "=>",
        r'$lib.',
        function.displayName,
        function.typeParameters.argumentsDart,
        ...argList(
          thisName: thisName,
        ).enclosedInParen,
        ";",
      ].joinInCurlyOrEmpty();
    }

    yield* createExtension(
      onType: parameterType.getDisplayString(withNullability: true),
    );

    Element aliasOrTypeElement(DartType type) {
      final alias = type.alias;
      return alias == null ? type.element! : alias.element;
    }

    if (annotation.getField("has")!.toBoolValue()!) {
      final type = parameterType as ParameterizedType;
      final typeElement = aliasOrTypeElement(type);

      yield* createExtension(
        nameSuffix: [
          r'$',
          nm(Has),
        ],
        onType: [
          prefixOfHas,
          typeElement.displayName,
          type.typeArguments
              .map((e) => e.getDisplayString(withNullability: true))
              .joinInChevronOrEmpty(),
        ].join(),
        thisName: typeElement.displayName.camelCase,
      );

      // yield r"extension ";
      // yield r'$';
      // yield function.name;
      // yield r'$';
      // yield parameter.name;
      // yield r'$';
      // yield nm(Ext);
      // yield r'$';
      // yield nm(Has);
      // yield extensionGenerics.parametersDart;
      // yield r" on ";
      // yield prefixOfHas;
      // yield typeElement.displayName;
      // yield type.typeArguments
      //     .map((e) => e.getDisplayString(withNullability: true))
      //     .joinInChevronOrEmpty();
      // yield [
      //   function.returnType.getDisplayString(withNullability: true),
      //   " ",
      //   function.displayName,
      //   methodGenerics.parametersDart,
      //   ...paramList().enclosedInParen,
      //   "=>",
      //   r'$lib.',
      //   function.displayName,
      //   methodGenerics.argumentsDart,
      //   ...argList(
      //     thisName: typeElement.displayName.camelCase,
      //   ).enclosedInParen,
      //   ";",
      // ].joinInCurlyOrEmpty();
    }
  }
}
