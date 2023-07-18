import 'package:mhu_dart_commons/commons.dart';

import '../source_generator.dart';
import '../gen.dart';
import '../prop.dart';

class FieldGen extends MemberGen {
  final Prop prop;
  final bool late;
  final String? defaultSrc;

  FieldGen(
    this.prop, {
    this.late = false,
    this.defaultSrc,
  });

  @override
  late final src = (late ? 'late ' : '')
      .followedBy('final ${prop.typeAndName}')
      .followedBy(defaultSrc?.let((v) => '=$v') ?? '')
      .andSemi;
}
