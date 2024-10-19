import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class InstallXcodeSigningBuilder implements StepBuilder {
  final Expression encodedProvisioningProfile;
  final Expression encodedSigningIdentity;
  final Expression signingIdentityPassphrase;

  const InstallXcodeSigningBuilder({
    required this.encodedProvisioningProfile,
    required this.encodedSigningIdentity,
    required this.signingIdentityPassphrase,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Install Signing Identity',
          uses: Tools.appleActionsImportCodesignCerts,
          withArgs: {
            'p12-file-base64': encodedSigningIdentity.toString(),
            'p12-password': signingIdentityPassphrase.toString(),
          },
        ),
        Step.run(
          name: 'Install Provisioning Profile',
          run: '''
set -eo pipefail
new_dir="\$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
old_dir="\$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "\$new_dir" "\$old_dir"
echo -n '$encodedProvisioningProfile' | base64 --decode -o "\$new_dir/app.mobileprovision"
ln -s "\$new_dir/app.mobileprovision" "\$old_dir/app.mobileprovision"
''',
        ),
      ];
}
