import 'dart:async';

import 'package:mocktail/mocktail.dart';

extension WhenFutureX<T> on When<Future<T>> {
  void thenReturnAsync(FutureOr<T> data) => thenAnswer((i) async => data);
}

extension WhenStreamX<T> on When<Stream<T>> {
  void thenStream(Stream<T> stream) => thenAnswer((i) => stream);
}
