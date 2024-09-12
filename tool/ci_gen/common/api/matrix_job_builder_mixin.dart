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

abstract base class Matrix<TMatrixSelector extends IMatrixSelector> {
  final List<TMatrixSelector> _selectors;

  const Matrix(this._selectors);

  IMatrixProperty<TMatrixSelector> get selectorProperty;

  List<IMatrixProperty<TMatrixSelector>> get includeProperties;

  MapEntry<String, List<dynamic>> _createSelector() =>
      MapEntry(selectorProperty.name, [
        for (final selector in _selectors) selectorProperty.valueFor(selector),
      ]);

  Iterable<Map<String, dynamic>> _createIncludes() sync* {
    for (final selector in _selectors) {
      final include = {
        selectorProperty.name: selectorProperty.valueFor(selector),
        for (final property in includeProperties)
          if (property.valueFor(selector) case final Object value)
            property.name: value,
      };

      if (include.length > 1) {
        yield include;
      }
    }
  }
}

base mixin MatrixJobBuilderMixin<TMatrix extends Matrix<TMatrixSelector>,
    TMatrixSelector extends IMatrixSelector> implements JobBuilder {
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
      strategy: Strategy(
        failFast: false,
        matrix: m.Matrix(
          Map.fromEntries([
            matrix._createSelector(),
          ]),
          include: matrix._createIncludes().toList(),
        ),
      ),
      steps: [
        for (final step in rawJob.steps)
          step.copyWith(
            ifExpression: matrixCondition != null
                ? (matrixCondition! & step.ifExpression)
                : step.ifExpression,
          ),
      ],
    );
  }
}
