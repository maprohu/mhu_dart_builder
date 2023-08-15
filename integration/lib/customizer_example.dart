import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';

part 'customizer_example.g.dart';

class ExampleBase {}

class ExampleKey<T extends ExampleBase, A, B> {}

class ExampleInput<A, B> {}

const paramA = TypeParam("A");
const paramB = TypeParam("B");

@Customizers([
  Customizer(
    name: "exampleFeature",
    typeParams: [
      paramA,
      paramB,
    ],
    key: TypeWithArgs<ExampleKey>(typeArgs: [
      TypeWithArgs<ExampleBase>(),
      paramA,
      paramB,
    ]),
    input: TypeWithArgs<ExampleInput>(typeArgs: [
      paramA,
      paramB,
    ]),
    outputParams: [],
    output: TypeParam("A", nullable: true),
  ),
])
class ExampleCustomizers {}

/*
class ExampleFeature extends GenericFeature<ExampleKey, ExampleOutput, dynamic> {
  ExampleFeature(
    A Function<A, B>(
      ExampleKey<ExampleBase, A, B> exampleKey,
      ExampleOutput<A, B> exampleOutput,
    ) defaultFeature,
  ) : super(defaultFeature);

  A call<A, B>(
    ExampleKey<ExampleBase, A, B> exampleKey,
    ExampleOutput<A, B> exampleOutput,
  ) =>
      $invoke(exampleKey, exampleOutput);

  void put<A, B>(
    ExampleKey<ExampleBase, A, B> exampleKey,
    A Function(
      ExampleOutput<A, B> exampleOutput,
    ) $feature,
  ) =>
      $put(exampleKey, $feature);
}
*/

class ExampleOutput<A, B> {}

@Cst()
typedef TestFeature<O> = ExampleOutput<O, K>? Function<K, V>(
  ExampleKey<ExampleBase, K, V> key,
  ExampleInput<K, V> input,
);

@Cst(
  keyParamCount: 2,
)
typedef TestFeature2<O> = ExampleOutput<O, K>? Function<K, V>(
  ExampleKey<ExampleBase, K, V> key1,
  ExampleKey<ExampleBase, K, V> key2,
  ExampleInput<K, V> input1,
  ExampleInput<K, V> input2,
);
