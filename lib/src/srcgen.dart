import 'dart:io';

import 'package:dart_style/dart_style.dart';

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

  String get inChevron => "<$this>";

  String get inParen => "($this)";

  String plusCurly([String content = '']) => plus(content.inCurly);

  String plusCurlyLines(Iterable<String> lines) => plusCurly(lines.joinLines);

  String plusParen([String content = '']) => plus(content.inParen);
  String plusParenLines(Iterable<String> lines) => plusParen(lines.joinLines);

  String get plusDollar => plus(r'$');

  String get plusComma => plus(r',');

  String get plusSemi => plus(r';');
  String get plusDot => plus(r'.');

  String spacePlus(String? value) => sepPlus(' ', value);

  String spacePlusIf(bool when, String? value) =>
      when ? sepPlus(' ', value) : this;

  String sepPlus(String sep, String? value) =>
      value == null ? this : plus(sep).plus(value);

  String assign(String? value) => sepPlus('=', value).plusSemi;

  String get dartRawSingleQuoteStringLiteral => "r'${replaceAll("'", "''")}'";


  static final _formatter = DartFormatter();

  String formattedDartCode([File? errorOutput]) {
    try {
      return _formatter.format(this);
    } catch (_) {
      if (errorOutput != null) {
        errorOutput.parent.createSync(recursive: true);
        errorOutput.writeAsStringSync(this);
        stderr.writeln("error formatting: ${errorOutput.uri}");
      }
      rethrow;
    }
  }

  String removePrefixes(List<String> prefixes) {
    for (final prefix in prefixes) {
      if (startsWith(prefix)) {
        return substring(prefix.length);
      }
    }
    return this;
  }
}
