
import '../class_gen.dart';
import '../gen.dart';
import '../prop.dart';
import 'method.dart';

typedef GetterBodyFn = SelfFn<GetterGen, MethodBodyGen>;

class GetterGen extends MemberGen {
  final Prop prop;
  final GetterBodyFn body;

  late final src =
      '${prop.type.withNullability} get ${prop.name}${body(this).src}';

  GetterGen({
    required this.prop,
    this.body = MissingBodyGen.fn,
  });

  GetterGen copyWith({
    Prop? prop,
    GetterBodyFn? body,
  }) {
    return GetterGen(
      prop: prop ?? this.prop,
      body: body ?? this.body,
    );
  }
}

