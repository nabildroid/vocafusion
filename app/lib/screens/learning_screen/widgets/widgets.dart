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

class TextWithTextHighlited extends StatelessWidget {
  final String text;
  final double fontSize;
  const TextWithTextHighlited(
    this.text, {
    super.key,
    this.fontSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    // First pass: handle red text (double asterisks)
    List<InlineSpan> spans = [];
    RegExp redPattern = RegExp(r'\*\*(.*?)\*\*');

    int lastEnd = 0;
    for (Match match in redPattern.allMatches(text)) {
      // Add any text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Add the red text
      spans.add(TextSpan(
        text: match.group(1)!,
        style: TextStyle(color: Color(0xffFF0307)),
      ));

      lastEnd = match.end;
    }

    // Add any remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    // Second pass: handle bold text (single asterisks) in regular text spans
    List<InlineSpan> finalSpans = [];
    RegExp boldPattern = RegExp(r'\*(.*?)\*');

    for (InlineSpan span in spans) {
      if (span is TextSpan && span.style?.color != Color(0xffFF0307)) {
        // This is a regular text span, process it for bold text
        String spanText = span.text!;
        int spanLastEnd = 0;

        List<InlineSpan> boldSpans = [];
        for (Match match in boldPattern.allMatches(spanText)) {
          // Add any text before this match
          if (match.start > spanLastEnd) {
            boldSpans.add(
                TextSpan(text: spanText.substring(spanLastEnd, match.start)));
          }

          // Add the bold text
          boldSpans.add(TextSpan(
            text: match.group(1)!,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blueAccent.shade700),
          ));

          spanLastEnd = match.end;
        }

        // Add any remaining text
        if (spanLastEnd < spanText.length) {
          boldSpans.add(TextSpan(text: spanText.substring(spanLastEnd)));
        }

        finalSpans.addAll(boldSpans);
      } else {
        // This is already a red text span, add it as is
        finalSpans.add(span);
      }
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        children: finalSpans,
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({this.color = const Color(0xFF42A5F5)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 5;

    double startY = 0;
    while (startY < size.height) {
      // Draw a small line
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
