import 'package:meta/meta.dart';

@internal
enum BumpLevel() {
  build,
  patch,
  minor,
  breaking,
  major;

  static BumpLevel? maxOf(Iterable<BumpLevel?> levels) =>
      levels.nonNulls.fold<BumpLevel?>(
        null,
        (max, level) => max == null || level.index > max.index ? level : max,
      );
}
