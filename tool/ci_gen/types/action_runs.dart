import 'package:freezed_annotation/freezed_annotation.dart';

import 'step.dart';

part 'action_runs.freezed.dart';
part 'action_runs.g.dart';

@Freezed(unionKey: 'using')
sealed class ActionsRuns with _$ActionsRuns {
  const factory composite(List<Step> steps) = ActionsCompositeRuns;
  const factory docker({required String image}) = ActionsDockerRuns;
  const factory node20({required String main}) = ActionsJsRuns;

  factory fromJson(Map<String, dynamic> json) => _$ActionsRunsFromJson(json);
}
