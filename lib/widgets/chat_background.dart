import 'package:flutter/material.dart';
import 'tiled_svg_repeat.dart';

class ChatBackground extends StatelessWidget {
  final Widget child;
  const ChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              // Diagonal, smooth two-part gradient using mirror tiling
              begin: Alignment.topLeft,
              end: Alignment.center,
              colors: [
                Color(0xFFCBD38B), // #cbd38b
                Color(0xFF8CB885), // #8cb885
              ],
              tileMode: TileMode.mirror,
              stops: [0.0, 1.0],
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: TiledSvgRepeat(
              asset: 'assets/chat_bg/pattern_space.svg',
              tile: 320, // base tile size
              color: Color(0xFF7AA673), // #7aa673
              opacity: 0.75,
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
} 