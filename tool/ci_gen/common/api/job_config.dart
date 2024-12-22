import 'package:meta/meta.dart';

abstract base class JobConfig {
  @protected
  @mustCallSuper
  void expand() {}
}
