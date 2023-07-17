import '../source_generator.dart';

import '../gen.dart';
import '../prop.dart';

class ConstGen extends MemberGen {
  final Prop prop;
  final String value;

  late final src = 'const ${prop.typeAndName} = $value'.andSemi;

  ConstGen({
    required this.prop,
    required this.value,
  });
}
