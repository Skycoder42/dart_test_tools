import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart' hide Enum;
import 'package:source_gen/source_gen.dart';

import 'references.dart';

extension ExpressionX on Expression {
  Expression get yielded =>
      CodeExpression(Block.of([const Code('yield '), code]));

  Expression get yieldedStar =>
      CodeExpression(Block.of([const Code('yield* '), code]));
}

extension ConstantReaderX on ConstantReader {
  TEnum enumValue<TEnum extends Enum>(Iterable<TEnum> values) {
    final revivedName = revive().accessor.split('.').last;
    return values.byName(revivedName);
  }

  Expression toExpression() {
    if (isNull) {
      return literalNull;
    }

    // Collection constants keep their elements wrapped as DartObjects, so they
    // have to be converted recursively instead of being passed to literal().
    if (objectValue.toListValue() case final listValue?) {
      return literalList(listValue.map(_objectToExpression));
    }

    if (objectValue.toSetValue() case final setValue?) {
      return literalSet(setValue.map(_objectToExpression));
    }

    if (objectValue.toMapValue() case final mapValue?) {
      return literalMap({
        for (final MapEntry(:key, :value) in mapValue.entries)
          _objectToExpression(key): _objectToExpression(value),
      });
    }

    // literal() has no support for symbols
    if (objectValue.toSymbolValue() case final symbolValue?) {
      return CodeExpression(Code('#$symbolValue'));
    }

    if (isLiteral) {
      return literal(literalValue);
    }

    if (objectValue.toTypeValue() case final typeValue?) {
      return typeValue.toReference();
    }

    if (objectValue.toFunctionValue() case final functionValue?) {
      return functionValue.toExpression();
    }

    return revive().toExpression();
  }
}

extension RevivableX on Revivable {
  Expression toExpression() {
    final classFragment = source.fragment;
    if (classFragment.isNotEmpty) {
      final type = TypeReference(
        (b) => b
          ..symbol = classFragment
          ..url = source.removeFragment().toString(),
      );
      if (accessor.isEmpty) {
        return type.newInstance(
          positionalArguments.map(_objectToExpression),
          namedArguments.map((k, v) => MapEntry(k, _objectToExpression(v))),
        );
      } else {
        return type.newInstanceNamed(
          accessor,
          positionalArguments.map(_objectToExpression),
          namedArguments.map((k, v) => MapEntry(k, _objectToExpression(v))),
        );
      }
    } else {
      return Reference(accessor, source.toString());
    }
  }
}

Expression _objectToExpression(DartObject? object) =>
    ConstantReader(object).toExpression();

extension ExecutableElementExpressionX on ExecutableElement {
  Expression toExpression() => switch (this) {
    ConstructorElement(isDefaultConstructor: true, :final enclosingElement) =>
      enclosingElement.toReference(),
    ConstructorElement(
      isDefaultConstructor: false,
      :final enclosingElement,
      :final name?,
    ) =>
      enclosingElement.toReference().property(name),
    MethodElement(:final enclosingElement?, :final name?) =>
      enclosingElement.toReference().property(name),
    PropertyAccessorElement(:final enclosingElement, :final name?) =>
      enclosingElement.toReference().property(name),
    ExecutableElement(:final name?) => refer(name),
    _ => throw InvalidGenerationSourceError(
      'Unsupported function type',
      element: this,
    ),
  };
}
