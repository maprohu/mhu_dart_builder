import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mhu_dart_commons/commons.dart';
import 'package:source_gen/source_gen.dart';

import 'source_generator.dart';
import 'class_gen.dart';
import 'fn.dart';
import 'prop.dart';
import 'typ.dart';

extension DartObjectX on DartObject {
  InterfaceType? get asInterfaceType => type?.asInterfaceType;

  DartType get firstTypeArgumentIncludingDynamic =>
      asInterfaceType!.typeArguments.first;

  DartType? get firstTypeArgument => asInterfaceType?.firstTypeArgument;
}

extension ConstantReaderX on ConstantReader {
  DartType get asDartType => objectValue.type!;

  InterfaceType get asInterfaceType => asDartType.asInterfaceType;

  DartType get firstTypeArgumentIncludingDynamic =>
      asInterfaceType.firstTypeArgumentIncludingDynamic;

  DartType? get firstTypeArgument => asInterfaceType.firstTypeArgument;

}

extension InterafaceTypeX on InterfaceType {
  DartType get firstTypeArgumentIncludingDynamic => typeArguments.first;

  DartType? get firstTypeArgument =>
      firstTypeArgumentIncludingDynamic.takeIf((a) => !a.isDynamic);
}

extension InterfaceElementX on InterfaceElement {
  Iterable<InterfaceType> get directImplementedInterfaces => [
        ...supertype?.let((e) => [e]) ?? [],
        ...interfaces,
        ...mixins,
      ];
}

extension FunctionTypedElementX on FunctionTypedElement {
  // bool canBeOverridenBy(FunctionTypedElement other) => library.typeSystem.isAssignableTo(leftType, rightType)
}

extension DartTypeX on DartType {
  InterfaceType get asInterfaceType => this as InterfaceType;

  DartType get firstTypeArgumentIncludingDynamic =>
      asInterfaceType.typeArguments.first;

  bool get isNullable => nullabilitySuffix != NullabilitySuffix.none;

  String get displayWithoutNullability => alias?.let((a) => a.displayString) ?? () {
        final full = getDisplayString(withNullability: true);
        if (isNullable) {
          return full.substring(0, full.length - 1);
        } else {
          return full;
        }
      }();

  String get displayWithNullability =>
      alias?.let((a) => a.displayString) ??
      getDisplayString(withNullability: true);

  ClassGen toClassGen() => ClassGen.fromElement(element!);
}

extension InstantiatedTypeAliasElementX on InstantiatedTypeAliasElement {
  String get displayString => element.displayName.followedBy(
        typeArguments
            .map(
              (e) => e.displayWithNullability,
            )
            .commasGenerics,
      );
}

class Search<T> {
  final Set<String> concrete = {};
  final Map<String, T> found = {};
}

class SearchAbstract {
  final ifaces = <InterfaceType>[];
  final methods = Search<MethodElement>();
  final getters = Search<PropertyAccessorElement>();
  final setters = Search<PropertyAccessorElement>();

  SearchAbstract.fromElement(InterfaceElement element) {
    walk(
      element.methods,
      element.accessors,
      element.mixins,
      element.supertype,
      element.interfaces,
      false,
    );
  }

  SearchAbstract.iface(InterfaceType element) {
    walkIface(element, true);
  }

  void walkIface(InterfaceType mixin, bool abst) {
    ifaces.add(mixin);
    walk(
      mixin.methods,
      mixin.accessors,
      mixin.mixins,
      mixin.superclass,
      mixin.interfaces,
      abst,
    );
  }

  void walk(
    List<MethodElement> thisMethods,
    List<PropertyAccessorElement> thisProps,
    List<InterfaceType> mixins,
    InterfaceType? supertype,
    List<InterfaceType> interfaces,
    bool abstract,
  ) {
    void process<T extends ExecutableElement>(
        Search<T> search, Iterable<T> items) {
      for (final item in items) {
        if (item.isStatic || search.concrete.contains(item.name)) {
          continue;
        }

        final abs = abstract || item.isAbstract;

        if (!abs) {
          search.concrete.add(item.name);
        } else if (!search.found.containsKey(item.name)) {
          search.found[item.name] = item;
        }
      }
    }

    // this class
    process(
      methods,
      thisMethods,
    );
    process(
      getters,
      thisProps.where((element) => element.isGetter),
    );
    process(
      setters,
      thisProps.where((element) => element.isSetter),
    );

    void iface(InterfaceType mixin, bool abst) {
      walkIface(mixin, abstract || abst);
    }

    // mixins
    mixins.reversed.forEach((mixin) {
      iface(mixin, false);
    });

    // superclass
    supertype?.let((s) => iface(s, false));

    // interfaces
    // TODO this should be breadth-first, otherwise it may find
    // a less specific definition first
    interfaces.reversed.forEach((element) {
      iface(element, true);
    });
  }

  late final ms = methods.found.values;
  late final gs = getters.found.values;
  late final ss = setters.found.values;

  late final getterProps = gs.map((m) {
    return Prop(
      name: m.displayName,
      type: Typ.fromType(m.returnType),
    );
  });

  late final setterProps = ss.map((m) => Prop(
        name: m.displayName,
        type: Typ.fromType(m.parameters[0].type),
      ));

  late final methodFns = ms.map(Fn.fromMethod);

  late final methodNames = {...methodFns.map((e) => e.name)};
  late final getterNames = {...getterProps.map((e) => e.name)};
  late final setterNames = {...setterProps.map((e) => e.name)};
}
