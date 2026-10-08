import 'package:flutter/material.dart';

/// Every widget here assumes a left-to-right layout. Each line is flagged by
/// one of the arabize lints.
class RtlIssues extends StatelessWidget {
  const RtlIssues({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
              ),
              border: const Border(left: BorderSide()),
            ),
            child: const Text('arabize', textAlign: TextAlign.left),
          ),
          const Positioned(left: 0, top: 0, child: Icon(Icons.chevron_left)),
          const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
