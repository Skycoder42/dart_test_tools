import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';

part 'import_result.freezed.dart';

@freezed
class DirectiveError with _$DirectiveError {
  const DirectiveError._();

  // ignore: sort_unnamed_constructors_first
  const factory DirectiveError({
    required String directive,
    required int line,
  }) = _DirectiveError;

  @override
  String toString() => 'Line $line: $directive';
}

@freezed
class ImportResult with _$ImportResult {
  const ImportResult._();

  const factory ImportResult.skipped({
    required String path,
    required String reason,
  }) = _Skipped;
  const factory ImportResult.accepted(String path) = _Accepted;
  const factory ImportResult.rejected({
    required String path,
    required List<DirectiveError> errors,
  }) = _Rejected;
  const factory ImportResult.failed({
    required String path,
    required Object error,
    StackTrace? stackTrace,
    String? directive,
  }) = _Failed;

  bool get isFailure => map(
        skipped: (_) => false,
        accepted: (_) => false,
        rejected: (_) => true,
        failed: (_) => true,
      );

  void log(Logger logger) => when(
        skipped: (path, reason) => logger.warning('Skipped $path: $reason'),
        accepted: (path) => logger.fine('Accepted $path'),
        rejected: (path, errors) {
          logger.severe('Found problematic imports in $path:');
          for (final error in errors) {
            logger.severe(' > $error');
          }
        },
        failed: (path, error, stackTrace, directive) => logger.shout(
          'Failed to analyze '
          '$path${directive != null ? ' at directive <$directive>' : ''}',
          error,
          stackTrace,
        ),
      );
}
