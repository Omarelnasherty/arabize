import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/fixes/use_directional_alignment.dart';
import 'src/fixes/use_directional_edge_insets.dart';
import 'src/fixes/use_positioned_directional.dart';
import 'src/fixes/use_text_align_start_end.dart';
import 'src/rules/avoid_hardcoded_text_direction.dart';
import 'src/rules/prefer_directional_alignment.dart';
import 'src/rules/prefer_directional_edge_insets.dart';
import 'src/rules/prefer_positioned_directional.dart';
import 'src/rules/prefer_text_align_start_end.dart';

/// The plugin instance the analysis server loads.
final plugin = ArabizePlugin();

/// Registers the arabize lint rules.
class ArabizePlugin extends Plugin {
  @override
  String get name => 'arabize';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(PreferDirectionalEdgeInsets());
    registry.registerFixForRule(
      PreferDirectionalEdgeInsets.code,
      UseDirectionalEdgeInsets.new,
    );
    registry.registerLintRule(PreferDirectionalAlignment());
    registry.registerFixForRule(
      PreferDirectionalAlignment.code,
      UseDirectionalAlignment.new,
    );
    registry.registerLintRule(PreferPositionedDirectional());
    registry.registerFixForRule(
      PreferPositionedDirectional.code,
      UsePositionedDirectional.new,
    );
    registry.registerLintRule(PreferTextAlignStartEnd());
    registry.registerFixForRule(
      PreferTextAlignStartEnd.code,
      UseTextAlignStartEnd.new,
    );
    registry.registerLintRule(AvoidHardcodedTextDirection());
  }
}
