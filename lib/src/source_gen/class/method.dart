


import '../source_generator.dart';

import '../class_gen.dart';
import '../gen.dart';
import '../mthd.dart';

typedef MethodBodyFn = SelfFn<MethodGen, MethodBodyGen>;

class MethodGen extends MemberGen {
  final Mthd mthd;
  final MethodBodyFn body;

  late final src = mthd.declare.followedBy(body(this).src);

  MethodGen({
    required this.mthd,
    this.body = MethodBodyGen.missing,
  });

  late final firstParam = mthd.firstParam;

  MethodGen copyWith({
    Mthd? mthd,
    MethodBodyFn? body,
  }) {
    return MethodGen(
      mthd: mthd ?? this.mthd,
      body: body ?? this.body,
    );
  }
}

extension MethodBodyStringX on String {
  SelfFn<Object, MethodBodyGen> get asExpressionBody =>
      (_) => ExpressionBodyGen(this);

  MethodBodyFn get asBlockBody => (_) => BlockBodyGen(this);
}

abstract class MethodBodyGen {
  const MethodBodyGen._();

  static MethodBodyGen missing(MethodGen self) => MissingBodyGen.instance;

  String get src;
}

class MissingBodyGen extends MethodBodyGen {
  const MissingBodyGen._() : super._();
  static const instance = MissingBodyGen._();

  static MissingBodyGen fn(_) => instance;

  @override
  String get src => ';';
}

class ExpressionBodyGen extends MethodBodyGen {
  final String expression;

  const ExpressionBodyGen(this.expression) : super._();

  @override
  String get src => '=>'.followedBy(expression).andSemi;
}

class BlockBodyGen extends MethodBodyGen {
  final String content;

  const BlockBodyGen(this.content) : super._();

  String get src => content.curly;
}

