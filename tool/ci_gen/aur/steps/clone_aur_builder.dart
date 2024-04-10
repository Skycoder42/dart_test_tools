import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class CloneAurBuilder implements StepBuilder {
  static const aurHostKeys = {
    'ssh-ed25519':
        'AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN',
    'ecdsa-sha2-nistp256':
        'AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLMiLrP8pVi5BFX2i3vepSUnpedeiewE5XptnUnau+ZoeUOPkpoCgZZuYfpaIQfhhJJI5qgnjJmr4hyJbe/zxow=',
    'ssh-rsa':
        'AAAAB3NzaC1yc2EAAAADAQABAAABgQDKF9vAFWdgm9Bi8uc+tYRBmXASBb5cB5iZsB7LOWWFeBrLp3r14w0/9S2vozjgqY5sJLDPONWoTTaVTbhe3vwO8CBKZTEt1AcWxuXNlRnk9FliR1/eNB9uz/7y1R0+c1Md+P98AJJSJWKN12nqIDIhjl2S1vOUvm7FNY43fU2knIhEbHybhwWeg+0wxpKwcAd/JeL5i92Uv03MYftOToUijd1pqyVFdJvQFhqD4v3M157jxS5FTOBrccAEjT+zYmFyD8WvKUa9vUclRddNllmBJdy4NyLB8SvVZULUPrP3QOlmzemeKracTlVOUG1wsDbxknF1BwSCU7CmU6UFP90kpWIyz66bP0bl67QAvlIc52Yix7pKJPbw85+zykvnfl2mdROsaT8p8R9nwCdFsBc9IiD0NhPEHcyHRwB8fokXTajk2QnGhL+zP5KnkmXnyQYOCUYo3EKMXIlVOVbPDgRYYT/XqvBuzq5S9rrU70KoI/S5lDnFfx/+lPLdtcnnEPk=',
  };

  final Expression aurSshPrivateKey;

  const CloneAurBuilder({
    required this.aurSshPrivateKey,
  });

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Setup git author',
          run: r'''
set -eo pipefail
git config --global user.name "$GITHUB_ACTOR"
git config --global user.email "$GITHUB_ACTOR@users.noreply.github.com"
''',
        ),
        const Step.run(
          name: 'Ensure SSH configuration directory exists',
          run: 'mkdir -p /etc/ssh',
        ),
        Step.run(
          name: 'Setup known host keys',
          run: ['set -eo pipefail']
              .followedBy(
                aurHostKeys.entries.map(
                  (entry) =>
                      "echo 'aur.archlinux.org ${entry.key} ${entry.value}' "
                      '>> /etc/ssh/ssh_known_hosts',
                ),
              )
              .join('\n'),
        ),
        Step.run(
          name: 'Import SSH private key',
          run: '''
set -eo pipefail

echo "$aurSshPrivateKey" >> "${Runner.temp}/ssh-key"
chmod 600 "${Runner.temp}/ssh-key"

echo "Host aur.archlinux.org" > /etc/ssh/ssh_config
echo "  IdentityFile ${Runner.temp}/ssh-key" >> /etc/ssh/ssh_config
echo "  User aur" >> /etc/ssh/ssh_config
''',
        ),
        const Step.run(
          name: 'Clone AUR repository',
          run: 'git clone '
              r'"ssh://aur@aur.archlinux.org/$(yq ".name" src/pubspec.yaml).git" '
              './aur',
        ),
        const Step.run(
          name: 'Cleanup AUR repository',
          run: r'find . -type f -not -path "./.git*" -exec git rm {} \;',
          workingDirectory: 'aur',
        ),
      ];
}
