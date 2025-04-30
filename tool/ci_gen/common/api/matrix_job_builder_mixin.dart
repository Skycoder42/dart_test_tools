import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';

import '../../types/expression.dart';
import '../../types/job.dart';
import '../../types/matrix.dart' as m;
import '../../types/strategy.dart';
import 'job_builder.dart';

abstract interface class IMatrixSelector {}

abstract base class IMatrixProperty<TMatrixSelector extends IMatrixSelector> {
  const IMatrixProperty();

  String get name;

  Object? valueFor(TMatrixSelector include);

  Expression get expression => Expression('matrix.$name');
}

abstract interface class IMatrix<TMatrixSelector extends IMatrixSelector> {
  @internal
  m.Matrix build();
}

abstract base class Matrix<TMatrixSelector extends IMatrixSelector>
    implements IMatrix<TMatrixSelector> {
  final List<TMatrixSelector> _selectors;

  const Matrix(this._selectors);

  IMatrixProperty<TMatrixSelector> get selectorProperty;

  List<IMatrixProperty<TMatrixSelector>>? get includeProperties => null;

  @override
  m.Matrix build() {
    final includes = _createIncludes().toList();
    return m.Matrix(
      Map.fromEntries([_createSelector()]),
      include: includes.isEmpty ? null : includes,
    );
  }

  MapEntry<String, List<dynamic>> _createSelector() => MapEntry(
    selectorProperty.name,
    [for (final selector in _selectors) selectorProperty.valueFor(selector)],
  );

  Iterable<Map<String, dynamic>> _createIncludes() sync* {
    for (final selector in _selectors) {
      final include = {
        selectorProperty.name: selectorProperty.valueFor(selector),
        for (final property
            in includeProperties ?? <IMatrixProperty<TMatrixSelector>>[])
          if (property.valueFor(selector) case final Object value)
            property.name: value,
      };

      if (include.length > 1) {
        yield include;
      }
    }
  }
}

abstract base class ExpressionMatrix<TMatrixSelector extends IMatrixSelector>
    implements IMatrix<TMatrixSelector> {
  final Expression expression;

  ExpressionMatrix(this.expression);

  IMatrixProperty<TMatrixSelector> get selectorProperty;

  @override
  m.Matrix build() => m.Matrix({selectorProperty.name: expression.toString()});
}

base mixin MatrixJobBuilderMixin<
  TMatrix extends IMatrix<TMatrixSelector>,
  TMatrixSelector extends IMatrixSelector
>
    implements JobBuilder {
  @protected
  TMatrix get matrix;

  @protected
  Expression? get matrixCondition => null;

  @protected
  Expression get matrixRunsOn;

  @protected
  Job buildGeneric(String runsOn);

  @override
  @nonVirtual
  Job build() {
    final rawJob = buildGeneric(matrixRunsOn.toString());
    return rawJob.copyWith(
      strategy: Strategy(failFast: false, matrix: matrix.build()),
      steps: [
        for (final step in rawJob.steps)
          step.copyWith(
            ifExpression:
                matrixCondition != null
                    ? (matrixCondition! & step.ifExpression)
                    : step.ifExpression,
          ),
      ],
    );
  }
}
