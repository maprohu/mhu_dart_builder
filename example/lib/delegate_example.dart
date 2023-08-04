import 'package:mhu_dart_commons/commons.dart';

part 'delegate_example.g.dart';

@Delegate()
typedef ReadValue<T> = T Function();

@Delegate()
typedef WriteValue<T> = void Function(T value);

@Delegate()
typedef SaveValue = void Function();

@Delegate()
abstract class ReadWrite<T> implements HasReadValue<T>, HasWriteValue<T> {}

@Delegate()
abstract class ReadWriteSave<T> implements ReadWrite<T>, HasSaveValue {}
