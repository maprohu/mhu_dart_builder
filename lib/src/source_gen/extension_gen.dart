


import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';

import 'class_gen.dart';
import 'gen.dart';
import 'generic.dart';

class ExtensionGen extends MemberGen {
  final String suffix;
  final ClassGen base;
  final Iterable<Generic> generics;
  final Iterable<MemberGen> members;
  final String? comment;

  ExtensionGen({
    this.suffix = '\$Ext',
    required this.base,
    required this.generics,
    required this.members,
    this.comment,
  });

  late final name = '${base.name}$suffix';

  String get src =>
      [
        commentLineOf(comment),
        'extension $name${generics.paramsBrackets} on ${base.nameWithArgs}'
            .andCurly([members.srcsJoin]),
      ].join();

}