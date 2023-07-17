import 'package:analyzer/dart/element/element.dart';
import '../source_generator.dart';
import '../class_gen.dart';
import '../gen.dart';
import '../mthd.dart';
import '../param.dart';
import 'method.dart';

typedef ConstrBodyFn = String Function(Constr self);

class Constr implements MemberGen {
  final ClassGen owner;
  final String name;
  final Iterable<Param> params;
  final ConstrBodyFn body;
  final bool cnst;
  final bool factory;

  static String emptyBody(Constr self) => ';';

  static String superUnderscore(Constr self) => ': super._();';

  Constr({
    required this.owner,
    this.name = '',
    this.params = const [],
    this.body = emptyBody,
    this.cnst = false,
    this.factory = false,
  });

  late final firstParamName = params.first.name;
  late final paramList = ParamList(params);

  late final isDefault = name.isEmpty;

  late final constSrc = cnst ? 'const ' : '';
  late final factorySrc = factory ? 'factory ' : '';

  String sepName(String sep) => name.isEmpty ? '' : '$sep$name';

  late final dotName = sepName('.');
  late final dollarName = sepName('\$');

  late final bodySrc = body(this);

  late final ref = '${owner.name}$dotName';

  late final src = constSrc
      .followedBy(factorySrc)
      .followedBy(ref)
      .andParen([paramList.declare]).followedBy(bodySrc);

  late final isNoArg = params.every((e) => e.isOptional);

  Constr.fromElement(ClassGen owner, ConstructorElement element)
      : this(
          owner: owner,
          name: element.name,
          cnst: element.isConst,
          params: element.parameters.map(Param.fromElement),
        );

  static Iterable<Constr> fromConstructorElements(
    ClassGen owner,
    Iterable<ConstructorElement> constructors, {
    bool includeFactoryConstructors = false,
  }) =>
      constructors
          .where((e) => (includeFactoryConstructors || !e.isFactory) && e.isPublic)
          .map((e) => Constr.fromElement(owner, e));

  Mthd factoryMethod(String? name) => Mthd(
        type: owner.typ,
        params: params.map((e) => e.copyWith(target: ParamNoTarget())),
        name: name ?? this.name,
        generics: owner.generics,
      );

  MethodGen factoryMethodGen(String? name) => MethodGen(
        mthd: factoryMethod(name),
        body: ref.andParen([paramList.passArgs]).asExpressionBody,
      );

  late final paramsNoTarget = params.map(
    (e) => e.copyWith(
      target: ParamNoTarget(),
    ),
  );

  String invokeSrc(Iterable<String> args) => ref.andParen(args);
}
