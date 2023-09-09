@HasOf<String>()
library;

import 'package:mhu_dart_annotation/mhu_dart_annotation.dart';

import 'delegate_example.dart' as $lib;
part 'delegate_example.g.has.dart';
part 'delegate_example.g.dart';


@Has()
typedef ReadValue<T extends Object> = T Function();

@Has()
typedef WriteValue<T> = void Function(T value);

@Has()
@Compose()
typedef WatchValue<T> = void Function(T value);

void _noop() {}

@Has()
@HasDefault(_noop)
typedef SaveValue = void Function();

@Compose()
abstract class ReadWrite<T extends Object>
    implements HasReadValue<T>, HasWriteValue<T> {}

@Compose()
abstract class ReadSave<T extends Object>
    implements HasReadValue<T>, HasSaveValue {}

@Compose()
abstract class ReadWriteSave<T extends Object>
    implements ReadWrite<T>, HasSaveValue {}

@Compose()
abstract class IfaceOnly<T extends Object>
    implements ReadWrite<T>, ReadSave<T> {}

abstract class Merge1 implements HasReadValue {}

abstract class Merge2<T extends Object> implements HasWriteValue<T> {}

@Compose()
abstract class Merge implements Merge1, Merge2, ReadWrite, HasWatchValue {}

@Has()
typedef Something<T> = Future<T>;

@Compose()
abstract class NullableTest implements HasSomething<int?> {
  static NullableTest of(Future<int?> something) {
    return ComposedNullableTest(
      something: something,
    );
  }
}

// @freezedStruct
// class TST with _$TST   {
//   factory TST({
//     required int columnCount,
//     required int rowCount,
//   }) = _TST;
//
//   factory TST.other({
//     required int x,
//   }) =>
//       TST(
//         columnCount: 0,
//         rowCount: 0,
//       );
// }
