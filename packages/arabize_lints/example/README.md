# Example

Add the plugin to `analysis_options.yaml`:

```yaml
plugins:
  arabize_lints: ^1.0.0
```

Then run `flutter analyze`, or open the file in your editor:

```dart
Padding(
  padding: const EdgeInsets.only(left: 16), // prefer_directional_edge_insets
  child: Text(
    'arabize',
    textAlign: TextAlign.left, // prefer_text_align_start_end
  ),
)
```

Apply the quick fix and it becomes:

```dart
Padding(
  padding: const EdgeInsetsDirectional.only(start: 16),
  child: Text('arabize', textAlign: TextAlign.start),
)
```

A Flutter app that triggers every rule is in the [repository](https://github.com/Omarelnasherty/arabize/tree/main/example).
