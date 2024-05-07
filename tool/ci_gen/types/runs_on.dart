enum RunsOn {
  ubuntuLatest('ubuntu-latest'),
  macosLatest('macos-latest'),
  windowsLatest('windows-latest');

  final String id;

  const RunsOn(this.id);
}
