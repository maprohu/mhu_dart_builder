import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';

import 'generic.dart';
import 'param.dart';
import 'prop.dart';
import 'typ.dart';

class Mthd {
  final Typ type;
  final Iterable<Param> params;
  final String name;
  final Iterable<Generic> generics;

  Mthd({
    required this.type,
    required this.params,
    required this.name,
    this.generics = const [],
  });

  late final paramList = ParamList(params);

  late final genericsAndParamList = generics.paramsBrackets.andParen([
    paramList.declare,
  ]);
  late final returnTypeSrc = type.withNullability;
  late final declare = '$returnTypeSrc $name$genericsAndParamList';

  late final functionType = Typ(
    withoutNullability: '$returnTypeSrc Function$genericsAndParamList',
    nullable: false,
  );

  late final functionProp = Prop(
    name: name,
    type: functionType,
  );

  Mthd.fromMethod(ExecutableElement m)
      : this.fromFunctionType(
    m.displayName,
    m.type,
  );

  Mthd.fromFunctionType(String name, FunctionType m)
      : this(
    name: name,
    type: Typ.fromType(m.returnType),
    params: m.parameters.map(Param.fromElement),
    generics: m.typeFormals.map(
          (e) => Generic(e.name, e.bound?.toString()),
    ),
  );

  Mthd copyWith({
    Typ? type,
    Iterable<Param>? params,
    String? name,
    Iterable<Generic>? generics,
  }) {
    return Mthd(
      type: type ?? this.type,
      params: params ?? this.params,
      name: name ?? this.name,
      generics: generics ?? this.generics,
    );
  }

  late final firstParam = params.first;
}
