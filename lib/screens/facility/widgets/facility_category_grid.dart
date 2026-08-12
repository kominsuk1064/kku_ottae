import 'dart:math' as math;

import 'package:flutter/material.dart';

class FacilityCategoryGrid extends StatelessWidget {
  const FacilityCategoryGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  static const double _maxContentWidth = 720;

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(constraints.maxWidth, _maxContentWidth);
        final crossAxisCount = switch (contentWidth) {
          < 360 => 1,
          < 620 => 2,
          _ => 3,
        };

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: GridView.builder(
              padding: EdgeInsets.all(contentWidth < 360 ? 12 : 20),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 132,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: itemBuilder,
            ),
          ),
        );
      },
    );
  }
}

class FacilityCategoryTile extends StatelessWidget {
  const FacilityCategoryTile({
    super.key,
    required this.label,
    required this.symbol,
    required this.onTap,
  });

  final String label;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(8));

    return Material(
      color: Colors.white,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Text(symbol, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
