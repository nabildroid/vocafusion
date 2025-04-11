import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocafusion/cubits/content_cubit.dart';
import 'package:vocafusion/cubits/learning/learning_session_cubit.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/screens/learning_screen/widgets/widgets.dart';

class QuizWidget extends StatefulWidget {
  final WordCard item;
  final ValueNotifier<bool?> answerNotifier;

  final bool showIsCorrect;
  final bool showCorrectAnswer;

  const QuizWidget({
    super.key,
    required this.item,
    required this.answerNotifier,
    required this.showIsCorrect,
    required this.showCorrectAnswer,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  bool isCorrect = false;
  int attempt = 0;
  bool showFeedback = false;
  List<String> options = [];
  List<int> hiddenWordIndices = [];

  @override
  void initState() {
    super.initState();
    // Generate a list of options including the correct word
    options = _generateOptions();
    // Generate indices of words to hide in the definition
    hiddenWordIndices = _generateHiddenWordIndices();
    widget.answerNotifier.value = null;
  }

  List<String> _generateOptions() {
    // In a real app, you would generate distractors based on the word
    // Here we're creating some mock options
    final words = List<WordCard>.from(context.read<ContentCubit>().state.words);
    words.shuffle();
    List<String> wordOptions = [
      widget.item.word,
      ...words.sublist(0, 3).map((e) => e.word),
    ];

    // Shuffle the options
    // wordOptions.shuffle();
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
    final definitionWords = widget.item.targetDefinition.split(' ');
    // Don't hide words if definition is too short
    if (definitionWords.length < 4) return [];

    // Determine how many words to hide (30-50% of words)
    final numberOfWordsToHide =
        (definitionWords.length * (0.3 + Random().nextDouble() * 0.2)).round();

    // Create a list of word indices starting from index 2 (skip first two words)
    final availableIndices =
        List<int>.generate(definitionWords.length - 2, (i) => i + 2);

    // Shuffle and take first n elements
    availableIndices.shuffle();
    return availableIndices
        .take(min(numberOfWordsToHide, availableIndices.length))
        .toList();
  }

  // Create a RichText with some words hidden in the definition
  Widget _buildDefinitionWithHiddenWords() {
    final definitionWords = widget.item.targetDefinition.split(' ');
    final List<InlineSpan> spans = [];

    for (int i = 1; i < definitionWords.length; i++) {
      if (hiddenWordIndices.contains(i)) {
        // Add underscores for hidden words
        spans.add(TextSpan(
          text: ".",
          style: TextStyle(
            color: Colors.black45,
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
      maxLines: 3,
      softWrap: true,
      text: TextSpan(
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade200.withAlpha(100)),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fill in the blank with the correct word",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black38,
            ),
          ),
          SizedBox(height: 4),
          _buildDefinitionWithHiddenWords(),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 750),
              child: TextWithTextHighlited(
                key: ValueKey(widget.showCorrectAnswer),
                (widget.showCorrectAnswer
                    ? widget.item.context
                    : contextWithBlank),
              ),
            ),
          ),
          SizedBox(height: 24),
          QuizOptionsGroup(
            options: options,
            correctIndex: widget.showIsCorrect ? widget.item.word : null,
            onSelected: (selected) {
              final isCorrect = selected == widget.item.word;
              widget.answerNotifier.value = isCorrect;

              context.read<SrCubit>().recordQuizAnswer(widget.item, isCorrect,
                  secondTry: attempt != 0);

              attempt++;
              if (attempt < 2) {
                context
                    .read<LearningSessionCubit>()
                    .removeFailedTest(widget.item.id);
              } else if (attempt == 2) {
                context
                    .read<LearningSessionCubit>()
                    .registerFailedTest(widget.item.id);
              }
            },
            showCorrectIndex: widget.showCorrectAnswer,
          )
        ],
      ),
    );
  }
}

class QuizOptionsGroup extends StatefulWidget {
  final List<String> options;
  final String? correctIndex;
  final bool showCorrectIndex;

  final void Function(String selected) onSelected;

  const QuizOptionsGroup({
    super.key,
    required this.options,
    this.correctIndex,
    required this.onSelected,
    this.showCorrectIndex = true,
  });

  @override
  State<QuizOptionsGroup> createState() => QuizOptionsGroupState();
}

