import 'package:mhu_dart_commons/commons.dart';
import 'package:mhu_dart_proto/mhu_dart_proto.dart';

import '../proto_meta/proto_meta_generator.dart';
import '../source_gen/source_generator.dart';
import '../source_gen/class/constr.dart';
import '../source_gen/class/field.dart';
import '../source_gen/class/setter.dart';
import '../source_gen/class_gen.dart';
import '../source_gen/gen.dart';
import '../source_gen/param.dart';
import '../source_gen/prop.dart';
import 'proto_message.dart';

final hasFrCls = ClassGen.fromTypeDynamic(HasFr).fromCommons;
final frCls = ClassGen.fromTypeDynamic(Fr).fromCommons;
final hasFwCls = ClassGen.fromTypeDynamic(HasFw).fromCommons;
final fwCls = ClassGen.fromTypeDynamic(Fw).fromCommons;
final disposersCls = ClassGen.fromTypeDynamic(DspReg).fromCommons;

class ProtoFrp extends TopGen {
  final PmgMsg msg;

  late final frClass = frCls.withGeneric1(msg.messageClassGen);
  late final fwClass = fwCls.withGeneric1(msg.messageClassGen);

  late final fwExtension = fwClass.extensionGen(
    msg.singleFields
        .map(
          (field) => SetterGen(
            prop: Prop(
              name: field.name.andDollar,
              type: field.typ,
            ),
            body: (valueVar) =>
                '=> rebuild((msg_) => msg_.${field.name} = $valueVar);',
          ),
        )
        .srcsJoin,
    generics: [],
    suffix: '\$Ext'.andDollar.followedBy(msg.messageClassName),
  );

  late final frProp = Prop(
    name: 'fv',
    type: frClass.typ,
  );

  late final fwProp = Prop(
    name: 'fv',
    type: fwClass.typ,
  );

  late final disposersProp = Prop(
    name: '_disposers',
    type: disposersCls.typ.withNullable(true),
  );

  late final ClassGen frClassGen = ClassGen(
    name: msg.messageName.andDollar.followedBy('Fr'),
    mixins: (self) => [
      hasFrCls.withGeneric1(msg.messageClassGen),
    ],
    content: (self) => [
      FieldGen(frProp),
      FieldGen(disposersProp),
      Constr(
        owner: self,
        params: [
          Param(
            prop: frProp,
            naming: ParamNaming.unnamed,
            requirement: ParamRequirement.required,
            target: ParamTarget.thisTarget,
          ),
          Param(
            prop: disposersProp.withEscapedName(),
            naming: ParamNaming.named,
            requirement: ParamRequirement.optional,
            target: ParamTarget.noTarget,
          ),
        ],
        body: (_) => ':'
            .followedBy(disposersProp.name)
            .followedBy('=')
            .followedBy(disposersProp.escapedName)
            .andSemi,
      ),
      ...msg.singleFields.map(
        (field) {
          final frSrc =
              '$commonsPrefix.fr(() => ${frProp.name}().${field.name}, disposers: _disposers,)';
          late final plain = FieldGen(
            Prop(
              name: field.name.andDollar,
              type: frCls.copyWith(
                generics: [field.typeGeneric],
              ).typ,
            ),
            late: true,
            defaultSrc: frSrc,
          );
          return switch (field.fld.cardinality) {
            PdfSingle() => switch (field.fld.singleValueType) {
                PdfMessageType(:final pdMsg) => run(() {
                    final frClassGen = pdMsg.payload.frp.frClassGen;
                    return FieldGen(
                      Prop(
                        name: field.name.andDollar,
                        type: frClassGen.typ,
                      ),
                      late: true,
                      defaultSrc: frClassGen.defaultConstructor.invokeSrc([
                        frSrc,
                        'disposers: _disposers',
                      ].plusCommas),
                    );
                  }),
                _ => plain,
              },
            _ => plain,
          };
        },
      ),
      ...msg.collectionFields.map((field) {
        final nameAndDollar = field.name.andDollar;

        final frSrc =
            '$commonsPrefix.fr(() => ${frProp.name}().${field.name}, disposers: _disposers,)';

        final factoryMethodName = switch (field.fld.cardinality) {
          PdfRepeated() => 'list',
          PdfMapOf() => 'map',
          final other => throw other,
        };

        final wrapperSrc = switch (field.fld.singleValueType) {
          PdfMessageType(:final pdMsg) =>
            pdMsg.payload.frp.frClassGen.name.andDot.followedBy('new'),
          _ => '(item) => item',
        };

        final cachedSrc = [
          '$commonsPrefix.CachedFr.$factoryMethodName(',
          '  fv: $frSrc,',
          '  wrap: $wrapperSrc,',
          '  defaultValue: ${field.staticRef}.create(),',
          ')',
        ].join();

        return 'late final $nameAndDollar = $cachedSrc;'.asGen;
      }),
      ...msg.oneOfs.map(
        (field) => FieldGen(
          Prop(
            name: field.whichMethodName.andDollar,
            type: frCls.copyWith(
              generics: [field.enumClassGen.asGenericArg],
            ).typ,
          ),
          late: true,
          defaultSrc:
              '$commonsPrefix.fr(() => ${frProp.name}().${field.whichMethodName}(), disposers: _disposers,)',
        ),
      ),
    ],
    constructorsFn: (self) => [],
  );

