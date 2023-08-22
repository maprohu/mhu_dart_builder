import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';

import 'ext_example.dart' as $lib;

part 'ext_example.g.dart';

part 'ext_example.g.has.dart';


@Has()
typedef SomeInt = int;

class SomeClass<A> {}

void someMethod<A, B>(
  @Ext()
  SomeClass<SomeClass<A>> Function(
    SomeClass<B> input,
  ) someClass, {
  @Ext(has: true) required SomeInt someInt,
  int someOtherInt = 5,
}) {}

void otherMethod<A, B>(
  @Ext()
  SomeClass<SomeClass<A>> Function(
    SomeClass<B> input,
  ) someClass, [
  int someOtherInt = 5,
]) {}
