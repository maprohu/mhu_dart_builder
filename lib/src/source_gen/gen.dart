abstract class SourceGen {
  String get src;
}

abstract class TopGen extends SourceGen {}

abstract class MemberGen extends SourceGen {}

abstract class ElemGen implements TopGen, MemberGen {}

class GenString extends MemberGen {
  @override
  final String src;

  GenString(this.src);
}

extension StringMemberGenX on String {
  GenString get asGen => GenString(this);

  Iterable<MemberGen> get asContent => [asGen];
}

extension IterableMemberGenX on Iterable<SourceGen> {
  Iterable<String> get srcs => map((e) => e.src);

  String get srcsJoin => srcs.join();
}
