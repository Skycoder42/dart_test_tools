import 'package:code_builder/code_builder.dart';

class LiteralString(void Function(LiteralStringBuilder) updates)
    extends Expression {
  late final List<Code> _code;

  this {
    final builder = LiteralStringBuilder();
    updates.call(builder);
    _code = builder.build();
  }

  @override
  R accept<R>(covariant ExpressionVisitor<R> visitor, [R? context]) {
    var currentContext = context;
    for (final code in _code) {
      currentContext = visitor.visitCodeExpression(
        CodeExpression(code),
        currentContext,
      );
    }
    return currentContext!;
  }
}

class LiteralStringBuilder() {
  final _parts = <_Part>[];

  void addString(String string) => _parts.add(_StringPart(string));

  void addParameter(Expression expression) =>
      _parts.add(_ParameterPart(expression));

  List<Code> build() => [
    const Code("'"),
    ..._parts.expand((p) => p.code),
    const Code("'"),
  ];
}

sealed class _Part() {
  Iterable<Code> get code;
}

class _StringPart(final String _string) extends _Part {
  final _dollarQuoteRegexp = RegExp(r"""(?=[$'\\])""");

  @override
  Iterable<Code> get code sync* {
    yield Code(_string.replaceAll(_dollarQuoteRegexp, r'\'));
  }
}

class _ParameterPart(final Expression _expression) extends _Part {
  @override
  Iterable<Code> get code sync* {
    yield const Code(r'${');
    yield _expression.code;
    yield const Code('}');
  }
}
