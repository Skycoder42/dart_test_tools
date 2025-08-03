import 'package:freezed_annotation/freezed_annotation.dart';

import 'step.dart';

part 'action_runs.freezed.dart';
part 'action_runs.g.dart';

@Freezed(unionKey: 'using')
sealed class ActionsRuns with _$ActionsRuns {
  const factory ActionsRuns.composite(List<Step> steps) = ActionsCompositeRuns;
  const factory ActionsRuns.docker({required String image}) = ActionsDockerRuns;
  const factory ActionsRuns.node20({required String main}) = ActionsJsRuns;

  factory ActionsRuns.fromJson(Map<String, dynamic> json) =>
      _$ActionsRunsFromJson(json);
}
