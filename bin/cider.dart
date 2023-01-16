import 'dart:io';

import 'package:cider/cider.dart';
import 'package:dart_test_tools/cider.dart';

Future<void> main(List<String> args) =>
    Cider(plugins: [const VersionSyncPlugin()])
        .run(args)
        .then((code) => exitCode = code);
