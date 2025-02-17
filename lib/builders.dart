import 'package:build/build.dart';

import 'src/builders/package_metadata/package_metadata_builder.dart';

Builder packageMetadataBuilder(BuilderOptions options) =>
    PackageMetadataBuilder(options);
