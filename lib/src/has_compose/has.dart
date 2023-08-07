part of 'has_compose.dart';

Builder delegateHasClassBuilder(BuilderOptions options) => PartBuilder(
  [DelegateHasClassGenerator()],
  '.g.has.dart',
);

class DelegateHasClassGenerator extends GeneratorForAnnotation<Has> {
  @override
  generateForAnnotatedElement(
      Element element,
      ConstantReader annotation,
      buildStep,
      ) {
    element as TypeParameterizedElement;

    var output = <String>[];

    final name = element.displayName;
    final params = element.parametersDart;
    final args = element.argumentsDart;
    // final indirectName = "$name$suffixOfIndirect";

    void hasClass(String name) {
      final camelName = name.camelCase;

      "abstract class $prefixOfHas$name$params".plusCurlyLines([
        "$name$args get $camelName;",
      ]).addTo(output);
    }

    final defaultValue = element.defaultValue;
    if (defaultValue != null) {
      "@HasDefault($defaultValue)".addTo(output);
    }

    hasClass(name);
    // "typedef $indirectName$params = $name$args Function();".also(out);
    // hasClass(indirectName);
    //
    // "extension $prefixOfHas$indirectName\$Ext$params on $prefixOfHas$indirectName$args"
    //     .plusCurlyLines([
    //   "$name$args get ${name.camelCase} => ${name.camelCase}$suffixOfIndirect();"
    // ]).also(out);

    return output.joinLines;
  }
}

extension _AnyX<T> on T {
  void addTo(List<T> target) => target.add(this);

}
