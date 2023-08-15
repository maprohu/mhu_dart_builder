import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';
import 'package:mhu_dart_sourcegen/mhu_dart_sourcegen.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

Builder customizerBuilder(BuilderOptions options) =>
    SharedPartBuilder([CustomizerGenerator()], 'customizer');

class CustomizerGenerator extends GeneratorForAnnotation<Cst> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TypeAliasElement) {
      return "";
    }
    final aliasedType = element.aliasedType;
    if (aliasedType is! FunctionType) {
      return "";
    }

    var output = <String>[];

    final name = element.name;

    final pascalName = name.pascalCase;

    final outputParams = element.typeParameters;

    // final lookupChecker = TypeChecker.fromRuntime(Lookup);

    final keyParamCount =
        annotation.objectValue.getField("keyParamCount")!.toIntValue()!;

    final lookupParams = aliasedType.parameters.take(keyParamCount).toList();

    final inputParams =
        aliasedType.parameters.whereNot(lookupParams.contains).toList();

    final inputTypeParams = aliasedType.typeFormals;

    final dynamicMap = {
      for (final param in inputTypeParams)
        param.name:
            param.bound?.getDisplayString(withNullability: true) ?? "dynamic",
    };
    final dynamicLookupType = lookupParams
        .map((e) => e.type.substituteTypeArgs(dynamicMap))
        .toList()
        .joinEnclosedIfMultiple();

    final dynamicInputType = inputParams
        .map((e) => e.type.substituteTypeArgs(dynamicMap))
        .toList()
        .joinEnclosedIfMultiple();

    final dynamicOutputType =
        aliasedType.returnType.substituteTypeArgs(dynamicMap);

    late final functionType = element.name.plus(element.argumentsDart);

    late final outputType =
        aliasedType.returnType.getDisplayString(withNullability: true);

    final className = pascalName.plus("Customizer");

    Iterable<String> splitRecord(String name, int count) {
      if (count == 1) {
        return [name];
      } else {
        return Iterable.generate(
          count,
          (index) => "$name.\$${index + 1}",
        );
      }
    }

    "class $className"
        .plus(outputParams.parametersDart)
        .plus(" extends ${nm(GenericFeature)} ")
        .plus([
          dynamicLookupType,
          dynamicInputType,
          dynamicOutputType,
        ].joinInChevronOrEmpty())
        .plusCurlyLines([
      className
          .plusParenLines([
            functionType.plus(" defaultFeature,"),
          ])
          .plus(": super")
          .plusParenLines([
            "(key, input) => defaultFeature"
                .plusParenLines(
                  [
                    ...splitRecord("key", lookupParams.length),
                    ...splitRecord("input", inputParams.length),
                  ].plusCommas,
                )
                .plusComma,
          ])
          .plusSemi,
      "$outputType call".plus(inputTypeParams.parametersDart).plusParenLines([
        ...aliasedType.parameters
            .map((e) => e.getDisplayString(withNullability: true))
            .plusCommas
      ]).plus(
        "=>\$invoke"
            .plusParenLines(
              [
                lookupParams
                    .map((e) => e.name)
                    .toList()
                    .joinEnclosedIfMultiple(),
                inputParams
                    .map((e) => e.name)
                    .toList()
                    .joinEnclosedIfMultiple(),
              ].plusCommas,
            )
            .plus(" as ")
            .plus(outputType)
            .plusSemi,
      ),
      // "void put".plus(typeParamsInChevrons).plusParenLines([
      //   keyParamDef,
      //   "$outputType Function($inputParamDef) \$feature,"
      // ]).plus(" => \$put($keyCamel, \$feature);"),
    ]).addTo(output);

    return output.joinLines;
  }
}
// class CustomizerGenerator extends GeneratorForAnnotation<Cst> {
//   @override
//   String generateForAnnotatedElement(
//     Element element,
//     ConstantReader annotation,
//     BuildStep buildStep,
//   ) {
//     if (element is! TypeAliasElement) {
//       return "";
//     }
//     final aliasedType = element.aliasedType;
//     if (aliasedType is! FunctionType) {
//       return "";
//     }
//
//
//
//
//     var output = <String>[];
//
//     final customizers =
//         annotation.objectValue.getField("customizers")!.toListValue()!;
//
//     // const outputParam = "O";
//
//     for (final customizer in customizers) {
//       final name = customizer.getField("name")!.toStringValue()!;
//
//       final pascalName = name.pascalCase;
//
//       final typeParams = customizer.getField("typeParams")!.toListValue()!;
//
//       final typeParamsInChevrons = typeParams
//           .map((e) => e.getField("name")!.toStringValue()!)
//           .joinInChevronOrEmpty();
//       final keyField = customizer.getField("key")!;
//       final inputField = customizer.getField("input")!;
//       final outputField = customizer.getField("output")!;
//
//       final paramChecker = TypeChecker.fromRuntime(TypeParam);
//
//       String typeWithoutArgs(DartObject object) {
//         if (paramChecker.isExactlyType(object.type!)) {
//           return "dynamic";
//         }
//         return (object.type as InterfaceType)
//             .typeArguments
//             .first
//             .element!
//             .name!;
//       }
//
//       final keyType = typeWithoutArgs(keyField);
//
//       final inputType = typeWithoutArgs(inputField);
//
//       String typeParamName(DartObject object) {
//         return object.getField("name")!.toStringValue()!;
//       }
//
//       String typeWithArgs(DartObject typeWithArgsObject) {
//         // final typeChecker = TypeChecker.fromRuntime(TypeWithArgs);
//         if (paramChecker.isExactlyType(typeWithArgsObject.type!)) {
//           return typeParamName(typeWithArgsObject)
//               .plusNullable(typeWithArgsObject);
//         }
//
//         final typeArgs =
//             typeWithArgsObject.getField("typeArgs")!.toListValue()!;
//
//         return typeWithoutArgs(typeWithArgsObject).plus(
//           typeArgs.map((e) {
//             if (paramChecker.isExactlyType(e.type!)) {
//               return typeParamName(e);
//             } else {
//               return typeWithArgs(e);
//             }
//           }).joinInChevronOrEmpty(),
//         ).plusNullable(typeWithArgsObject);
//       }
//
//       final outputParams = customizer
//           .getField("outputParams")!
//           .toListValue()!
//           .map(typeParamName)
//           .toList();
//
//       final keyCamel = keyType.camelCase;
//       final inputCamel = inputType.camelCase;
//
//       final keyParamDef =
//           typeWithArgs(keyField).plusSpace.plus(keyCamel).plusComma;
//       final inputParamDef =
//           typeWithArgs(inputField).plusSpace.plus(inputCamel).plusComma;
//
//       final invokeFunctionDef = typeParamsInChevrons.plusParenLines([
//         keyParamDef,
//         inputParamDef,
//       ]);
//
//       final outputType = typeWithArgs(outputField);
//
//       "class $pascalName"
//           .plus(outputParams.joinInChevronOrEmpty())
//           .plus(" extends ${nm(GenericFeature)} ")
//           .plus([
//             keyType,
//             inputType,
//             typeWithoutArgs(outputField),
//           ].joinInChevronOrEmpty())
//           .plusCurlyLines([
//         pascalName.plusParenLines([
//           "$outputType Function"
//               .plus(invokeFunctionDef)
//               .plus(" defaultFeature,"),
//         ]).plus(": super(defaultFeature);"),
//         "$outputType call"
//             .plus(invokeFunctionDef)
//             .plus("=>\$invoke($keyCamel, $inputCamel);"),
//         "void put".plus(typeParamsInChevrons).plusParenLines([
//           keyParamDef,
//           "$outputType Function($inputParamDef) \$feature,"
//         ]).plus(" => \$put($keyCamel, \$feature);"),
//       ]).addTo(output);
//     }
//
//     return output.joinLines;
//   }
// }

extension _X on String {
  String plusNullable(DartObject type) {
    var nullable = type.getField("nullable")?.toBoolValue();

    while (nullable == null) {
      type = type.getField("(super)")!;
      nullable = type.getField("nullable")?.toBoolValue();
    }

    if (nullable) {
      return plus("?");
    } else {
      return this;
    }
  }
}
