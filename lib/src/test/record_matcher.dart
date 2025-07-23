import 'package:test/test.dart';

class _Marker {
  static const value = _Marker();

  const _Marker();
}

Matcher isRecord(
  dynamic $1, [
  dynamic $2 = _Marker.value,
  dynamic $3 = _Marker.value,
  dynamic $4 = _Marker.value,
  dynamic $5 = _Marker.value,
  dynamic $6 = _Marker.value,
  dynamic $7 = _Marker.value,
  dynamic $8 = _Marker.value,
  dynamic $9 = _Marker.value,
]) {
  if (!identical($9, _Marker.value)) {
    return _isRecord9($1, $2, $3, $4, $5, $6, $7, $8, $9);
  } else if (!identical($8, _Marker.value)) {
    return _isRecord8($1, $2, $3, $4, $5, $6, $7, $8);
  } else if (!identical($7, _Marker.value)) {
    return _isRecord7($1, $2, $3, $4, $5, $6, $7);
  } else if (!identical($6, _Marker.value)) {
    return _isRecord6($1, $2, $3, $4, $5, $6);
  } else if (!identical($5, _Marker.value)) {
    return _isRecord5($1, $2, $3, $4, $5);
  } else if (!identical($4, _Marker.value)) {
    return _isRecord4($1, $2, $3, $4);
  } else if (!identical($3, _Marker.value)) {
    return _isRecord3($1, $2, $3);
  } else if (!identical($2, _Marker.value)) {
    return _isRecord2($1, $2);
  } else {
    return _isRecord1($1);
  }
}

Matcher _isRecord1(dynamic $1) =>
    isA<(dynamic,)>().having((m) => m.$1, r'$1', $1);

Matcher _isRecord2(dynamic $1, dynamic $2) => isA<(dynamic, dynamic)>()
    .having((m) => m.$1, r'$1', $1)
    .having((m) => m.$2, r'$2', $2);

Matcher _isRecord3(dynamic $1, dynamic $2, dynamic $3) =>
    isA<(dynamic, dynamic, dynamic)>()
        .having((m) => m.$1, r'$1', $1)
        .having((m) => m.$2, r'$2', $2)
        .having((m) => m.$3, r'$3', $3);

Matcher _isRecord4(dynamic $1, dynamic $2, dynamic $3, dynamic $4) =>
    isA<(dynamic, dynamic, dynamic, dynamic)>()
        .having((m) => m.$1, r'$1', $1)
        .having((m) => m.$2, r'$2', $2)
        .having((m) => m.$3, r'$3', $3)
        .having((m) => m.$4, r'$4', $4);

Matcher _isRecord5(
  dynamic $1,
  dynamic $2,
  dynamic $3,
  dynamic $4,
  dynamic $5,
) => isA<(dynamic, dynamic, dynamic, dynamic, dynamic)>()
    .having((m) => m.$1, r'$1', $1)
    .having((m) => m.$2, r'$2', $2)
    .having((m) => m.$3, r'$3', $3)
    .having((m) => m.$4, r'$4', $4)
    .having((m) => m.$5, r'$5', $5);

Matcher _isRecord6(
  dynamic $1,
  dynamic $2,
  dynamic $3,
  dynamic $4,
  dynamic $5,
  dynamic $6,
) => isA<(dynamic, dynamic, dynamic, dynamic, dynamic, dynamic)>()
    .having((m) => m.$1, r'$1', $1)
    .having((m) => m.$2, r'$2', $2)
    .having((m) => m.$3, r'$3', $3)
    .having((m) => m.$4, r'$4', $4)
    .having((m) => m.$5, r'$5', $5)
    .having((m) => m.$6, r'$6', $6);

Matcher _isRecord7(
  dynamic $1,
  dynamic $2,
  dynamic $3,
  dynamic $4,
  dynamic $5,
  dynamic $6,
  dynamic $7,
) => isA<(dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic)>()
    .having((m) => m.$1, r'$1', $1)
    .having((m) => m.$2, r'$2', $2)
    .having((m) => m.$3, r'$3', $3)
    .having((m) => m.$4, r'$4', $4)
    .having((m) => m.$5, r'$5', $5)
    .having((m) => m.$6, r'$6', $6)
    .having((m) => m.$7, r'$7', $7);

Matcher _isRecord8(
  dynamic $1,
  dynamic $2,
  dynamic $3,
  dynamic $4,
  dynamic $5,
  dynamic $6,
  dynamic $7,
  dynamic $8,
) =>
    isA<
          (
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
          )
        >()
        .having((m) => m.$1, r'$1', $1)
        .having((m) => m.$2, r'$2', $2)
        .having((m) => m.$3, r'$3', $3)
        .having((m) => m.$4, r'$4', $4)
        .having((m) => m.$5, r'$5', $5)
        .having((m) => m.$6, r'$6', $6)
        .having((m) => m.$7, r'$7', $7)
        .having((m) => m.$8, r'$8', $8);
Matcher _isRecord9(
  dynamic $1,
  dynamic $2,
  dynamic $3,
  dynamic $4,
  dynamic $5,
  dynamic $6,
  dynamic $7,
  dynamic $8,
  dynamic $9,
) =>
    isA<
          (
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
            dynamic,
          )
        >()
        .having((m) => m.$1, r'$1', $1)
        .having((m) => m.$2, r'$2', $2)
        .having((m) => m.$3, r'$3', $3)
        .having((m) => m.$4, r'$4', $4)
        .having((m) => m.$5, r'$5', $5)
        .having((m) => m.$6, r'$6', $6)
        .having((m) => m.$7, r'$7', $7)
        .having((m) => m.$8, r'$8', $8)
        .having((m) => m.$9, r'$9', $9);
