import 'package:flutter/material.dart';

class FlowBraning extends StatelessWidget {
  const FlowBraning({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, -3),
            ),
          ],
        ),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Pick Path",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            TreeDiagramWidget(
              options: [
                "I know this word well",
                "I'm still learning this",
                "I need to review it again"
              ],
              onOptionSelected: (index) {},
            ),
          ],
        ),
      ),
    );
  }
}

class TreeDiagramWidget extends StatelessWidget {
  final List<String> options;
  final Function(int) onOptionSelected;

  const TreeDiagramWidget({
    Key? key,
    required this.options,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Stack(
        children: [
          // Custom painter for the dashed lines and branches
          CustomPaint(
            size: Size(double.infinity, 150),
            painter: TreeDiagramPainter(),
          ),

          // Option buttons at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                options.length,
                (index) => SizedBox(
                  width:
                      MediaQuery.of(context).size.width / options.length - 24,
                  child: ElevatedButton(
                    onPressed: () => onOptionSelected(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: [
                        Colors.green.shade100,
                        Colors.amber.shade100,
                        Colors.red.shade100
                      ][index],
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: [
                            Colors.green.shade400,
                            Colors.amber.shade400,
                            Colors.red.shade400
                          ][index],
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      options[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TreeDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dashedLinePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Main stem path - straight line
    final Path mainPath = Path();
    // Start from top center
    mainPath.moveTo(size.width / 2, 0);
    // Draw straight line to center
    mainPath.lineTo(size.width / 2, size.height * 0.3);

    // Draw the dashed line
    drawDashedLine(canvas, mainPath, dashedLinePaint);

    // Draw the three branches with curves - only the branches are curved
    final branchPath1 = Path();
    branchPath1.moveTo(size.width / 2, size.height * 0.3);
    // Left branch with curve
    branchPath1.quadraticBezierTo(
      size.width / 4, // control point x
      size.height * 0.5, // control point y
      size.width / 6, // end point x
      size.height - 40, // end point y
    );

    final branchPath2 = Path();
    branchPath2.moveTo(size.width / 2, size.height * 0.3);
    // Middle branch with subtle S curve
    branchPath2.cubicTo(
      size.width / 2 + 10, // first control point x
      size.height * 0.4, // first control point y
      size.width / 2 - 10, // second control point x
      size.height * 0.6, // second control point y
      size.width / 2, // end point x
      size.height - 40, // end point y
    );

    final branchPath3 = Path();
    branchPath3.moveTo(size.width / 2, size.height * 0.3);
    // Right branch with curve
    branchPath3.quadraticBezierTo(
      3 * size.width / 4, // control point x
      size.height * 0.5, // control point y
      5 * size.width / 6, // end point x
      size.height - 40, // end point y
    );

    drawDashedLine(canvas, branchPath1, dashedLinePaint);
    drawDashedLine(canvas, branchPath2, dashedLinePaint);
    drawDashedLine(canvas, branchPath3, dashedLinePaint);
  }

  void drawDashedLine(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 5;
    const dashSpace = 3;

    final Path dashPath = Path();
    final metric = path.computeMetrics().first;
    var distance = 0.0;

    while (distance < metric.length) {
      final start = distance;
      distance += dashWidth;
      if (distance > metric.length) {
        distance = metric.length;
      }

      final extractPath = metric.extractPath(start, distance);
      dashPath.addPath(extractPath, Offset.zero);

      distance += dashSpace;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
