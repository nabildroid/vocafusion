import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intrinsic_dimension/intrinsic_dimension.dart';

class AnimToFillViewForScrolling extends StatefulWidget {
  final Widget child;
  final bool isFilled;
  final double maxHeight;
  final bool debug;

  final double opacity;

  const AnimToFillViewForScrolling({
    super.key,
    required this.child,
    this.isFilled = true,
    required this.maxHeight,
    this.debug = false,
    this.opacity = 1.0,
  });

  @override
  State<AnimToFillViewForScrolling> createState() => _AnimToFillViewState();
}

class _AnimToFillViewState extends State<AnimToFillViewForScrolling> {
  final h = ValueNotifier(10000.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 350),
      opacity: widget.opacity,
      child: Container(
        color: widget.debug ? Colors.red.shade100 : null,
        child: Column(
          children: [
            IntrinsicDimension(listener: (_, __, height, a) {
              print(a);

              h.value = height;
            }, builder: (context, _, __, ___) {
              return ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: double.infinity),
                child: widget.child,
              );
            }),
            ValueListenableBuilder(
              valueListenable: h,
              builder: (_, h, ___) => AnimatedContainer(
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                height: widget.isFilled ? max(50, widget.maxHeight - h) : 0,
              ),
            )
          ],
        ),
      ),
    );
  }
}
