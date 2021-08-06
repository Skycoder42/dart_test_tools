enum Mode {
  unit,
  integration,
}

extension ModeX on Mode {
  String get value => toString().split('.').last;

  static Iterable<String> get values => Mode.values.map((e) => e.value);

  static Iterable<Mode> parse(Iterable<String> values) =>
      values.map((e) => Mode.values.firstWhere((m) => m.value == e));
}
