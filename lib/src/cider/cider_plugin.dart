import 'package:cider/cider.dart';

abstract class CiderPlugin {
  CiderPlugin._();

  void call(Cider cider) {}
}
