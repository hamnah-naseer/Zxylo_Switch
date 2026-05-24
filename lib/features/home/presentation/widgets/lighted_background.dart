import 'package:flutter/material.dart';

import '../../../../core/theme/sh_colors.dart';


class LightedBackgound extends StatelessWidget {
  const LightedBackgound({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: SHColors.backgroundColor),
        Transform.scale(
          scale: 2,
          alignment: Alignment.center,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3E5C76), Color(0xFF1D2D44)],
                  stops: [0.1, 0.3],
                ),
              ),
            ),
          ),

        child,
      ],
    );
  }
}
