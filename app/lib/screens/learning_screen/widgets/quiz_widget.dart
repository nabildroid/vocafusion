import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vocafusion/models/modeling.dart';

class QuizWidget extends StatefulWidget {
  final WordCard item;

  const QuizWidget({
    super.key,
    required this.item,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  bool isCorrect = false;
  bool hasAttempted = false;
  List<String> options = [];
  List<int> hiddenWordIndices = [];

  @override
  void initState() {
    super.initState();
    // Generate a list of options including the correct word
    options = _generateOptions();
    // Generate indices of words to hide in the definition
    hiddenWordIndices = _generateHiddenWordIndices();
  }

  List<String> _generateOptions() {
    // In a real app, you would generate distractors based on the word
    // Here we're creating some mock options
    List<String> wordOptions = [
      widget.item.word,
      // Add 3 fake options - in a real app these would be better distractors
      'option1',
      'option2',
      'option3',
    ];
    // Shuffle the options
    wordOptions.shuffle();
    return wordOptions;
  }

  // Generate a context paragraph with a blank space
  String get contextWithBlank {
    // Replace the target word with a blank in the context
    // Here, we assume the word is wrapped in ** in the context
    final pattern = "**${widget.item.word}**";
    if (widget.item.context.contains(pattern)) {
      return widget.item.context.replaceAll(pattern, "__________");
    }
    // If the word isn't marked with **, just add a blank
    return widget.item.context.replaceAll(widget.item.word, "__________");
  }

  // Generate random indices of words to hide in the definition
  List<int> _generateHiddenWordIndices() {
    final definitionWords = widget.item.definition.split(' ');
    // Don't hide words if definition is too short
    if (definitionWords.length < 4) return [];

    // Determine how many words to hide (30-50% of words)
    final numberOfWordsToHide =
        (definitionWords.length * (0.3 + Random().nextDouble() * 0.2)).round();

    // Create a list of all word indices
    final allIndices = List<int>.generate(definitionWords.length, (i) => i);

    // Shuffle and take first n elements
    allIndices.shuffle();
    return allIndices.take(numberOfWordsToHide).toList();
  }

  // Create a RichText with some words hidden in the definition
  Widget _buildDefinitionWithHiddenWords() {
    final definitionWords = widget.item.definition.split(' ');
    final List<InlineSpan> spans = [];

    for (int i = 0; i < definitionWords.length; i++) {
      if (hiddenWordIndices.contains(i)) {
        // Add underscores for hidden words
        spans.add(TextSpan(
          text: "_" *
              (definitionWords[i].length > 2 ? definitionWords[i].length : 3),
          style: TextStyle(
            color: Colors.transparent,
          ),
        ));
      } else {
        spans.add(TextSpan(text: definitionWords[i]));
      }

      // Add space after each word except the last one
      if (i < definitionWords.length - 1) {
        spans.add(TextSpan(text: " "));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
        children: spans,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            "Fill in the blank with the correct word",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          _buildDefinitionWithHiddenWords(),
          SizedBox(height: 16),

          // Paragraph with blank space
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: DragTarget<String>(
              builder: (context, candidateData, rejectedData) {
                return Text(
                  isCorrect ? widget.item.context : contextWithBlank,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                );
              },
              onAcceptWithDetails: (context) {
                setState(() {
                  hasAttempted = true;
                  isCorrect = context.data == widget.item.word;
                });
              },
              onWillAcceptWithDetails: (context) {
                return context.data == widget.item.word;
              },
              onLeave: (data) {
                setState(() {
                  hasAttempted = false;
                  isCorrect = false;
                });
              },
            ),
          ),

          SizedBox(height: 24),

          // Show feedback if attempted
          if (hasAttempted)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCorrect ? "Correct! Well done!" : "Incorrect. Try again!",
                style: TextStyle(
                  color:
                      isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          SizedBox(height: 24),

          // Word options
          if (!isCorrect)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: options.map((word) {
                return Draggable<String>(
                  data: word,
                  feedback: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
