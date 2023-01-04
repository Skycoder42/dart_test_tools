import 'dart:io';

import 'package:cider/cider.dart';
import 'package:dart_test_tools/src/cider_plugins/bump_all.dart';

void main(List<String> args) => Cider(
      plugins: [
        BumpAllPlugin(),
      ],
    ).run(args).then((code) => exitCode = code);
