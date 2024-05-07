enum RunsOn {
  ubuntuLatest('ubuntu-latest'),
  macosLatest('macos-latest'), // ARM64
  macos13('macos-13'), // X86_64
  windowsLatest('windows-latest');

  final String id;

  const RunsOn(this.id);
}
