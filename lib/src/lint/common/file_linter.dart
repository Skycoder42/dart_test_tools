import 'file_result.dart';
import 'linter.dart';

abstract class FileLinter implements Linter {
  bool shouldAnalyze(String path);

  Future<FileResult> analyzeFile(String path);

  Iterable<String> collectFiles() => contextCollection.contexts
      .expand((context) => context.contextRoot.analyzedFiles())
      .where((path) => shouldAnalyze(path));

  @override
  Stream<FileResult> call() =>
      Stream.fromIterable(collectFiles()).asyncMap(analyzeFile);
}
