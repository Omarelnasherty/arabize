import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/fixes/use_directional_edge_insets.dart';
import 'src/rules/prefer_directional_edge_insets.dart';

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
  }
}
