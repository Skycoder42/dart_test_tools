import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class FlutterAuthBuilder implements StepBuilder {
  final Expression ifExpression;

  FlutterAuthBuilder({
    required this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Create publishing token (flutter)',
          ifExpression: ifExpression,
          run: r'''
set -eo pipefail
PUB_TOKEN=$(curl --retry 5 --retry-connrefused -sLS "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=https://pub.dev" -H "User-Agent: actions/oidc-client" -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" | jq -r '.value')
echo "PUB_TOKEN=${PUB_TOKEN}" >> $GITHUB_ENV
export PUB_TOKEN
flutter pub token add https://pub.dev --env-var PUB_TOKEN
''',
        ),
      ];
}
