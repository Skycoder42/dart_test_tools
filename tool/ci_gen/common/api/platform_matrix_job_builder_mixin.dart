import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';

import '../../types/expression.dart';
import '../../types/runs_on.dart';
import 'matrix_job_builder_mixin.dart';

abstract interface class IPlatformMatrixSelector() implements IMatrixSelector {
  String get platform;
  RunsOn get os;

  bool get isWeb;
}

final class const PlatformMatrixProperty()
    extends IMatrixProperty<IPlatformMatrixSelector> {
  @override
  String get name => 'platform';

  @override
  Object? valueFor(IPlatformMatrixSelector include) => include.platform;
}

final class const OsMatrixProperty()
    extends IMatrixProperty<IPlatformMatrixSelector> {
  @override
  String get name => 'os';

  @override
  Object? valueFor(IPlatformMatrixSelector include) => include.os.id;
}

abstract class const PlatformMatrix(super._selectors)
    extends Matrix<IPlatformMatrixSelector> {
  @nonVirtual
  PlatformMatrixProperty get platform => const PlatformMatrixProperty();

  @nonVirtual
  OsMatrixProperty get os => const OsMatrixProperty();

  @override
  @nonVirtual
  IMatrixProperty<IPlatformMatrixSelector> get selectorProperty => platform;

  @override
  @mustCallSuper
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
    platform,
    os,
  ];
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

abstract base class EnabledPlatforms._() {
  static Expression check(Expression enabledPlatforms, Expression platform) =>
      (enabledPlatforms.eq(const Expression.literal('[]')) |
              const Expression('contains')([
                const Expression('fromJSON')([enabledPlatforms]),
                platform,
              ]))
          .parenthesized;
}
