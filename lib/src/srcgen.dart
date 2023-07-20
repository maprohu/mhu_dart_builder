import 'package:mhu_dart_builder/mhu_dart_builder.dart';

extension SrcgenIterableOfStringX on Iterable<String> {
  String get joinLines => join('\n');
}

extension SrcgenStringX on String {
  String plus(String str) => "$this$str";

  String get inCurly => "{$this}";

  String get inParen => "($this)";

  String plusCurly([String content = '']) => plus(content.inCurly);

  String plusParen([String content = '']) => plus(content.inParen);

  String get plusDollar => plus(r'$');
  String get plusComma => plus(r',');

  String get plusSemi => plus(r';');

  String spacePlus(String? value) => sepPlus(' ', value);

  String spacePlusIf(bool when, String? value) =>
      when ? sepPlus(' ', value) : this;

  String sepPlus(String sep, String? value) =>
      value == null ? this : plus(sep).plus(value);

  String assign(String? value) => sepPlus('=', value).plusSemi;

  String get dartRawSingleQuoteStringLiteral => "r'${replaceAll("'", "''")}'";
}
