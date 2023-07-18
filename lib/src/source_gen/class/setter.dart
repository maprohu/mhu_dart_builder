import '../source_generator.dart';
import '../gen.dart';
import '../prop.dart';

class SetterGen extends MemberGen {
  final Prop prop;
  final String Function(String valueVar) body;

  late final valueVar = prop.name;

  @override
  late final src = 'set ${prop.name}'.andParen([
    '${prop.type.withNullability} $valueVar',
  ]).followedBy(body(valueVar));

  static String emptyBody(String valueVar) => ';';

  SetterGen({
    required this.prop,
    this.body = emptyBody,
  });
}
