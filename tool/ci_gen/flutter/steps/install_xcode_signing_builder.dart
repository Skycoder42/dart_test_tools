import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/secrets.dart';
import '../../common/tools.dart';
import '../../types/step.dart';

base mixin InstallXcodeSigningConfig on JobConfig {
  late final encodedProvisioningProfile = secretContext(
    WorkflowSecrets.provisioningProfile,
  );
  late final encodedSigningIdentity = secretContext(
    WorkflowSecrets.signingIdentity,
  );
  late final signingIdentityPassphrase = secretContext(
    WorkflowSecrets.signingIdentityPassphrase,
  );
}

class InstallXcodeSigningBuilder implements StepBuilder {
  final InstallXcodeSigningConfig config;

  const InstallXcodeSigningBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    Step.uses(
      name: 'Install Signing Identity',
      uses: Tools.appleActionsImportCodesignCerts,
      withArgs: {
        'p12-file-base64': config.encodedSigningIdentity.toString(),
        'p12-password': config.signingIdentityPassphrase.toString(),
      },
    ),
    Step.run(
      name: 'Install Provisioning Profile',
      run: '''
set -eo pipefail
new_dir="\$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
old_dir="\$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "\$new_dir" "\$old_dir"
echo -n '${config.encodedProvisioningProfile}' | base64 --decode > "\$new_dir/app.mobileprovision"
ln -s "\$new_dir/app.mobileprovision" "\$old_dir/app.mobileprovision"
''',
    ),
  ];
}
