import 'dart:async';
import 'dart:math';

import 'package:entry/entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/learning/biased_sorting_cubit.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/favorites_repository.dart';
import 'package:vocafusion/screens/learning_screen/widgets/widgets.dart';

class LearningScreen extends StatefulWidget {
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int pointer = 1;

  final learningController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();

  final fadeoutOldCards = ValueNotifier(false);
  final floatingButtonActive = ValueNotifier(false);

  final minScreenFlashcard = 0.98;
  double cardsSizeScrollNonce = 0.12;

  @override
  void initState() {
    super.initState();

    itemPositionsListener.itemPositions
        .addListener(listenToItemPositionChanges);

    reactToStateChanges(context.read<BiasedSortingCubit>().state);
  }

  void listenToItemPositionChanges() {
    final positions = itemPositionsListener.itemPositions;
    final last = positions.value.last;

    if (last.index == pointer - 1 && last.itemTrailingEdge < 1.3) {
      floatingButtonActive.value = true;
    } else {
      floatingButtonActive.value = false;
    }
    final diff = (last.itemTrailingEdge - last.itemLeadingEdge);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      cardsSizeScrollNonce = diff > minScreenFlashcard ? 0 : 0.25;
    });

    final edge = diff > minScreenFlashcard ? 1.25 : 1.13;
    if (last.index == pointer - 1 && last.itemTrailingEdge < edge) {
      fadeoutOldCards.value = true;
    } else {
      fadeoutOldCards.value = false;
    }
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions
        .removeListener(listenToItemPositionChanges);
    super.dispose();
  }

  Future<void> workAroundTheScrollIssue() async {
    await Future.delayed(Duration(milliseconds: 250));
    if (!mounted) return;
    await scrollOffsetController.animateScroll(
        offset: 10, duration: Duration(milliseconds: 10));

    setState(() {});
  }

  void next() async {
    pointer = pointer + 1;
    setState(() {});

    if (!mounted) return;

    // workaround the issue that the scollable doesn't know about the items bein Animated to filled
    await workAroundTheScrollIssue();
    await Future.delayed(Duration(milliseconds: 50));

    if (!mounted) return;
    learningController.scrollTo(
      index: pointer,
      duration: Duration(milliseconds: 350),
      alignment: 0.1, //for a reason, this behaves completly unstable
      curve: Curves.easeIn,
      // opacityAnimationWeights: [20, 30, 100],
    );
  }

  List<WordCard> forLearning = [];

  void reactToStateChanges(BiasedSortingState state) {
    setState(() {
      forLearning = state.sorted;
      pointer = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = context.watch<BiasedSortingCubit>().state.sorted;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BlocListener<BiasedSortingCubit, BiasedSortingState>(
            listenWhen: (p, c) {
              return !listEquals(p.sorted, c.sorted);
            },
            listener: (context, state) => reactToStateChanges(state),
            child: LayoutBuilder(builder: (context, c) {
              return ScrollablePositionedList.builder(
                padding: EdgeInsets.only(top: 42),
                itemCount: pointer,
                itemScrollController: learningController,
                scrollOffsetController: scrollOffsetController,
                itemPositionsListener: itemPositionsListener,
                itemBuilder: (context, i) {
                  return ValueListenableBuilder(
                    valueListenable: fadeoutOldCards,
                    builder: (context, fadeout, child) {
                      final opacity = pointer - 2 >= i && fadeout ? .0 : 1.0;

                      return AnimToFillViewForScrolling(
                        debug: false,
                        opacity: opacity,
                        maxHeight: c.maxHeight * minScreenFlashcard,
                        isFilled: pointer - 1 == i,
                        child: child!,
                      );
                    },
                    child: Builder(builder: (ctx) {
                      final item = context
                          .read<BiasedSortingCubit>()
                          .state
                          .sorted
                          .elementAtOrNull(i);

                      if (item == null) return SizedBox.shrink();
                      // final quiz =
                      //     context.read<ContentCubit>().getQuiz(item.id);

                      // if (quiz == null) return SizedBox.shrink();

                      // if (i % 2 == 1) {
                      //   return Padding(
                      //     padding: const EdgeInsets.only(bottom: 20),
                      //     child: QuizWidget(
                      //       word: item,
                      //       quiz: quiz,
                      //     ),
                      //   );
                      // }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: CardWidget(
                          item: item,
                          // item2: item,
                          // item3: item,
                        ),
                      );
                      // return Padding(
                      //   padding: const EdgeInsets.only(bottom: 20),
                      //   child: CardWidget(
                      //     item: item,
                      //   ),
                      // );
                    }),
                  );
                },
              );
            }),
          )),
      bottomSheet: BranchingPathsWidget(),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              context
                  .read<SrCubit>()
                  .recordQuizAnswer(words[pointer - 1], true);
              next();
            },
            child: Text("Easy"),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<SrCubit>()
                  .recordQuizAnswer(words[pointer - 1], false);
              next();
            },
            child: Text("Hard"),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomNavigationBar(
        onFavoriteTap: () {
          context.go('/learn/favorites');
        },
      ),
    );
  }
}

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

