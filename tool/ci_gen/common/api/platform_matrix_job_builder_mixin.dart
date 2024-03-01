import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';

import '../../types/expression.dart';
import '../../types/runs_on.dart';
import 'matrix_job_builder_mixin.dart';

abstract interface class IPlatformMatrixSelector implements IMatrixSelector {
  String get platform;
  RunsOn get os;

  bool get isWeb;
}

final class PlatformMatrixProperty
    extends IMatrixProperty<IPlatformMatrixSelector> {
  const PlatformMatrixProperty();

  @override
  String get name => 'platform';

  @override
  Object? valueFor(IPlatformMatrixSelector include) => include.platform;
}

final class OsMatrixProperty extends IMatrixProperty<IPlatformMatrixSelector> {
  const OsMatrixProperty();

  @override
  String get name => 'os';

  @override
  Object? valueFor(IPlatformMatrixSelector include) => include.os.id;
}

base class PlatformMatrix extends Matrix<IPlatformMatrixSelector> {
  const PlatformMatrix(super._selectors);

  @nonVirtual
  PlatformMatrixProperty get platform => const PlatformMatrixProperty();

  @nonVirtual
  OsMatrixProperty get os => const OsMatrixProperty();

  @override
  @nonVirtual
  IMatrixProperty<IPlatformMatrixSelector> get selectorProperty => platform;

  @override
  @mustCallSuper
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties =>
      [platform, os];
}

base mixin PlatformJobBuilderMixin<TMatrix extends PlatformMatrix>
    on MatrixJobBuilderMixin<TMatrix, IPlatformMatrixSelector> {
  @visibleForOverriding
  Expression get enabledPlatforms;

  @override
  @nonVirtual
  Expression get matrixCondition =>
      EnabledPlatforms.check(enabledPlatforms, matrix.platform.expression);

  @override
  @nonVirtual
  Expression get matrixRunsOn => matrix.os.expression;
}

abstract base class EnabledPlatforms {
  EnabledPlatforms._();

  static Expression check(Expression enabledPlatforms, Expression platform) =>
      (Expression('fromJSON')([enabledPlatforms])
                  .property('length')
                  .eq(Expression.literal(0)) |
              Expression('contains')([
                Expression('fromJSON')([enabledPlatforms]),
                platform,
              ]))
          .parenthesized;
}
