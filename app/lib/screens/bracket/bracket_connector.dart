import 'package:flutter/cupertino.dart';

import 'bracket_column.dart';

/// The classic bracket-tree connector: a ")" shape bridging a pair of
/// matches in one round to their single follow-up match in the next.
class BracketConnector extends StatelessWidget {
  const BracketConnector({
    super.key,
    required this.sourceMatchCount,
    this.height = kBracketColumnHeight,
  });

  /// Number of matches feeding into this connector column (e.g. 8 for
  /// the R16→QF bridge). Determines both the per-item height and how
  /// many bracket shapes are drawn.
  final int sourceMatchCount;

  /// Must match the [BracketColumn.height] of the columns it bridges.
  final double height;

  @override
  Widget build(BuildContext context) {
    final itemHeight = height / sourceMatchCount;
    final count = sourceMatchCount ~/ 2;
    return SizedBox(
      width: kBracketConnectorWidth,
      child: Column(
        children: [
          const SizedBox(height: 28),
          SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < count; i++)
                  Container(
                    height: itemHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        top: const BorderSide(color: Color(0x2916162E)),
                        bottom: const BorderSide(color: Color(0x2916162E)),
                        right: const BorderSide(color: Color(0x2916162E)),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(9),
                        bottomRight: Radius.circular(9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