class QuizOptionsGroupState extends State<QuizOptionsGroup> {
  String selected = "";
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: [
      for (final o in widget.options) ...[
        CustomOutlinedButton(
          text: o,
          isSelected: widget.correctIndex == null && selected == o,
          isInCorrect: widget.correctIndex != null &&
              o == selected &&
              o != widget.correctIndex,
          isCorrect: (o == selected || widget.showCorrectIndex) &&
              widget.correctIndex != null &&
              o == widget.correctIndex,
          onPressed: () {
            setState(() {
              selected = o;
            });
            widget.onSelected(o);
          },
          disabled: widget.correctIndex != null,
        ),
      ]
    ]);
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  final bool disabled;
  final bool isSelected;
  final bool isCorrect;
  final bool isSubtleCorrect;
  final bool isInCorrect;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.disabled = false,
    this.isSelected = false,
    this.isCorrect = false,
    this.isSubtleCorrect = false,
    this.isInCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: disabled ? null : onPressed,
      clipBehavior: Clip.none,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected
              ? Colors.blueAccent.shade700
              : isCorrect
                  ? Colors.blueGrey.shade400
                  : isInCorrect
                      ? const Color(0xffa37711)
                      : Colors.grey.shade300,
          width: 1.5,
        ), // Border color

        backgroundBuilder: (ctx, state, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              if (isCorrect)
                Positioned(
                  top: -5,
                  left: -5,
                  child: Icon(
                    Icons.check_box,
                    color: Colors.blueGrey.shade400,
                    size: 22,
                  ),
                ),
              if (isInCorrect)
                Positioned(
                  top: -5,
                  left: -5,
                  child: Icon(
                    Icons.disabled_by_default_rounded,
                    color: const Color(0xffa37711),
                    size: 22,
                  ),
                ),
            ],
          );
        },

        backgroundColor:
            isSubtleCorrect ? Colors.grey.shade200 : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: isSelected
                ? Colors.blue.shade900
                : isInCorrect
                    ? const Color(0xffa37711)
                    : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class QuizSuccessFeedback extends StatefulWidget {
  final VoidCallback onOkPressed;
  final VoidCallback? onWhyPressed;

  final bool isVisible;

  const QuizSuccessFeedback({
    super.key,
    required this.onOkPressed,
    this.onWhyPressed,
    this.isVisible = true,
  });

  @override
  State<QuizSuccessFeedback> createState() => _QuizSuccessFeedbackState();
}

class _QuizSuccessFeedbackState extends State<QuizSuccessFeedback> {
  @override
  void didUpdateWidget(covariant QuizSuccessFeedback oldWidget) {
    if (!oldWidget.isVisible && widget.isVisible) {
      // AudioEffectsService.answerCorrect();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return QuizFeedbackLayout(
      color: const Color(0xffd5f9df),
      okLabel: "Go",
      onOkPressed: widget.onOkPressed,
      onWhyPressed: widget.onWhyPressed,
      top: Row(
        children: [
          Text(
            "🙋",
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(width: 12),
          Text(
            "Amazing",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 12),
          if (Random(DateTime.now().second ~/ 5).nextBool())
            AnimatedOpacity(
              duration: Duration(milliseconds: 450),
              curve: Curves.easeInExpo,
              opacity: widget.isVisible ? 1 : 0,
              child: AnimatedSlide(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInExpo,
                offset: Offset(0, widget.isVisible ? 0 : 0.5),
                child: Text(
                  "+15 XP",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(
                        0xff3ab73a,
                      )),
                ),
              ),
            ),
        ],
      ),
      okButtonStyle: FilledButton.styleFrom(
        backgroundColor: Color(0xff3ab73a),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class QuizFailureFeedback extends StatefulWidget {
  final VoidCallback? onTryPressed;
  final VoidCallback onSeePressed;

  final bool isVisible;

  const QuizFailureFeedback({
    super.key,
    required this.onSeePressed,
    this.onTryPressed,
    this.isVisible = true,
  });

  @override
  State<QuizFailureFeedback> createState() => _QuizFailureFeedbackState();
}

class _QuizFailureFeedbackState extends State<QuizFailureFeedback> {
  @override
  void didUpdateWidget(covariant QuizFailureFeedback oldWidget) {
    if (!oldWidget.isVisible && widget.isVisible) {
      // AudioEffectsService.answerInCorrect();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    bool isInDifficultMode = widget.onTryPressed != null;

    return QuizFeedbackLayout(
      color: Color(0xffffe29a),
      okLabel: (isInDifficultMode || widget.onTryPressed == null)
          ? "See the Answer"
          : "لا تستسلم، جرب ثانية",
      whyLabel: !isInDifficultMode ? "See the Answer" : "Try Again",
      onOkPressed: (isInDifficultMode || widget.onTryPressed == null)
          ? widget.onSeePressed
          : widget.onTryPressed ?? () {},
      onWhyPressed: widget.onTryPressed == null
          ? null
          : !isInDifficultMode
              ? widget.onSeePressed
              : widget.onTryPressed,
      top: Row(
        children: [
          Text(
            "Be ready, your second Chance!",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      okButtonStyle: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      whyButtonStyle: FilledButton.styleFrom(
        backgroundColor: Colors.black12,
        foregroundColor: Colors.black,
      ),
    );
  }
}

class QuizFeedbackLayout extends StatelessWidget {
  final VoidCallback onOkPressed;
  final VoidCallback? onWhyPressed;

  final Widget top;

  final String whyLabel;
  final String okLabel;

  final Color color;

  final ButtonStyle? okButtonStyle;
  final ButtonStyle? whyButtonStyle;

  const QuizFeedbackLayout({
    super.key,
    required this.onOkPressed,
    this.onWhyPressed,
    required this.top,
    this.whyLabel = "why",
    required this.okLabel,
    required this.color,
    this.okButtonStyle,
    this.whyButtonStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          top,
          SizedBox(height: 24),
          Row(
            children: [
              if (onWhyPressed != null) ...[
                FilledButton(
                  style: whyButtonStyle,
                  onPressed: onWhyPressed!,
                  child: Text(whyLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      )),
                ),
                SizedBox(width: 24),
              ],
              Expanded(
                child: FilledButton(
                  style: okButtonStyle,
                  onPressed: onOkPressed,
                  child: Text(
                    okLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
