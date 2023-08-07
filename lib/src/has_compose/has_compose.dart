
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

// ignore: implementation_imports
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';
import 'package:mhu_dart_sourcegen/mhu_dart_sourcegen.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

part 'has.dart';

part 'compose.dart';

const prefixOfHas = "Has";
// const suffixOfIndirect = "Indirect";

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
