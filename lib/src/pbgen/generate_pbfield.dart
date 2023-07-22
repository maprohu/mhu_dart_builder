import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mhu_dart_builder/src/protoc.dart';
import 'package:mhu_dart_builder/src/srcgen.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_commons/io.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';
import 'package:protobuf/protobuf.dart';
import 'package:recase/recase.dart';

import '../resources.dart';
import '../reflect.dart';

Future<void> runPbFieldGenerator({
  String? packageName,
  required PbiLib lib,
}) async {
  packageName ??= await packageNameFromPubspec();

  final cwd = Directory.current;

  final metaFile = cwd.pbfieldFile(packageName);

  final content = generatePbFieldDart(
    package: packageName,
    lib: lib,
  );

  await metaFile.parent.create(recursive: true);
  await metaFile.writeAsString(
    content.formattedDartCode(
      cwd.fileTo(
        ['.dart_tool', 'mhu', metaFile.filename],
      ),
    ),
  );
  stdout.writeln(
    "wrote: ${metaFile.uri}",
  );
}

extension _PbiMessageX<M extends GeneratedMessage> on PbiMessage<M> {
  String get className => instance.runtimeType.toString();

  List<FieldInfo> get fields => builderInfo.byIndex;

  Iterable<FieldAccess> get fieldAccesses => fields.map((e) => e.access());
}

const _mdc = r"$mdc";
const _mdp = r"$mdp";

String _field(PbiMessage msg, FieldInfo fld) =>
    '${msg.className}\$.${fld.name}';

String generatePbFieldDart({
  required String package,
  required PbiLib lib,
}) {
  String fldgen(PbiMessage msg, FieldInfo fieldInfo) {
    final access = fieldInfo.accessForMessage(msg);
    final msgCls = msg.className;

    final fieldInfoRef =
        "$msgCls.getDefault().info_.byIndex[${fieldInfo.index}].cast()";

    final accessClassName = access.runtimeType;

    return "$_mdp.$accessClassName($fieldInfoRef,)";
  }

  String oogen(PbiMessage msg, int oneofIndex, String name) {
    final msgCls = msg.className;
    return [
      "$_mdp.OneofFieldAccess(",
      "oneofIndex: $oneofIndex,",
      "builderInfo: $msgCls.getDefault().info_,",
      "options: ${msgCls}_${name.pascalCase}.values,"
          ")",
    ].joinLines;
  }

  return [
    "// ignore_for_file: annotate_overrides",
    "// ignore_for_file: camel_case_types",
    "// ignore_for_file: unnecessary_this",
    "// ignore_for_file: camel_case_extensions",
    "import 'package:mhu_dart_proto/mhu_dart_proto.dart' as $_mdp;",
    "import 'package:mhu_dart_commons/commons.dart' as $_mdc;",
    for (final dep in lib.importedLibraries)
      "import '${protoImportUri(dep.name)}';",
    "import '$package.pb.dart';",
    // Message static classes
    for (final msg in lib.messages) ...[
      'class ${msg.className}\$ {', // Start of static class
      // Field accessors
      for (final fld in msg.fields) ...[
        'static final ${fld.name} = ${fldgen(msg, fld)};'
      ],
      // OneOfs
      ...msg.oneofs.mapIndexed(
        (index, oo) =>
            'static final ${oo.name.camelCase} = ${oogen(msg, index, oo.name)};',
      ),
      // create method
      'static ${msg.className} create(',
      [
        for (final fld in msg.fieldAccesses)
          <String>[
            switch (fld) {
              RepeatedFieldAccess(:final singleValueType) =>
                'Iterable<$singleValueType>',
              _ => fld.valueType.toString()
            },
            '? ${fld.fieldInfo.name},',
          ].join(),
      ].joinLinesInCurlyOrEmpty,
      ') {',
      'final \$o = ${msg.className}();',
      for (final fld in msg.fieldAccesses) ...[
        'if (${fld.name} != null) {',
        switch (fld) {
          ScalarFieldAccess() => '\$o.${fld.name} = ${fld.name};',
          _ => '\$o.${fld.name}.addAll(${fld.name});'
        },
        '}',
      ],
      'return \$o;',
      '}', // End of create method
      '}', // End of static class
    ],
    for (final msg in lib.messages) ...[
      'extension ${msg.className}\$Ext on ${msg.className} {',
      for (final fld in msg.fields) ...[
        if (fld.access() case ScalarFieldAccess(:final valueType)) ...[
          '$valueType? get ${fld.name}Opt',
          ' => ',
          '${msg.className}\$.${fld.name}.getOpt(this);',
        ]
      ],
      '}',
      ..._frpMsg(msg),
      ..._oneofs(msg),
    ],
  ].joinLines;
}

enum _Access {
  FR,
  FW,
}

enum _Cardinality {
  MAP,
  LIST,
}

