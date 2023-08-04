import 'package:mhu_dart_commons/commons.dart';

part 'delegate_example.g.has.dart';
part 'delegate_example.g.compose.dart';


@Has()
typedef ReadValue<T extends Object> = T Function();

@Has()
typedef WriteValue<T> = void Function(T value);

@Has()
typedef WatchValue<T> = void Function(T value);

@Has()
typedef SaveValue = void Function()?;

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



