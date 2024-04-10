import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/env.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/build_linux_job_builder.dart';

class BuildLinuxWorkflow implements WorkflowBuilder {
  static const _flutterSdkGpgKey = '''
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEZhVSPhYJKwYBBAHaRw8BAQdAyUCjyTVvL0R5RQZw6NeF1mcjTyxjz56RjWRE
x+qI6dC0dFNreWNvZGVyNDIgKEdQRyBLZXkgZm9yIG9yZy5mcmVlZGVza3RvcC5T
ZGsuRXh0ZW5zaW9uLmZsdXR0ZXIgZmxhdHBhayBidW5kbGVzKSA8U2t5Y29kZXI0
MkB1c2Vycy5ub3JlcGx5LmdpdGh1Yi5jb20+iJMEExYKADsWIQRM3jbjqquCG4iR
YqdbEIdDIpRYLgUCZhVSPgIbAwULCQgHAgIiAgYVCgkICwIEFgIDAQIeBwIXgAAK
CRBbEIdDIpRYLmBgAP40jr4173kOMnhnIsLwgwOIunXht/KZkVRGWjHUV7wP5wD8
C2ebyeiaya6PrQ/u+AG/mIbTPm2qgl58ESWpQXVmawC4OARmFVI+EgorBgEEAZdV
AQUBAQdARVAUlIBUyukjFlGYscv8T49PdW4PAexZRqE1JnyMr1cDAQgHiHgEGBYK
ACAWIQRM3jbjqquCG4iRYqdbEIdDIpRYLgUCZhVSPgIbDAAKCRBbEIdDIpRYLv5A
AQD1vBoAhv6iM+ePgHGAnl01VyKuJfcRcsOQ7bQl5j/bKAEAzXtbKs3/rLkKlBF5
08PRzDxSMStKeNf+L6NVrSKNVgc=
=Cnso
-----END PGP PUBLIC KEY BLOCK-----
''';

  const BuildLinuxWorkflow();

  @override
  String get name => 'build-linux';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();

    final buildLinuxJobBuilder = BuildLinuxJobBuilder(
      sdkVersion: inputContext(WorkflowInputs.flatpakSdkVersion),
      bundleName: inputContext(WorkflowInputs.bundleName),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      manifestPath: inputContext(WorkflowInputs.manifestPath),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      env: const Env({'FLUTTER_SDK_GPG_KEY': _flutterSdkGpgKey}),
      jobs: {
        buildLinuxJobBuilder.id: buildLinuxJobBuilder.build(),
      },
    );
  }
}