Iterable<String> _frpMsg(PbiMessage msg) {
  final frCls = '${msg.className}\$Fr';
  final fwCls = '${msg.className}\$Fw';

  String wrap(
    _Access access,
    FieldInfo fld,
    Type singleValueType,
  ) {
    return fld.access().isMessageValue
        ? "$singleValueType\$${access.name.pascalCase}.new"
        : "$_mdp.bare${access.name.pascalCase}<$singleValueType>";
  }

  String multi(
    _Access access,
    _Cardinality cardinality,
    FieldInfo fld,
    Type singleValueType,
  ) {
    return 'this.${cardinality.name.toLowerCase()}\$'.plusParenLines([
      _field(msg, fld).plusComma,
      wrap(access, fld, singleValueType).plusComma,
    ]);
  }

  return [
    'extension ${msg.className}\$ExtFw on $_mdc.Fw<${msg.className}>'
        .plusCurlyLines([
      for (final fld in msg.fields) ...[
        if (fld.access() case ScalarFieldAccess(:final valueType))
          'set ${fld.name}'.plusParenLines([
            '$valueType value',
          ]).plusCurlyLines([
            '${_field(msg, fld)}.setFw(this, value);',
          ]),
      ],
    ]),
    'class $frCls extends $_mdp.${nm(PbFr)}<${msg.className}>'.plusCurlyLines([
      'final $_mdc.${nm(Fr)}<${msg.className}> fv\$;'
          '$frCls(this.fv\$, {super.disposers,});',
      for (final fld in msg.fields) ...[
        'late final ${fld.name} =',
        switch (fld.access()) {
          ScalarFieldAccess(:final singleValueType) => 'fr\$'.plusParenLines([
              _field(msg, fld).plusComma,
              wrap(_Access.FR, fld, singleValueType).plusComma,
            ]),
          RepeatedFieldAccess(:final singleValueType) => multi(
              _Access.FR,
              _Cardinality.LIST,
              fld,
              singleValueType,
            ),
          MapFieldAccess(:final singleValueType) => multi(
              _Access.FR,
              _Cardinality.MAP,
              fld,
              singleValueType,
            ),
        },
        ';',
      ],
    ]),
    'class $fwCls extends $_mdp.${nm(PbFw)}<${msg.className}>'.plusCurlyLines([
      'final $_mdc.${nm(Fw)}<${msg.className}> fv\$;'
          '$fwCls(this.fv\$, {super.disposers,});',
      for (final fld in msg.fields) ...[
        'late final ${fld.name} =',
        switch (fld.access()) {
          ScalarFieldAccess(:final singleValueType) => 'fw\$'.plusParenLines([
              _field(msg, fld).plusComma,
              wrap(_Access.FW, fld, singleValueType).plusComma,
            ]),
          RepeatedFieldAccess(:final singleValueType) => multi(
              _Access.FW,
              _Cardinality.LIST,
              fld,
              singleValueType,
            ),
          MapFieldAccess(:final singleValueType) => multi(
              _Access.FW,
              _Cardinality.MAP,
              fld,
              singleValueType,
            ),
        },
        ';',
      ],
    ]),
  ];
}

Iterable<String> _oneofs(PbiMessage msg) {
  Iterable<String> oneof({
    required String oneofName,
    required int oneofIndex,
  }) {
    final enumClsName = '${msg.className}_${oneofName.pascalCase}';
    final baseClassName = enumClsName.plusDollar;
    final notSetCls = baseClassName.plus('notSet\$');

    String optClsFor(FieldInfo field) => baseClassName.plus(field.name);
    Iterable<String> option(FieldInfo field) {
      final optCls = optClsFor(field);
      final valueType = field.access().valueType;
      return [
        'class $optCls ',
        'extends $baseClassName ',
        'with $_mdc.${nm(HolderMixin)}<$valueType>'.plusCurlyLines([
          'final $valueType value;',
          'const $optCls(this.value);',
          if (field.name != 'value') '$valueType get ${field.name} => value;',
          'int get tagNumber\$ => ${field.tagNumber};'
        ]),
      ];
    }

    final fields = listOneofFields(
      builderInfo: msg.builderInfo,
      oneofIndex: oneofIndex,
    );
    return [
      'sealed class $baseClassName implements $_mdp.${nm(PbWhich)}'
          .plusCurlyLines([
        'const $baseClassName();',
      ]),
      'class $notSetCls extends $baseClassName'.plusCurlyLines([
        'const $notSetCls._();',
        'static const instance = $notSetCls._();',
        'int get tagNumber\$ => 0;'
      ]),
      for (final field in fields) ...option(field),
      'extension \$$baseClassName\$Ext on ${msg.className}'.plusCurlyLines([
        '$baseClassName get ${oneofName.camelCase} => switch'.plusParenLines([
          'which${oneofName.pascalCase}()',
        ]).plusCurlyLines([
          for (final field in fields)
            '$enumClsName.${field.name} => ${optClsFor(field)}(${field.name}),',
          '$enumClsName.notSet => $notSetCls.instance,',
        ]).plusSemi,
      ]),
    ];
  }

  return [
    ...msg.oneofs.expandIndexed(
      (index, element) => oneof(
        oneofName: element.name,
        oneofIndex: index,
      ),
    ),
  ];
}
