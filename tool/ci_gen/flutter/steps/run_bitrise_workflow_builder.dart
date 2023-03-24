import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class RunBitriseWorkflowBuilder implements StepBuilder {
  final Expression bitriseAppSlug;
  final Expression bitriseWorkflowId;
  final Expression bitrisePat;

  RunBitriseWorkflowBuilder({
    required this.bitriseAppSlug,
    required this.bitriseWorkflowId,
    required this.bitrisePat,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Run Bitrise Workflow',
          run: '''
set -eo pipefail

echo "Starting new integration test run for commit ${Expression('github.sha')}"
build_slug=\$(
  curl -sSLf \\
    -X POST \\
    -H "Authorization: $bitrisePat" \\
    -H "Content-Type: application/json" \\
    https://api.bitrise.io/v0.1/apps/$bitriseAppSlug/builds \\
    -d @- << EOF | jq -r '.build_slug'
{
  "build_params": {
    "commit_hash": "${Expression('github.sha')}",
    "workflow_id": "$bitriseWorkflowId"
  },
  "hook_info": {
    "type": "bitrise"
  }
}
EOF
)

echo "::group::Waiting for run to complete..."
build_data=
build_status=0
while (( \$build_status == 0 )); do
  sleep 10
  echo -n "Checking build status - "
  build_data=\$(
    curl -sSLf \\
      -H "Authorization: $bitrisePat" \\
      "https://api.bitrise.io/v0.1/apps/$bitriseAppSlug/builds/\$build_slug"
  )
  build_status=\$(echo "\$build_data" | jq '.data.status')
  echo "\$build_data" | jq -r '.data.status_text'
done
echo "::endgroup::"

if (( \$build_status == 1 )); then
  echo "Integration tests finished successfully"
  echo "Visit https://app.bitrise.io/build/\$build_slug for more details"
else
  echo "::error::Integration Tests not successful. Finished with status: \$(echo "\$build_data" | jq '.data.status_text')"
  echo "Visit https://app.bitrise.io/build/\$build_slug for more details"
  exit 1
fi
''',
        ),
      ];
}
