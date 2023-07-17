


import 'package:mhu_dart_builder/src/source_gen/class/method.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_commons/commons.dart';

import 'class/const.dart';
import 'class/constr.dart';
import 'class/getter.dart';
import 'class_gen.dart';
import 'gen.dart';
import 'prop.dart';

// String factoryClass({
//   required String name,
//   required String content,
//   required ClassGen target,
// }) {
// }

class FactoryClassGen extends TopGen {
  final String name;
  final String content;
  final ClassGen target;

  FactoryClassGen({
    required this.name,
    required this.content,
    required this.target,
  });

  late final factoryClassName = '${name.capitalize()}\$Factory';
  late final factoryInstance = '${name.uncapitalize()}\$Factory';

  late final classGen = ClassGen(
    name: factoryClassName,
    constructorsFn: (self) => [Constr(owner: self, cnst: true)],
    content: (self) => content.asContent,
  );

  late final src = [
    classGen,
    // 'class $factoryClassName'.andCurly([
    //   'const $factoryClassName();',
    //   content,
    // ]),
    ConstGen(
      prop: Prop(
        name: factoryInstance,
        type: classGen.typ,
      ),
      value: factoryClassName.andParen([]),
    ),
    // 'const $factoryInstance = $factoryClassName();',
    target.extensionGen(
      GetterGen(
        prop: Prop(
          type: classGen.typ,
          name: name,
        ),
        body: factoryInstance.asExpressionBody,
      ).src,
      // '$factoryClassName get $name => $factoryInstance;',
      suffix: '\$Ext\$$name',
    ),
  ].srcsJoin;
}
