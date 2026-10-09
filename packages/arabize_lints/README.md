# arabize_lints

Analyzer lints that catch left-to-right layout assumptions in Flutter code. Most rules come with a quick fix.

## Usage

Add the plugin to your `analysis_options.yaml`:

```yaml
plugins:
  arabize_lints: ^0.1.0
```

Rules are enabled with the plugin. To pick them one by one:

```yaml
plugins:
  arabize_lints:
    version: ^0.1.0
    diagnostics:
      prefer_directional_edge_insets: true
      prefer_directional_alignment: true
      prefer_positioned_directional: true
      prefer_text_align_start_end: true
      avoid_hardcoded_text_direction: true
      prefer_directional_border_radius: true
      prefer_directional_border: true
      avoid_unmirrored_icons: true
```

## Rules

| Rule | Flags | Prefer |
| --- | --- | --- |
| `prefer_directional_edge_insets` | `EdgeInsets.only(left: ...)`, `EdgeInsets.fromLTRB` | `EdgeInsetsDirectional` |
| `prefer_directional_alignment` | `Alignment.centerLeft` and similar | `AlignmentDirectional.centerStart` |
| `prefer_positioned_directional` | `Positioned(left: ...)` | `PositionedDirectional` |
| `prefer_text_align_start_end` | `TextAlign.left`, `TextAlign.right` | `TextAlign.start`, `TextAlign.end` |
| `avoid_hardcoded_text_direction` | `TextDirection.ltr` and `rtl` literals | the ambient `Directionality` |
| `prefer_directional_border_radius` | `BorderRadius.only(topLeft: ...)` | `BorderRadiusDirectional` |
| `prefer_directional_border` | `Border(left: ...)` | `BorderDirectional` |
| `avoid_unmirrored_icons` | `Icons.chevron_left` and similar | `Icon(..., matchTextDirection: true)` |
