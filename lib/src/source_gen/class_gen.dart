import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'class/constr.dart';
import 'class/field.dart';
import 'extension_gen.dart';
import 'gen.dart';
import 'generic.dart';
import 'param.dart';
import 'prop.dart';
import '../reflect.dart';
import 'source_generator.dart';
import 'typ.dart';

typedef SelfFn<S, R> = R Function(S self);

String passParams(Iterable<String> params) =>
    params.map((e) => '$e: $e,').join();

const valueVar = 'value';

String commentLineOf(String? comment) =>
    comment?.let((c) => '\n/// $c\n') ?? '';

const instanceVar = 'instance';

typedef Content = Iterable<MemberGen> Function(ClassGen self);

Iterable<MemberGen> noContent(ClassGen classGen) => const Iterable.empty();

enum ClassMod {
  none,
  abstract,
  mixin,
}

class ClassGen extends TopGen {
  final String name;
  final Iterable<Generic> generics;
  final ClassMod mod;
  final Iterable<ClassGen> Function(ClassGen self) implements;
  final Iterable<ClassGen> Function(ClassGen self) mixins;
  final Content content;
  final ClassGen? superClass;
  final Iterable<Constr> Function(ClassGen self) constructorsFn;
  final String? comment;
  final String? prefix;


  static Iterable<Constr> noConstrs(ClassGen self) => [
        Constr(owner: self),
      ];

  ClassGen({
    required this.name,
    this.mod = ClassMod.none,
    this.generics = const Iterable.empty(),
    this.implements = empty1,
    this.mixins = empty1,
    this.content = noContent,
    this.superClass,
    this.constructorsFn = noConstrs,
    this.comment,
    this.prefix,
  });

  static ClassGen hasDataOf(ClassGen type) => ClassGen(
        name: 'HasData',
        generics: [Generic.fromClassGen(type)],
      );

  factory ClassGen.singleton({
    required String name,
    Iterable<MemberGen> Function(ClassGen self) content = noContent,
    Iterable<ClassGen> Function(ClassGen self) implements = empty1,
    ClassGen? superClass,
    String constructorBody = ';',
    bool cnst = true,
    String? comment,
  }) =>
      ClassGen(
        name: name,
        constructorsFn: (self) => [
          Constr(
              owner: self, cnst: cnst, name: '_', body: (_) => constructorBody)
        ],
        content: (self) =>
            'static ${cnst ? 'const' : 'final'} $instanceVar = ${self.name}._();'
                .followedBy(content(self).map((e) => e.src).join())
                .asContent,
        implements: implements,
        superClass: superClass,
        comment: comment,
      );

  late final nameUncap = name.uncapitalize();

  late final Iterable<ClassGen> implementsList = implements(this);
  late final Iterable<ClassGen> mixinsList = mixins(this);

  late final singletonRef = '$name.$instanceVar';
  late final constructors = constructorsFn(this).toList(growable: false);

  late final singleConstructor = constructors.single;
  late final firstConstructor = constructors.first;

  late final defaultConstructor = Constr(owner: this);

  late final firstNoArgConstructorOpt =
      constructors.firstWhereOrNull((e) => e.isNoArg);

  String singletonGetter(String getterName) =>
      '$name get $getterName => $singletonRef;';

  // late final superClassOpt = superClass.nullableAsOpt();

  late final nameWithParams = '$nameWithPrefix${generics.paramsBrackets}';
  late final nameWithArgs = '$nameWithPrefix${generics.argsBrackets}';

  late final nameWithPrefix = prefix == null ? name : '$prefix.$name';

  late final typ = Typ(
    withoutNullability: nameWithArgs,
    nullable: false,
  );

  ExtensionGen extensionGen(
    String content, {
    String suffix = '\$Ext',
    Iterable<Generic>? generics,
    String? comment,
  }) =>
      ExtensionGen(
        suffix: suffix,
        base: this,
        generics: generics ?? this.generics,
        members: content.asContent,
      );

  String extension(
    String content, {
    String suffix = '\$Ext',
    Iterable<Generic>? generics,
    String? comment,
  }) =>
      extensionGen(
        content,
        suffix: suffix,
        generics: generics,
        comment: comment,
      ).src;


  factory ClassGen.fromInterfaceType(InterfaceType iface) => ClassGen(
        name: iface.element.name,
        generics: iface.typeArguments.map(Generic.fromDartType),
        constructorsFn: (self) =>
            Constr.fromConstructorElements(self, iface.constructors),
      );

  factory ClassGen.fromElement(Element iface) => ClassGen(
        name: iface.name!,
      );

  factory ClassGen.fromTypeDynamic(Type type) => ClassGen(name: nm(type));

  late final classTypeSrc = switch (mod) {
    ClassMod.none => 'class',
    ClassMod.abstract => 'abstract class',
    ClassMod.mixin => 'mixin',

  };

  late final classHeader = classTypeSrc
      .followedBy(' ')
      .followedBy(name)
      .followedBy(generics.paramsBrackets)
      .followedBy(superClass?.extendsSrc ?? '')
      .followedBy(mixinsList.mixinsSrc)
      .followedBy(implementsList.implementsSrc);

  @override
  late final src = [
    commentLineOf(comment),
    classHeader.andCurly([
      ...constructors.map((e) => e.src),
      content(this).srcsJoin,
    ]),
  ].join();

  late final asGenericArg = Generic.fromClassGen(this);

  ClassGen withGeneric1(ClassGen arg1) =>
      copyWith(generics: [arg1.asGenericArg]);

  late final prop = Prop(name: nameUncap, type: typ);

  static Iterable<MemberGen> fieldsWithConstr({
    required ClassGen self,
    required Iterable<Prop> props,
    ParamNaming naming = ParamNaming.unnamed,
    bool cnst = true,
    String constrName = '',
    ConstrBodyFn body = Constr.emptyBody,
  }) =>
      [
        ...props.map(FieldGen.new),
        Constr(
          owner: self,
          cnst: cnst,
          name: constrName,
          params: props.map(
            (e) => Param(
              prop: e,
              naming: naming,
              requirement: ParamRequirement.required,
              target: ParamTarget.thisTarget,
            ),
          ),
          body: body,
        )
      ];

  ClassGen copyWith({
    String? name,
    Iterable<Generic>? generics,
    ClassMod? mod,
    Iterable<ClassGen> Function(ClassGen self)? implements,
    Iterable<ClassGen> Function(ClassGen self)? mixins,
    Content? content,
    ClassGen? superClass,
    Iterable<Constr> Function(ClassGen self)? constructorsFn,
    String? comment,
    String? prefix,
  }) {
    return ClassGen(
      name: name ?? this.name,
      generics: generics ?? this.generics,
      mod: mod ?? this.mod,
      implements: implements ?? this.implements,
      mixins: mixins ?? this.mixins,
      content: content ?? this.content,
      superClass: superClass ?? this.superClass,
      constructorsFn: constructorsFn ?? this.constructorsFn,
      comment: comment ?? this.comment,
      prefix: prefix ?? this.prefix,
    );
  }

}

extension IterableClassWithGenericsX on Iterable<ClassGen> {
  String get implementsSrc =>
      map((e) => e.nameWithArgs).commasEnclosed(' implements ');

  String get mixinsSrc => map((e) => e.nameWithArgs).commasEnclosed(' with ');
}

extension OptClassWithGenericsX on ClassGen {
  String get extendsSrc =>
      ' extends $nameWithArgs ';
}
