import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../edits/directional_border_edits.dart';

/// Rewrites `Border` with left and right into `BorderDirectional`.
class UseDirectionalBorder extends ResolvedCorrectionProducer {
  static const FixKind fix = FixKind(
    'arabize.fix.useDirectionalBorder',
    50,
    'Use BorderDirectional',
  );

  UseDirectionalBorder({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => fix;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final creation = node is InstanceCreationExpression
        ? node as InstanceCreationExpression
        : node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) return;

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      for (final r in directionalBorderReplacements(creation)) {
        fileEditBuilder.addSimpleReplacement(
          SourceRange(r.offset, r.length),
          r.text,
        );
      }
    });
  }
}
