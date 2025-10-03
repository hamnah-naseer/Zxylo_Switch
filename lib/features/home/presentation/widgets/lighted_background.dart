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
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(1.4)
              ..rotateX(0.1)
              ..setTranslationRaw(90, -80, 0),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  focal: Alignment.topCenter,
                  center: Alignment(0, -0.55),
                  colors: [
                    Colors.white,
                    Color(0xFF20B2AA),
                    Color(0xFF483D8B),
                  ],
                  stops: [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
