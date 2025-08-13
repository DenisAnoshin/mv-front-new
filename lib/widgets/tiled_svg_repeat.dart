import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TiledSvgRepeat extends StatelessWidget {
  final String asset;
  final double tile; // logical pixels for each tile
  final Color color;
  final double opacity;
  const TiledSvgRepeat({super.key, required this.asset, this.tile = 320, this.color = Colors.black, this.opacity = 0.6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = (constraints.maxWidth / tile).ceil() + 1;
        final rows = (constraints.maxHeight / tile).ceil() + 1;
        final widgets = <Widget>[];
        for (int y = 0; y < rows; y++) {
          for (int x = 0; x < cols; x++) {
            widgets.add(Positioned(
              left: x * tile,
              top: y * tile,
              width: tile,
              height: tile,
              child: Opacity(
                opacity: opacity,
                child: SvgPicture.asset(
                  asset,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  alignment: Alignment.topLeft,
                ),
              ),
            ));
          }
        }
        return Stack(children: widgets);
      },
    );
  }
} 