import 'package:mhu_dart_builder/mhu_dart_builder.dart';
import 'package:mhu_dart_builder/src/source_gen/source_generator.dart';

extension SrcgenIterableOfStringX on Iterable<String> {
  String get joinLines => join('\n');

  String joinEnclosedOrEmpty(
    String begin,
    String end, [
    String separator = '',
  ]) =>
      isEmpty ? '' : join(separator).enclosed(begin, end);

  String joinInCurlyOrEmpty([String separator = '']) =>
      joinEnclosedOrEmpty('{', '}', separator);

  String get joinLinesInCurlyOrEmpty => joinInCurlyOrEmpty('\n');

  Iterable<String> get plusCommas => map((e) => e.plusComma);

}

extension SrcgenStringX on String {
  String plus(String str) => "$this$str";

  String enclosed(String begin, String end) => "$begin$this$end";

  String get inCurly => "{$this}";

  String get inParen => "($this)";

  String plusCurly([String content = '']) => plus(content.inCurly);

  String plusCurlyLines(Iterable<String> lines) => plusCurly(lines.joinLines);

  String plusParen([String content = '']) => plus(content.inParen);
  String plusParenLines(Iterable<String> lines) => plusParen(lines.joinLines);

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
