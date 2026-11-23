import 'package:flutter/material.dart';

class ScrollPage extends StatelessWidget {
  final List<Widget> children, footer;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final Future<void> Function() onMore;
  final EdgeInsetsGeometry padding;
  const ScrollPage({
    super.key,
    required this.children,
    required this.footer,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    required this.onMore,
    required this.padding,
  });
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) {
          if (n.depth == 0 &&
              n.metrics.axis == Axis.vertical &&
              (n.scrollDelta ?? 0) > 0 &&
              n.metrics.extentAfter < 300) {
            onMore();
          }
          return false;
        },
        child: ListView.builder(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: children.length + itemCount + footer.length,
          itemBuilder: (context, index) {
            if (index < children.length) return children[index];
            final row = index - children.length;
            if (row < itemCount) return itemBuilder(context, row);
            return footer[row - itemCount];
          },
        ),
      );
}
