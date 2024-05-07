enum RunsOn {
  ubuntuLatest('ubuntu-latest'),
  macosLatestArm64('macos-latest'),
  macosLatestX86('macos-latest-large'),
  windowsLatest('windows-latest');

  final String id;

  const RunsOn(this.id);
}
