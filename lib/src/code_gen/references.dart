import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart' show Reference, TypeReference;
import 'package:code_builder/code_builder.dart' as cb;
import 'package:source_helper/source_helper.dart';

extension DartTypeCodeGenX on DartType {
  Reference toReference({bool ignoreTypeArguments = false, bool? nullable}) =>
      switch (this) {
        DynamicType() => CoreTypes.$dynamic,
        VoidType() => CoreTypes.$void,
        DartType(isDartCoreNull: true) => CoreTypes.$Null,
        final RecordType r => cb.RecordType(
          (b) => b
            ..isNullable = nullable ?? r.isNullableType
            ..positionalFieldTypes.addAll([
              for (final field in r.positionalFields) field.type.toReference(),
            ])
            ..namedFieldTypes.addAll({
              for (final field in r.namedFields)
                field.name: field.type.toReference(),
            }),
        ),
        final FunctionType f => cb.FunctionType(
          (b) => b
            ..isNullable = nullable ?? f.isNullableType
            ..types.addAll(f.typeImplementations.map((t) => t.toReference()))
            ..returnType = f.returnType.toReference()
            ..requiredParameters.addAll(
              f.formalParameters
                  .where((p) => p.isRequiredPositional)
                  .map((p) => p.type.toReference()),
            )
            ..optionalParameters.addAll(
              f.formalParameters
                  .where((p) => p.isOptionalPositional)
                  .map((p) => p.type.toReference()),
            )
            ..namedRequiredParameters.addAll(
              Map.fromEntries(
                f.formalParameters
                    .where((p) => p.isRequiredNamed)
                    .map((p) => MapEntry(p.name!, p.type.toReference())),
              ),
            )
            ..namedParameters.addAll(
              Map.fromEntries(
                f.formalParameters
                    .where((p) => p.isOptionalNamed)
                    .map((p) => MapEntry(p.name!, p.type.toReference())),
              ),
            ),
        ),
        DartType(:final element?) => TypeReference((b) {
          b
            ..symbol = element.name
            ..url = element.library?.uri.toString()
            ..isNullable = nullable ?? isNullableType;

          if (this case ParameterizedType(
            :final typeArguments,
          ) when !ignoreTypeArguments) {
            b.types.addAll(typeArguments.map((t) => t.toReference()));
          }
        }),
        _ => throw UnsupportedError(
          'Unable to convert type "$this" to a TypeReference',
        ),
      };
}

extension ElementCodeGenX on Element {
  TypeReference toReference({
    bool ignoreTypeArguments = false,
    bool nullable = false,
  }) => TypeReference((b) {
    b
      ..symbol = name
      ..url = library?.uri.toString()
      ..isNullable = nullable;

    if (this case TypeParameterElement(:final bound?)) {
      b.bound = bound.toReference();
    }

    if (this case TypeParameterizedElement(
      :final typeParameters,
    ) when !ignoreTypeArguments) {
      b.types.addAll(typeParameters.map((t) => t.toReference()));
    }
  });
}

extension ReferenceX on Reference {
  // ignore: avoid_positional_boolean_parameters for single parameter
  Reference asNullable(bool isNullable) => switch (type) {
    TypeReference(symbol: 'void' || 'dynamic') => this,
    final TypeReference ref => TypeReference(
      (b) => b
        ..replace(ref)
        ..isNullable = isNullable,
    ),
    final cb.RecordType rec => cb.RecordType(
      (b) => b
        ..replace(rec)
        ..isNullable = isNullable,
    ),
    final cb.FunctionType rec => cb.FunctionType(
      (b) => b
        ..replace(rec)
        ..isNullable = isNullable,
    ),
    _ => throw UnsupportedError('Cannot change nullability of $runtimeType'),
  };
}

sealed class CoreTypes {
  // core
  static final $dynamic = TypeReference(
    (b) => b
      ..symbol = 'dynamic'
      ..url = 'dart:core',
  );

  static final $void = TypeReference(
    (b) => b
      ..symbol = 'void'
      ..url = 'dart:core',
  );

