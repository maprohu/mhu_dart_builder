import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';
import 'package:mhu_dart_builder/src/has_compose/has_compose.dart';
import 'package:mhu_dart_sourcegen/mhu_dart_sourcegen.dart';
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
        yield param.getDisplayString(withNullability: true);
        yield ",";
      }
    }

    Iterable<String> specialParamListOf(
        Iterable<ParameterElement> params) sync* {
      for (final param in params) {
        yield param.getDisplayString(withNullability: true).unenclosed;
        yield ",";
      }
    }

    Iterable<String> paramList() sync* {
      yield* paramListOf(plainParams);
      final firstSpecialParam = specialParams.firstOrNull;
      if (firstSpecialParam != null) {
        final specials = specialParamListOf(specialParams);

        if (firstSpecialParam.isNamed) {
          yield* specials.enclosedInCurly;
        } else {
          yield* specials.enclosedInBracket;
        }
      }
    }

    Iterable<String> argList({bool has = false}) sync* {
      for (final param in function.parameters) {
        if (param.isNamed) {
          yield param.name;
          yield ":";
        }
        if (!has && param == parameter) {
          yield "this";
        } else {
          yield param.name;
        }

        yield ",";
      }
    }

    yield r"extension ";
    yield r'$';
    yield function.name;
    yield r'$';
    yield parameter.name;
    yield r'$';
    yield nm(Ext);
    yield extensionGenerics.parametersDart;
    yield r" on ";
    yield parameterType.getDisplayString(withNullability: true);
    yield [
      function.returnType.getDisplayString(withNullability: true),
      " ",
      function.displayName,
      methodGenerics.parametersDart,
      ...paramList().enclosedInParen,
      "=>",
      r'$lib.',
      function.displayName,
      ...argList().enclosedInParen,
      ";",
    ].joinInCurlyOrEmpty();

    if (annotation.getField("has")!.toBoolValue()!) {
      final type = parameterType as ParameterizedType;
      final alias = type.alias;
      final typeElement = alias == null ? type.element! : alias.element;

      yield r"extension ";
      yield r'$';
      yield function.name;
      yield r'$';
      yield parameter.name;
      yield r'$';
      yield nm(Ext);
      yield r'$';
      yield nm(Has);
      yield extensionGenerics.parametersDart;
      yield r" on ";
      yield prefixOfHas;
      yield typeElement.displayName;
      yield type.typeArguments
          .map((e) => e.getDisplayString(withNullability: true))
          .joinInChevronOrEmpty();
      yield [
        function.returnType.getDisplayString(withNullability: true),
        " ",
        function.displayName,
        methodGenerics.parametersDart,
        ...paramList().enclosedInParen,
        "=>",
        r'$lib.',
        function.displayName,
        ...argList(has: true).enclosedInParen,
        ";",
      ].joinInCurlyOrEmpty();
    }
  }
}
