import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';

import 'ext_example.dart' as $lib;

part 'ext_example.g.dart';

part 'ext_example.g.has.dart';

@Has()
typedef SomeInt = int;

class SomeClass<A> {}

typedef SomeFunction = void Function();

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
  ) someClass,
  SomeFunction someFunction, [
  int someOtherInt = 5,
  Function(Function(int x))? x,
]) {}

void thirdMethod<A, B>(
  @Ext() SomeClass<SomeClass<A>> Function() someClass,
  SomeFunction someFunction, [
  int someOtherInt = 5,
  Function(Function(int x))? x,
]) {}


void mappingMethod({
  @ext required int a,
  @ext required int b,
}) {

}