class CardWidget extends StatefulWidget {
  final WordCard item;
  const CardWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
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
                widget.item.word,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffFF0307),
                ),
              ),
              Spacer(),
              Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.definition,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          TextWithTextHighlited(
            widget.item.context,
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

class CustomNavigationBar extends StatelessWidget {
  final VoidCallback onFavoriteTap;

  const CustomNavigationBar({
    Key? key,
    required this.onFavoriteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) {
          onFavoriteTap();
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.format_quote),
          label: 'Vocabulary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorite',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          child: Text("3"),
          backgroundColor: Colors.grey.shade200,
          radius: 8,
        ),
      ),
      title: FractionallySizedBox(
        widthFactor: 0.8,
        child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text("2/20",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(width: 4),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.2,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(80),
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        AlwaysStoppedAnimation(Colors.blueGrey.shade800),
                  ),
                ),
              ],
            )),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton.filledTonal(
          onPressed: () {
            context.read<BiasedSortingCubit>().sort();
          },
          icon: Icon(Icons.diamond_outlined),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
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

class BranchingPathsWidget extends StatelessWidget {
  const BranchingPathsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, // Taller to accommodate the new layout
      padding: EdgeInsets.only(top: 12, bottom: 8, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            "Choose Your Path",
            style: TextStyle(
              fontSize: 18, // Larger text
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          SizedBox(height: 6),

          // Branch description
          Text(
            "Select where your learning journey goes next",
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),

          // Branching visualization - takes most of the space
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base point (tree trunk)
                Positioned(
                  bottom: 10,
                  left: MediaQuery.of(context).size.width / 2 - 30,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade700,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.brown.shade900, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Custom painter for all branches
                CustomPaint(
                  painter: TreeBranchingPainter(),
                  size: Size.infinite,
                ),

                // LEFT SIDE BUTTONS - stacked vertically
                Positioned(
                  left: 10,
                  bottom: 45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBranchButton(
                        "Challenge",
                        Icons.sports_esports,
                        Colors.orange.shade800,
                        Colors.orange.shade50,
                        () {},
                      ),
                      SizedBox(height: 15),
                      _buildBranchButton(
                        "Adventure",
                        Icons.hiking,
                        Colors.green.shade800,
                        Colors.green.shade50,
                        () {},
                      ),
                    ],
                  ),
                ),

                // RIGHT SIDE BUTTONS - stacked vertically
                Positioned(
                  right: 10,
                  bottom: 45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBranchButton(
                        "Knowledge",
                        Icons.school,
                        Colors.indigo.shade700,
                        Colors.blue.shade50,
                        () {},
                        isRightSide: true,
                      ),
                      SizedBox(height: 15),
                      _buildBranchButton(
                        "Practice",
                        Icons.psychology,
                        Colors.purple.shade700,
                        Colors.purple.shade50,
                        () {},
                        isRightSide: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build consistently styled branch buttons
  Widget _buildBranchButton(String label, IconData icon, Color color,
      Color bgColor, VoidCallback onPressed,
      {bool isRightSide = false}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isRightSide
            ? SizedBox.shrink()
            : Icon(icon, size: 20, color: Colors.white),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15, // Larger text
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (isRightSide)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0, // Shadow is handled by container
        ),
      ),
    );
  }
}

// Completely reimagined painter for tree-like branching with dashed arcs
class TreeBranchingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = Colors.brown.shade400
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Tree trunk center point
    final trunkX = size.width / 2 - 18;
    final trunkY = size.height - 10;

    // LEFT BRANCH PATHS

    // Main left branch
    _drawDashedPath(
      canvas,
      Path()
        ..moveTo(trunkX, trunkY)
        ..quadraticBezierTo(size.width * 0.33, size.height * 0.5,
            size.width * 0.2, size.height * 0.4),
      dashPaint,
    );

    // Left branch split 1 - goes to top left button
    _drawDashedPath(
      canvas,
      Path()
        ..moveTo(size.width * 0.2, size.height * 0.4)
        ..quadraticBezierTo(size.width * 0.13, size.height * 0.3,
            size.width * 0.15, size.height * 0.2),
      dashPaint,
    );

    // Left branch split 2 - goes to bottom left button
    _drawDashedPath(
      canvas,
      Path()
        ..moveTo(size.width * 0.2, size.height * 0.4)
        ..quadraticBezierTo(size.width * 0.1, size.height * 0.5,
            size.width * 0.15, size.height * 0.45),
      dashPaint,
    );

    // RIGHT BRANCH PATHS

    // Main right branch
    _drawDashedPath(
      canvas,
      Path()
        ..moveTo(trunkX, trunkY)
        ..quadraticBezierTo(size.width * 0.67, size.height * 0.5,
            size.width * 0.8, size.height * 0.4),
      dashPaint,
    );

    // Right branch split 1 - goes to top right button
    _drawDashedPath(
      canvas,
      Path()
        ..moveTo(size.width * 0.8, size.height * 0.4)
        ..quadraticBezierTo(size.width * 0.87, size.height * 0.3,
            size.width * 0.85, size.height * 0.2),
      dashPaint,
    );

    // Right branch split 2 - goes to bottom right button
    _drawDashedPath(
      canvas,
      Path()
        ..moveTo(size.width * 0.8, size.height * 0.4)
        ..quadraticBezierTo(size.width * 0.9, size.height * 0.5,
            size.width * 0.85, size.height * 0.45),
      dashPaint,
    );
  }

  // Helper function to draw dashed paths
  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 5;
    const dashSpace = 3;

    final metrics = path.computeMetrics().first;
    var distance = 0.0;

    while (distance < metrics.length) {
      final start = distance;
      distance += dashWidth;
      if (distance > metrics.length) {
        distance = metrics.length;
      }

      final extractPath = metrics.extractPath(start, distance);
      canvas.drawPath(extractPath, paint);

      distance += dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
