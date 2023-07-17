

import 'package:mhu_dart_builder/src/proto_meta/proto_root.dart';

import '../source_gen/source_generator.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';

import '../source_gen/class_gen.dart';
import '../source_gen/reflect.dart';
import 'proto_meta_generator.dart';
import 'proto_field.dart';
import 'proto_message.dart';

// final pmEnumCls = ClassGen.fromTypeDynamic(PmEnum).;
class PmgEnum {
  final PdEnum<PmgMsg, PmgFld, PmgEnum> enm;

  PmgEnum.create(this.enm);

  late final name = enm.name;

  late final nameUncap = name.uncapitalize();

  late final enumClassName =
      [...enm.parent.path.map((e) => e.name), name].join('_');

  late final enumClassGen = ClassGen(name: enumClassName);

  late final metaClassName = '$enumClassName\$Meta';

  late final instanceReference = '$metaClassName.instance';

  late final metaSuperClass = '${pmEnumCls.nameWithPrefix}<$enumClassName>';
  late final metaClassSrc =
      'class $metaClassName extends $metaSuperClass'.andCurly([
    'const $metaClassName._();',
    'static const instance = $metaClassName._();'
        '${core(List)}<$enumClassName> values() => $enumClassName.values;',
  ]);

  late final values = enm.descriptor.value;
  late final globalSrc = [
    metaClassSrc,
    'extension $enumClassName\$Ext on $enumClassName'.andCurly([
      '$result when<$result>'.andParenCurly([
        '$result Function()? $fallbackVar,',
        ...values.map((e) => '$result Function()? ${e.name},'),
      ]),
      [
        'switch(this)'.andCurly([
          ...values.map((v) =>
              'case $enumClassName.${v.name}: return (${v.name} ?? $fallbackVar ?? $commonsPrefix.throws0).call();'),
        ]),
        'throw this;'
      ].curly,
    ]),
  ].join();
}
