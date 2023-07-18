import 'proto_meta/proto_meta_generator.dart';
import 'protoc.dart';

Future<void> runCompleteProtoGenerator(
  String packageName, {
  List<String> dependencies = const [],
}) async {
  await runProtoc(
    packageName,
    dependencies: dependencies,
  );
  await runProtoMetaGenerator(
    packageName,
    dependencies: dependencies,
  );
}
