


import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';
import 'package:mhu_dart_commons/commons.dart';

import 'class/constr.dart';
import 'class/method.dart';
import 'class_gen.dart';
import 'gen.dart';
import 'generic.dart';
import 'mthd.dart';
import 'param.dart';
import 'prop.dart';
import 'when_method_gen.dart';

class WhenClassGen extends TopGen {
  final String name;
  final Iterable<String> options;

  late final classes = options
      .map(
        (e) => WhenClassOption(gen: this, name: e),
      )
      .toList();

  late final whenMethodGen = WhenMethodGen(
    methodName: 'when',
    classes: (gen) => classes.map(
      (e) => e.methodClassGen(
        methodGen: gen,
        responder: false,
      ),
    ),
    callbackValues: (self) => [],
    commonType: baseGeneric.typ,
  );

  late final baseGeneric = Generic('T\$');

  late final mappedBaseGeneric = Generic('M'.followedBy(baseGeneric.name));

  late final classGenerics = classes.map((e) => e.generic);

  late final mapGenerics = [
    mappedBaseGeneric,
    ...classes.map((e) => e.mappedGeneric),
  ];

  MethodGen mapMethodGenFor(String ref, bool firstGeneric) => MethodGen(
        mthd: Mthd(
          name: 'map',
          type: classGen.copyWith(generics: mapGenerics).typ,
          generics: firstGeneric ? mapGenerics : mapGenerics.skip(1),
          params: classes.map(
            (e) => Param(
              prop: e.mappedFunctionProp,
              naming: ParamNaming.named,
              requirement: ParamRequirement.required,
            ),
          ),
        ),
        body: ref
            .callMethod(
              'when',
              classes.map(
                (e) => '${e.alias}: (v\$) => ${e.classGen.name}._'.andParen([
                  e.alias.andParen(['v\$']),
                ]).andComma,
              ),
            )
            .asExpressionBody,
      );

  late final mapMethodGen = mapMethodGenFor('this', true);

  late final mapperClassGen = ClassGen(
    name: classGen.name.andDollar.followedBy('Mapper'),
    generics: [
      mappedBaseGeneric,
      ...classGen.generics,
    ],
    constructorsFn: (self) => [],
    content: (self) {
      final prop = Prop(
        name: 'self\$',
        type: classGen.typ,
      );
      return [
        ...ClassGen.fieldsWithConstr(
          self: self,
          constrName: '_',
          props: [prop],
        ),
        mapMethodGenFor(prop.name, false),
      ];
    },
  );

  late final mapperMethodGen = MethodGen(
      mthd: Mthd(
        name: 'mapper',
        type: mapperClassGen.typ,
        generics: [mappedBaseGeneric],
        params: [],
      ),
      body: mapperClassGen.name.callMethod('_', ['this']).asExpressionBody);

  late final ClassGen classGen = ClassGen(
    name: name.capitalize(),
    mod: ClassMod.abstract,
    generics: [
      baseGeneric,
      ...classGenerics,
    ],
    constructorsFn: (self) => [
      Constr(
        owner: self,
        cnst: true,
        name: '_',
      ),
    ],
    content: (self) => [
      whenMethodGen.requiredMethodHeaderGen,
      whenMethodGen.maybeMethodGen,
      mapMethodGen,
      mapperMethodGen,
    ],
  );

  @override
  late final src = [
    classGen,
    mapperClassGen,
    ...classes,
  ].srcsJoin;

  WhenClassGen({
    required this.name,
    required this.options,
  });
}

class WhenClassOption extends TopGen {
  final WhenClassGen gen;
  final String name;

  WhenClassOption({
    required this.gen,
    required this.name,
  });

  late final alias = name.uncapitalize();

  late final generic = Generic(
    gen.baseGeneric.name.followedBy(name),
    gen.baseGeneric.name,
  );

  late final mappedGeneric = Generic(
    gen.mappedBaseGeneric.name.followedBy(name),
    gen.mappedBaseGeneric.name,
  );

  late final mappedFunctionProp = Mthd(
    type: mappedGeneric.typ,
    params: [Param.fromProp(prop)],
    name: alias,
  ).functionProp;

  late final prop = Prop(
    name: alias,
    type: generic.typ,
  );

  late final classGen = ClassGen(
    name: gen.classGen.name.andDollar.followedBy(name),
    generics: gen.classGen.generics,
    superClass: gen.classGen,
    constructorsFn: (self) => [],
    content: (self) => [
      ...ClassGen.fieldsWithConstr(
        self: self,
        props: [prop],
        constrName: '_',
        body: Constr.superUnderscore,
      ),
      gen.whenMethodGen.requiredMethodHeaderGen.copyWith(
        body: alias.andParen([
          'this.${prop.name}',
        ]).asExpressionBody,
      ),
    ],
  );

  WhenMethodClassGen methodClassGen({
    required WhenMethodGen methodGen,
    required bool responder,
  }) =>
      WhenMethodClassGen(
        gen: methodGen,
        alias: alias,
        callbackParams: (self) => [
          Param.simple(
            name: self.alias,
            type: generic.typ,
          ),
        ],
        responder: responder,
      );

  @override
  late final src = [classGen].srcsJoin;
}
