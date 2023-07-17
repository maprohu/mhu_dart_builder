import '../source_generator.dart';
import '../class_gen.dart';
import '../gen.dart';

class TypedefGen extends TopGen {
  final ClassGen left;
  final ClassGen right;
  final String? comment;

  TypedefGen(
    this.left,
    this.right, {
    this.comment,
  });

  @override
  String get src => [
        commentLineOf(comment),
        'typedef ${left.nameWithParams} = ${right.nameWithArgs}'.andSemi,
      ].join();
}
