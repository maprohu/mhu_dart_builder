import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'generic.dart';
import 'prop.dart';

class Fn {
  final String type;
  final Iterable<Prop> params;
  final String name;
  final Iterable<Generic> generics;

  Fn({
    required this.type,
    required this.params,
    required this.name,
    this.generics = const [],
  });

  // late final unnamedParamsParen = params.unnamedParams.paren;

  // late final genericsAndUnnamedParamsParen =
  //     '${generics.paramsBrackets}$unnamedParamsParen';

  // late final prop = Prop(
  //   name: name,
  //   type: Typ(
  //     withoutNullability: '$type Function$genericsAndUnnamedParamsParen',
  //     nullable: false,
  //   ),
  // );

  // late final declarationHeader = '$type $name$genericsAndUnnamedParamsParen';

  Fn.fromMethod(MethodElement m) : this.fromFunctionType(m.name, m.type);

  // Fn.fromMethod(MethodElement m)
  //     : this(
  //         type: m.returnType.toString(),
  //         name: m.name,
  //         params: m.parameters.map(Prop.fromParameter),
  //         generics: m.typeParameters.map(
  //           (e) => Generic(e.name, e.bound?.toString()),
  //         ),
  //       );

  Fn.fromFunctionType(String name, FunctionType m)
      : this(
    type: m.returnType.toString(),
    name: name,
    params: m.parameters.map(Prop.fromParameter),
    generics: m.typeFormals.map(
          (e) => Generic(e.name, e.bound?.toString()),
    ),
  );

  late final passUnnamedArgs = params.unnamedArgPasses.join();
//
// late final passUnnamedParams = params.passUnnamedParamsString;
}
