import 'package:analyzer/dart/element/element.dart';
import 'package:mhu_dart_sourcegen/mhu_dart_sourcegen.dart';

extension ParameterElementX on ParameterElement {
  String get declareDart => declareDartParts.join();

  Iterable<String> get declareDartParts sync* {
    final defaultValueCode = this.defaultValueCode;
    yield* [
      if (isRequiredNamed) "required ",
      ...type.codeParts,
      " ",
      name,
      if (defaultValueCode != null) ...[
        "=",
        defaultValueCode,
      ],
      ",",
    ];
  }
}
