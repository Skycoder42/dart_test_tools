import 'package:freezed_annotation/freezed_annotation.dart';

import 'analysis_options_ref.dart';

part 'linter_config.freezed.dart';

@freezed
class LinterConfig with _$LinterConfig {
  const factory LinterConfig({
    required AnalysisOptionsRef baseRules,
    @Default(<AnalysisOptionsRef>[]) List<AnalysisOptionsRef> mergeRules,
    AnalysisOptionsRef? customRules,
  }) = _LinterConfig;
}
