import 'package:mhu_dart_commons/commons.dart';

import '../source_gen/class_gen.dart';
import 'proto_root.dart';
import 'protoc_plugin.dart';

String generateProtoMeta(String name, List<int> descriptorFileBytes) => PmgRoot(
      descriptorFileBytes,
      PmgCtx(descriptorFileBytes, name),
    ).generate();

const notSet = 'notSet';

/** [RxVarImplOpt] */
const TRxVarOpt = 'RxVarImplOpt';

final listClass = ClassGen(name: core(List));

const commonsPrefix = r'$commons';
const protoMetaPrefix = r'$proto_meta';
const protobufPrefix = r'$protobuf';

extension ClassGenProtoX on ClassGen {
  ClassGen get fromCommons => copyWith(
        prefix: commonsPrefix,
      );

  ClassGen get fromProtobuf => copyWith(
        prefix: protobufPrefix,
      );

  ClassGen get fromProtoMeta => copyWith(
        prefix: protoMetaPrefix,
      );
}

String core(Type type) => ProtocPlugin.core(type);

class PmgCtx {
  final String name;
  final List<int> descriptorFileBytes;

  PmgCtx(this.descriptorFileBytes, this.name);

  late final protoc = ProtocPlugin(descriptorFileBytes);

  late final nameCap = name.capitalize();
  late final nameUncap = name.uncapitalize();

  late final libInstanceClassName = nameCap;
  late final libStaticClassName = "$libInstanceClassName\$";

  late final libInstanceClassGen = ClassGen(name: libInstanceClassName);
  late final libInstanceGeneric = libInstanceClassGen.asGenericArg;
}
