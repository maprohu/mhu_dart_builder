import 'package:mhu_dart_commons/commons.dart';

part 'delegate_example.g.has.dart';
part 'delegate_example.g.compose.dart';


@Delegate()
typedef ReadValue<T extends Object> = T Function();

@Delegate()
typedef WriteValue<T> = void Function(T value);

@Delegate()
typedef SaveValue = void Function();

@Delegate()
abstract class ReadWrite<T extends Object>
    implements HasReadValue<T>, HasWriteValue<T> {}

@Delegate()
abstract class ReadSave<T extends Object>
    implements HasReadValue<T>, HasSaveValue {}

@Delegate()
abstract class ReadWriteSave<T extends Object>
    implements ReadWrite<T>, HasSaveValue {}

@Delegate()
abstract class IfaceOnly<T extends Object>
    implements ReadWrite<T>, ReadSave<T> {}
