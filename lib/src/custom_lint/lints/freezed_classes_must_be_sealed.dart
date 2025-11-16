// import 'package:analyzer/dart/ast/ast.dart';
// import 'package:analyzer/error/listener.dart';
// import 'package:custom_lint_builder/custom_lint_builder.dart';
// import 'fixes/add_sealed_keyword.dart';

// class FreezedClassesMustBeSealed extends DartLintRule {
//   static const _code = LintCode(
//     name: 'freezed_classes_must_be_sealed',
//     problemMessage: 'Freezed classes must be sealed.',
//     correctionMessage: 'Add the sealed keyword to the class.',
//   );

//   const FreezedClassesMustBeSealed() : super(code: _code);

//   @override
//   void run(
//     CustomLintResolver resolver,
//     DiagnosticReporter reporter,
//     CustomLintContext context,
//   ) {
//     context.registry.addClassDeclaration((node) {
//       if (node.isUnsealedFreezed) {
//         reporter.atToken(node.classKeyword, _code);
//       }
//     });
//   }

//   @override
//   List<Fix> getFixes() => [FreezedClassesMustBeSealedFix()];
// }

// extension ClassDeclarationX on ClassDeclaration {
//   bool get isUnsealedFreezed {
//     final isFreezed = metadata.any(
//       (a) => a.name.name.toLowerCase() == 'freezed',
//     );
//     if (!isFreezed) {
//       return false;
//     }

//     final isSealed = sealedKeyword != null;
//     return !isSealed;
//   }
// }
