import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:source_gen/source_gen.dart';

Builder delegateBuilder(BuilderOptions options) => SharedPartBuilder(
      [DelegateGenerator()],
      'delegate',
    );

class DelegateGenerator extends GeneratorForAnnotation<Delegate> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, buildStep) {
    return "// $element";
  }
}
