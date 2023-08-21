import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';

import 'ext_example.dart' as $lib;

part 'ext_example.g.dart';

class SomeClass<A> {}

void someMethod<A, B>(
  @Ext()
  SomeClass<SomeClass<A>> Function(
    SomeClass<B> input,
  ) someClass, {
  required int someInt,
  int someOtherInt = 5,
}) {}

void otherMethod<A, B>(
  @Ext()
  SomeClass<SomeClass<A>> Function(
    SomeClass<B> input,
  ) someClass, [
  int someOtherInt = 5,
]) {}
