import 'package:mhu_dart_builder/src/source_gen/reflect.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protoc_plugin/protoc.dart';
import 'package:protoc_plugin/src/linker.dart';
import 'package:protoc_plugin/src/options.dart';
import 'package:protoc_plugin/src/shared.dart';
import 'package:protoc_plugin/src/generated/descriptor.pb.dart';

class ProtocPlugin {
  static String core(Type type) => '$coreImportPrefix.${type.simpleName}';

  final String preamble = "import 'dart:core' as $coreImportPrefix;";

  final List<int> descriptorFileBytes;
  late final FileDescriptorSet descriptorSet =
      FileDescriptorSet.fromBuffer(descriptorFileBytes);

  late final ctx = GenerationContext(null).also((ctx) {
    for (final e in descriptorSet.file) {
      ctx.registerProtoFile(
        FileGenerator(e, GenerationOptions()),
      );
    }
  });

  ProtocPlugin(this.descriptorFileBytes) {}

  String typeOfField(GeneratedMessage fieldDescriptorProto) {
    final descriptor =
        FieldDescriptorProto.fromBuffer(fieldDescriptorProto.writeToBuffer());

    return BaseType(descriptor, ctx).unprefixed;
  }
}
