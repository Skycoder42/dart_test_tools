import 'package:meta/meta.dart';
import 'package:test/test.dart';

typedef DataToStringFn<TData> = String Function(TData);

@isTestGroup
void testData<TData>(
  String description,
  Iterable<TData> data,
  dynamic Function(TData data) body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
  DataToStringFn<TData>? dataToString,
}) =>
    group(description, () {
      for (final element in data) {
        test(
          '(Variant: ${dataToString?.call(element) ?? element.toString()})',
          () => body(element),
          testOn: testOn,
          timeout: timeout,
          skip: skip,
          tags: tags,
          onPlatform: onPlatform,
          retry: retry,
        );
      }
    });
