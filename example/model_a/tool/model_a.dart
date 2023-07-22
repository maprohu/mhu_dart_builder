import 'dart:io';

import 'package:mhu_dart_builder/src/protoc.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';

final modelAname = 'model_a';
final modelAdir = Directory.current;

final modelAfds =
    modelAdir.descriptorSetOut.readAsBytes().then(FileDescriptorSet.fromBuffer);

final modelArunProtoc = runProtoc(
  packageName: modelAname,
  cwd: modelAdir,
);