  late final frFieldProp = Prop(
    name: '_fr',
    type: frClassGen.typ,
  );

  late final ClassGen fwClassGen = ClassGen(
    name: msg.messageName.andDollar.followedBy('Fw'),
    mixins: (self) => [
      hasFwCls.withGeneric1(msg.messageClassGen),
    ],
    content: (self) => [
      FieldGen(fwProp),
      FieldGen(disposersProp),
      Constr(
        owner: self,
        params: [
          Param(
            prop: fwProp,
            naming: ParamNaming.unnamed,
            requirement: ParamRequirement.required,
            target: ParamTarget.thisTarget,
          ),
          Param(
            prop: disposersProp.withEscapedName(),
            naming: ParamNaming.named,
            requirement: ParamRequirement.optional,
            target: ParamTarget.noTarget,
          ),
        ],
        body: (_) => ':'
            .followedBy(disposersProp.name)
            .followedBy('=')
            .followedBy(disposersProp.escapedName)
            .andSemi,
      ),
      // ...ClassGen.fieldsWithConstr(
      //   self: self,
      //   props: [fwProp],
      //   cnst: false,
      // ),
      FieldGen(
        frFieldProp,
        late: true,
        defaultSrc: frClassGen.defaultConstructor.invokeSrc(
          [
            fwProp.name,
            'disposers: _disposers',
          ].plusCommas,
        ),
      ),
      ...msg.singleFields.map(
        (field) {
          final nameDollar = field.name.andDollar;
          final fwSrc = [
            '$commonsPrefix.frw(',
            '  ${frFieldProp.name}.$nameDollar,',
            '  (v_) => ${fwProp.name}.$nameDollar = v_,',
            ')',
          ].join();
          final plain = FieldGen(
            Prop(
              name: nameDollar,
              type: fwCls.copyWith(
                generics: [field.typeGeneric],
              ).typ,
            ),
            late: true,
            defaultSrc: fwSrc,
          );

          return switch (field.fld.cardinality) {
            PdfSingle() => switch (field.fld.singleValueType) {
                PdfMessageType(:final pdMsg) => run(() {
                    final fwClassGen = pdMsg.payload.frp.fwClassGen;
                    return FieldGen(
                      Prop(
                        name: field.name.andDollar,
                        type: fwClassGen.typ,
                      ),
                      late: true,
                      defaultSrc: fwClassGen.defaultConstructor.invokeSrc(
                        [
                          fwSrc,
                          'disposers: _disposers',
                        ].plusCommas,
                      ),
                    );
                  }),
                _ => plain,
              },
            _ => plain,
          };
        },
      ),
      ...msg.collectionFields.map((e) {
        final nameAndDollar = e.name.andDollar;

        final fwSrc = [
          '$commonsPrefix.fru(',
          '  ${fwProp.name},',
          '  ${e.staticRef}.get,',
          '  disposers: _disposers,',
          ')',
        ].join();

        final factoryMethodName = switch (e.fld.cardinality) {
          PdfRepeated() => 'list',
          PdfMapOf() => 'map',
          final other => throw other,
        };

        final wrapperSrc = switch (e.fld.singleValueType) {
          PdfMessageType(:final pdMsg) =>
            pdMsg.payload.frp.fwClassGen.name.andDot.followedBy('new'),
          _ => '(item) => item',
        };

        final cachedSrc = [
          '$commonsPrefix.CachedFu.$factoryMethodName(',
          '  fv: $fwSrc,',
          '  wrap: $wrapperSrc,',
          '  defaultValue: ${e.staticRef}.create(),',
          ')',
        ].join();

        return 'late final $nameAndDollar = $cachedSrc;'.asGen;
      }),
    ],
    constructorsFn: (self) => [],
  );

  @override
  late final src = [
    fwExtension,
    frClassGen,
    fwClassGen,
  ].srcsJoin;

  ProtoFrp(this.msg);
}
/*
late final invoices$ = CachedFu.list(
  fv: fru(fv, IvoBatchMsg$.invoices.get),
  wrap: IvoInvoiceMsg$Fw.new,
  defaultValue: IvoInvoiceMsg.getDefault(),
);

 */
