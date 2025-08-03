import '../../types/action.dart';

abstract interface class ActionBuilder {
  String get name;

  Action build();
}