  static final $Null = TypeReference(
    (b) => b
      ..symbol = 'Null'
      ..url = 'dart:core',
  );

  static final $Object = TypeReference(
    (b) => b
      ..symbol = 'Object'
      ..url = 'dart:core',
  );

  static final $bool = TypeReference(
    (b) => b
      ..symbol = 'bool'
      ..url = 'dart:core',
  );

  static final $num = TypeReference(
    (b) => b
      ..symbol = 'num'
      ..url = 'dart:core',
  );

  static final $int = TypeReference(
    (b) => b
      ..symbol = 'int'
      ..url = 'dart:core',
  );

  static final $double = TypeReference(
    (b) => b
      ..symbol = 'double'
      ..url = 'dart:core',
  );

  static final $BigInt = TypeReference(
    (b) => b
      ..symbol = 'BigInt'
      ..url = 'dart:core',
  );

  static final $String = TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core',
  );

  static final $StringBuffer = TypeReference(
    (b) => b
      ..symbol = 'StringBuffer'
      ..url = 'dart:core',
  );

  static final $Uri = TypeReference(
    (b) => b
      ..symbol = 'Uri'
      ..url = 'dart:core',
  );

  static final $UriData = TypeReference(
    (b) => b
      ..symbol = 'UriData'
      ..url = 'dart:core',
  );

  static final $DateTime = TypeReference(
    (b) => b
      ..symbol = 'DateTime'
      ..url = 'dart:core',
  );

  static final $Duration = TypeReference(
    (b) => b
      ..symbol = 'Duration'
      ..url = 'dart:core',
  );

  static final $Pattern = TypeReference(
    (b) => b
      ..symbol = 'Pattern'
      ..url = 'dart:core',
  );

  static final $Match = TypeReference(
    (b) => b
      ..symbol = 'Match'
      ..url = 'dart:core',
  );

  static final $RegExp = TypeReference(
    (b) => b
      ..symbol = 'RegExp'
      ..url = 'dart:core',
  );

  static final $RegExpMatch = TypeReference(
    (b) => b
      ..symbol = 'RegExpMatch'
      ..url = 'dart:core',
  );

  static final $StringSink = TypeReference(
    (b) => b
      ..symbol = 'StringSink'
      ..url = 'dart:core',
  );

  static final $RuneIterator = TypeReference(
    (b) => b
      ..symbol = 'RuneIterator'
      ..url = 'dart:core',
  );

  static final $Runes = TypeReference(
    (b) => b
      ..symbol = 'Runes'
      ..url = 'dart:core',
  );

  static final $Type = TypeReference(
    (b) => b
      ..symbol = 'Type'
      ..url = 'dart:core',
  );

  static final $Enum = TypeReference(
    (b) => b
      ..symbol = 'Enum'
      ..url = 'dart:core',
  );

  static final $Function = TypeReference(
    (b) => b
      ..symbol = 'Function'
      ..url = 'dart:core',
  );

  static final $Record = TypeReference(
    (b) => b
      ..symbol = 'Record'
      ..url = 'dart:core',
  );

  static final $Symbol = TypeReference(
    (b) => b
      ..symbol = 'Symbol'
      ..url = 'dart:core',
  );

  static final $Invocation = TypeReference(
    (b) => b
      ..symbol = 'Invocation'
      ..url = 'dart:core',
  );

  static final $Stopwatch = TypeReference(
    (b) => b
      ..symbol = 'Stopwatch'
      ..url = 'dart:core',
  );

  static final $Deprecated = TypeReference(
    (b) => b
      ..symbol = 'Deprecated'
      ..url = 'dart:core',
  );

  static final $Error = TypeReference(
    (b) => b
      ..symbol = 'Error'
      ..url = 'dart:core',
  );

  static final $ArgumentError = TypeReference(
    (b) => b
      ..symbol = 'ArgumentError'
      ..url = 'dart:core',
  );

  static final $AssertionError = TypeReference(
    (b) => b
      ..symbol = 'AssertionError'
      ..url = 'dart:core',
  );

  static final $ConcurrentModificationError = TypeReference(
    (b) => b
      ..symbol = 'ConcurrentModificationError'
      ..url = 'dart:core',
  );

  static final $IndexError = TypeReference(
    (b) => b
      ..symbol = 'IndexError'
      ..url = 'dart:core',
  );

  static final $NoSuchMethodError = TypeReference(
    (b) => b
      ..symbol = 'NoSuchMethodError'
      ..url = 'dart:core',
  );

  static final $OutOfMemoryError = TypeReference(
    (b) => b
      ..symbol = 'OutOfMemoryError'
      ..url = 'dart:core',
  );

  static final $RangeError = TypeReference(
    (b) => b
      ..symbol = 'RangeError'
      ..url = 'dart:core',
  );

  static final $StackOverflowError = TypeReference(
    (b) => b
      ..symbol = 'StackOverflowError'
      ..url = 'dart:core',
  );

  static final $StateError = TypeReference(
    (b) => b
      ..symbol = 'StateError'
      ..url = 'dart:core',
  );

  static final $TypeError = TypeReference(
    (b) => b
      ..symbol = 'TypeError'
      ..url = 'dart:core',
  );

  static final $UnimplementedError = TypeReference(
    (b) => b
      ..symbol = 'UnimplementedError'
      ..url = 'dart:core',
  );

  static final $UnsupportedError = TypeReference(
    (b) => b
      ..symbol = 'UnsupportedError'
      ..url = 'dart:core',
  );

  static final $Exception = TypeReference(
    (b) => b
      ..symbol = 'Exception'
      ..url = 'dart:core',
  );

  static final $FormatException = TypeReference(
    (b) => b
      ..symbol = 'FormatException'
      ..url = 'dart:core',
  );

  static final $StackTrace = TypeReference(
    (b) => b
      ..symbol = 'StackTrace'
      ..url = 'dart:core',
  );

  static TypeReference $Comparable([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Comparable'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Comparator([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Comparator'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Iterable([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Iterable'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Iterator([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Iterator'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $List([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'List'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Set([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Set'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Map({Reference? keyType, Reference? valueType}) =>
      TypeReference((b) {
        b
          ..symbol = 'Map'
          ..url = 'dart:core'
          ..types.addAll(_validateTypes(keyType, valueType));
      });

  static TypeReference $MapEntry({Reference? keyType, Reference? valueType}) =>
      TypeReference((b) {
        b
          ..symbol = 'MapEntry'
          ..url = 'dart:core'
          ..types.addAll(_validateTypes(keyType, valueType));
      });

  static TypeReference $Sink([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Sink'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $WeakReference([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'WeakReference'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Expando([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Expando'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Finalizer([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Finalizer'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Future([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Future'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $Stream([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'Stream'
      ..url = 'dart:core'
      ..types.addAll([?type]);
  });

  static TypeReference $ParallelWaitError({
    Reference? keyType,
    Reference? valueType,
  }) => TypeReference((b) {
    b
      ..symbol = 'ParallelWaitError'
      ..url = 'dart:core'
      ..types.addAll(_validateTypes(keyType, valueType));
  });

  // helpers
  static Iterable<Reference> _validateTypes(
    Reference? type1,
    Reference? type2,
  ) sync* {
    var hasType = false;
    for (final type in [type1, type2]) {
      if (hasType && type == null) {
        throw ArgumentError('Either none or all type parameters must be set');
      }

      if (type == null) {
        continue;
      }

      hasType = true;
      yield type;
    }
  }
}

sealed class CoreConstants {
  static const override = Reference('override', 'dart:core');
  static const deprecated = Reference('deprecated', 'dart:core');
}

sealed class CoreFunctions {
  static const pragma = Reference('pragma', 'dart:core');
  static const identical = Reference('identical', 'dart:core');
  static const identityHashCode = Reference('identityHashCode', 'dart:core');
  static const print = Reference('print', 'dart:core');
}
