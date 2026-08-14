import 'package:freezed_annotation/freezed_annotation.dart';

import 'matrix.dart';

part 'strategy.freezed.dart';
part 'strategy.g.dart';

@freezed
sealed class Strategy with _$Strategy {
  const factory({
    @JsonKey(name: 'fail-fast', includeIfNull: false) bool? failFast,
    @JsonKey(name: 'max-parallel', includeIfNull: false) int? maxParallel,
    required Matrix matrix,
  }) = _Strategy;

  factory fromJson(Map<String, dynamic> json) => _$StrategyFromJson(json);
}
