import 'package:flutter/material.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/favorites_repository.dart';
import 'package:vocafusion/screens/learning_screen/widgets/widgets.dart';

class FlashbackWidget extends StatefulWidget {
  final WordCard item;

  const FlashbackWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<FlashbackWidget> createState() => _FlashbackWidgetState();
}

class _FlashbackWidgetState extends State<FlashbackWidget> {
  bool isFavorite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final favRepository = locator.get<FavoritesRepository>();
    final isFav = await favRepository.isFavorite(widget.item.id);

    if (mounted) {
      setState(() {
        isFavorite = isFav;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isLoading = true;
    });

    final favRepository = locator.get<FavoritesRepository>();
    final isFav = await favRepository.toggleFavorite(widget.item.id);

    if (mounted) {
      setState(() {
        isFavorite = isFav;
        isLoading = false;
      });
    }
  }

  // Extract text before, target word, and text after
  List<String> _extractContextParts() {
    final fullContext = widget.item.context;

    // First try to match text with ** markers
    final wordPattern = RegExp(r'\*\*(.*?)\*\*');
    final match = wordPattern.firstMatch(fullContext);

    if (match != null) {
      final beforeContext = fullContext.substring(0, match.start);
      final targetWord = match.group(1)!;
      final afterContext = fullContext.substring(match.end);
      return [beforeContext, targetWord, afterContext];
    }

    // If no match found, try to split around the plain word
    final plainWordIndex = fullContext.indexOf(widget.item.word);
    if (plainWordIndex >= 0) {
      final beforeContext = fullContext.substring(0, plainWordIndex);
      final targetWord = widget.item.word;
      final afterContext =
          fullContext.substring(plainWordIndex + targetWord.length);
      return [beforeContext, targetWord, afterContext];
    }

    // Fallback
    return ["", widget.item.word, ""];
  }

  @override
  Widget build(BuildContext context) {
    final contextParts = _extractContextParts();
    final beforeText = contextParts[0];
    final targetWord = contextParts[1];
    final afterText = contextParts[2];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                icon: Icon(
                  isLoading
                      ? Icons.hourglass_empty
                      : isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: isLoading ? null : _toggleFavorite,
                iconSize: 21,
              ),
              Spacer(),
              Text(
                "Flashback",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              Spacer(),
              IconButton.filledTonal(
                icon: Icon(Icons.refresh),
                onPressed: () {},
                iconSize: 21,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline with text sections
          Stack(
            alignment: Alignment.center,
            children: [
              // Vertical dashed line
              Positioned(
                top: 0,
                bottom: 0,
                child: CustomPaint(
                  size:
                      Size(2, 340), // Height matches all three sections + gaps
                  painter: DashedLinePainter(),
                ),
              ),

              // Three text sections stacked vertically
              Column(
                children: [
                  // Previous context (dimmed)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Opacity(
                      opacity: 0.7,
                      child: Text(
                        beforeText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Connector circle
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),

                  // Target word (highlighted)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.5),
                          offset: Offset(0, 0),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Definition
                        Text(
                          widget.item.definition,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        // Highlighted word
                        Text(
                          targetWord,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffFF0307),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Connector circle
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),

                  // After context (dimmed)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Opacity(
                      opacity: 0.7,
                      child: Text(
                        afterText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              IconButton.filledTonal(
                icon: Icon(Icons.mic),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: Icon(Icons.play_arrow),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add this new widget after the FlashbackWidget class
class ContextualFlashbackWidget extends StatefulWidget {
  final WordCard item1;
  final WordCard item2; // Middle item (focus)
  final WordCard item3;

  const ContextualFlashbackWidget({
    Key? key,
    required this.item1,
    required this.item2,
    required this.item3,
  }) : super(key: key);

  @override
  State<ContextualFlashbackWidget> createState() =>
      _ContextualFlashbackWidgetState();
}

class _ContextualFlashbackWidgetState extends State<ContextualFlashbackWidget> {
  bool isFavorite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  // Helper method to highlight the target word in a context string
  String _highlightWordInContext(WordCard item) {
    final context = item.context;

    // Check if word is already highlighted with **
    if (context.contains("**${item.word}**")) {
      return context;
    }

    // Otherwise add highlighting
    return context.replaceAll(item.word, "**${item.word}**");
  }

  @override
  Widget build(BuildContext context) {
    // Create context strings - only highlight the middle one
    final context1 = widget.item1.context; // No highlighting
    final context2 = _highlightWordInContext(widget.item2); // Highlighted
    final context3 = widget.item3.context; // No highlighting

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12), // Reduced padding
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // More compact header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Text(
                  "Contextual",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.layers, size: 16),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Timeline with three items - more compact
          Stack(
            alignment: Alignment.center,
            children: [
              // Vertical dashed line
              Positioned(
                top: 0,
                bottom: 0,
                child: CustomPaint(
                  size: Size(1.5, 240), // Shorter height
                  painter: DashedLinePainter(color: Colors.green.shade400),
                ),
              ),

              // Three items in timeline
              Column(
                children: [
                  // First word - simplified
                  _buildSimpleTimelineItem(
                    widget.item1.definition,
                    context1,
                    false, // not middle item
                  ),

                  // Small connector dot
                  Container(
                    width: 10, // Smaller dot
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),

                  // MIDDLE ITEM (focus) - more prominent
                  _buildMiddleTimelineItem(
                    widget.item2.word,
                    widget.item2.definition,
                    context2,
                  ),

                  // Small connector dot
                  Container(
                    width: 10, // Smaller dot
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),

                  // Third word - simplified
                  _buildSimpleTimelineItem(
                    widget.item3.definition,
                    context3,
                    false, // not middle item
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Minimal audio controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow, size: 18),
                onPressed: () {},
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Simplified timeline item for top and bottom (no word in header)
  Widget _buildSimpleTimelineItem(
      String definition, String context, bool isMiddle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Just the definition
          Text(
            definition,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3),
          // Context - regular styling
          Flexible(
            child: Text(
              context,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Special timeline item for the middle (with word and highlighting)
  Widget _buildMiddleTimelineItem(
      String word, String definition, String context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200.withOpacity(0.4),
            offset: Offset(0, 0),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word and definition in one line
          Row(
            children: [
              Expanded(
                child: Text(
                  definition,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          // Highlighted context
          Flexible(
            child: TextWithTextHighlited(
              context,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
