import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../edits/text_align_edits.dart';

/// Rewrites `TextAlign.left` and `TextAlign.right` into `start` and `end`.
class UseTextAlignStartEnd extends ResolvedCorrectionProducer {
  static const FixKind fix = FixKind(
    'arabize.fix.useTextAlignStartEnd',
    50,
    'Use TextAlign.start or TextAlign.end',
  );

  UseTextAlignStartEnd({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => fix;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final identifier = node is PrefixedIdentifier
        ? node as PrefixedIdentifier
        : node.thisOrAncestorOfType<PrefixedIdentifier>();
    if (identifier == null) return;

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      for (final r in directionalTextAlignReplacements(identifier)) {
        fileEditBuilder.addSimpleReplacement(
          SourceRange(r.offset, r.length),
          r.text,
        );
      }
    });
  }
}
