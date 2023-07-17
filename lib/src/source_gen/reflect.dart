import 'dart:mirrors';

extension ReflectSymbolX on Symbol {
  String get name => MirrorSystem.getName(this);
}

String _simpleName(Type type) => reflectType(type).simpleName.name;

extension ReflectTypeX on Type {
  String get simpleName => _simpleName(this);
}

String nm(Type type) => type.simpleName;