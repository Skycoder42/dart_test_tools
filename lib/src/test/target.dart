enum Target {
  vm,
  js,
}

extension TargetX on Target {
  String get value => toString().split('.').last;

  static Iterable<String> get values => Target.values.map((e) => e.value);

  static Iterable<Target> parse(Iterable<String> values) =>
      values.map((e) => Target.values.firstWhere((p) => p.value == e));
}
