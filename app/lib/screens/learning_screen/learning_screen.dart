import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vocafusion/cubits/auth_cubit.dart';
import 'package:vocafusion/cubits/content_cubit.dart';
import 'package:vocafusion/cubits/learning/learning_session_cubit.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';
import 'package:vocafusion/cubits/streak_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/screens/learning_screen/widgets/branching_path.dart';
import 'package:vocafusion/screens/learning_screen/widgets/flashback_widgets.dart';
import 'package:vocafusion/screens/learning_screen/widgets/quiz_widget.dart';
import 'package:vocafusion/screens/learning_screen/widgets/widgets.dart';
import 'package:vocafusion/screens/learning_screen/widgets/word_card.dart';
import 'package:vocafusion/screens/premium_screen.dart';
import 'package:vocafusion/utils/utils.dart';

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

  LearningItem? get currentItem {
    return context.read<LearningSessionCubit>().state.itemList.lastOrNull;
  }

  bool get isCurrentTest {
    return currentItem?.type == LearningItemType.testCurrentFlow ||
        currentItem?.type == LearningItemType.testOtherFlow;
  }

  final isQuizAnswerCorrect = ValueNotifier<bool?>(null);
  final userQuizAnswer = <int>[];
  final showQuizAnswer = <int>[];

  bool showGoodFeedback = false;
  bool showFailureFeedback = false;

  bool get isCurrentFlashback {
    return currentItem?.type == LearningItemType.feedbackCurrentFlow ||
        currentItem?.type == LearningItemType.feedbackOtherFlow;
  }

  @override
  void initState() {
    super.initState();

    itemPositionsListener.itemPositions
        .addListener(listenToItemPositionChanges);

    context.read<ContentCubit>().sync(context);

    reactToStateChanges(context.read<LearningSessionCubit>().state);
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
        offset: 20, duration: Duration(milliseconds: 10));

    setState(() {});
  }

  void next() async {
    final response = await context.read<LearningSessionCubit>().processData();
    if (response == false) return;

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

    context.read<StreakCubit>().incrementCardCount();
    context.read<StreakCubit>().showCongratsIfNeeded(context);
  }

  List<WordCard> forLearning = [];

  void reactToStateChanges(LearningSessionState state) {
    setState(() {
      forLearning = state.words.map((e) => e.value).toList();
      pointer = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: CustomAppBar(),
          body: BlocListener<LearningSessionCubit, LearningSessionState>(
            listenWhen: (p, c) {
              return p.words.length != c.words.length;
            },
            listener: (context, state) => reactToStateChanges(state),
            child: LayoutBuilder(builder: (context, c) {
              return ScrollablePositionedList.builder(
                padding: EdgeInsets.only(top: 42),
                itemCount: pointer,
                itemScrollController: learningController,
                scrollOffsetController: scrollOffsetController,
                itemPositionsListener: itemPositionsListener,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, i) {
                  return ValueListenableBuilder(
                    valueListenable: fadeoutOldCards,
                    builder: (context, fadeout, child) {
                      final opacity = pointer - 2 >= i && fadeout ? .0 : 1.0;

                      return AnimToFillViewForScrolling(
                        debug: false,
                        opacity: opacity,
                        maxHeight: c.maxHeight * minScreenFlashcard,
                        isFilled: i != 0 && pointer - 1 == i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: child!,
                        ),
                      );
                    },
                    child: Builder(builder: (ctx) {
                      final item = context
                          .read<LearningSessionCubit>()
                          .state
                          .itemList
                          .elementAtOrNull(i);

                      if (item == null) return SizedBox.shrink();

                      // Switch based on item type
                      switch (item.type) {
                        case LearningItemType.testOtherFlow:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: QuizWidget(
                              answerNotifier: isQuizAnswerCorrect,
                              item: item.word,
                              showIsCorrect: userQuizAnswer.contains(i),
                              showCorrectAnswer: showQuizAnswer.contains(i),
                            ),
                          );
                        case LearningItemType.testCurrentFlow:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: QuizWidget(
                              answerNotifier: isQuizAnswerCorrect,
                              item: item.word,
                              showIsCorrect: userQuizAnswer.contains(i),
                              showCorrectAnswer: showQuizAnswer.contains(i),
                            ),
                          );
                        case LearningItemType.learning:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: CardWidget(
                              item: item.word,
                            ),
                          );
                        case LearningItemType.feedbackCurrentFlow:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: FlashbackWidget(
                              item: item.word,
                            ),
                          );
                        case LearningItemType.feedbackOtherFlow:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: FlashbackWidget(
                              item: item.word,
                            ),
                          );
                      }
                    }),
                  );
                },
              );
            }),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButtonAnimator:
              FloatingActionButtonAnimator.noAnimation,
          floatingActionButton: ValueListenableBuilder(
              valueListenable: isQuizAnswerCorrect,
              builder: (_, isTestCorrect, __) {
                return ValueListenableBuilder(
                    valueListenable: floatingButtonActive,
                    builder: (context, isActive, _) {
                      return FloatingCheckingButton(
                        label: isCurrentTest ? "Check Answer" : "Next",
                        checkIfActive: () {
                          if (isCurrentTest) {
                            return isTestCorrect != null;
                          }
                          return true;
                        },
                        checkIfVisible: () {
                          if (showGoodFeedback || showFailureFeedback) {
                            return false;
                          }
                          return isActive;
                        },
                        onPressed: () async {
                          if (isCurrentTest) {
                            userQuizAnswer.add(pointer - 1);
                            setState(() {
                              showGoodFeedback = isTestCorrect!;
                              showFailureFeedback = !isTestCorrect;
                              if (isTestCorrect) {
                                showQuizAnswer.add(pointer - 1);
                              }
                            });
                            return;
                          }
                          next();
                        },
                      );
                    });
              }),
          bottomNavigationBar: CustomNavigationBar(
            onFavoriteTap: () {
              context.go('/learn/favorites');
            },
          ),
        ),
        BlocBuilder<LearningSessionCubit, LearningSessionState>(
          buildWhen: (p, c) {
            return p.needBranching != c.needBranching;
          },
          builder: (context, state) {
            if (state.needBranching != true) return SizedBox.shrink();
            return FlowBranching(
              onFlowSelected: next,
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSlide(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInExpo,
            offset: showGoodFeedback == true ? Offset(0, 0) : Offset(0, 1),
            child: LimitedBox(
              child: Material(
                child: QuizSuccessFeedback(
                  isVisible: showGoodFeedback == true,
                  onOkPressed: () {
                    next();
                    isQuizAnswerCorrect.value = null;
                    showGoodFeedback = false;
                  },
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSlide(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInExpo,
            offset: showFailureFeedback == true ? Offset(0, 0) : Offset(0, 1),
            child: LimitedBox(
              child: Material(
                child: QuizFailureFeedback(
                  isVisible: showFailureFeedback == true,
                  onSeePressed: () {
                    print("see");
                    setState(() {
                      showQuizAnswer.add(pointer - 1);
                      isQuizAnswerCorrect.value = null;
                      showFailureFeedback = false;
                    });

                    Future.delayed(Duration(milliseconds: 1500), () {
                      next();
                    });
                  },
                  onTryPressed: () {
                    print("");
                    setState(() {
                      showFailureFeedback = false;
                      showQuizAnswer.remove(pointer - 1);
                      userQuizAnswer.remove(pointer - 1);
                      isQuizAnswerCorrect.value = null;
                    });
                  },
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class FloatingCheckingButton extends StatefulWidget {
  final bool Function() checkIfVisible;
  final Future<void> Function() onPressed;
  final bool Function()? checkIfActive;
  final String label;

  FloatingCheckingButton({
    super.key,
    required this.checkIfVisible,
    required this.onPressed,
    this.checkIfActive,
    this.label = "Next",
  });

  @override
  State<FloatingCheckingButton> createState() => _FloatingCheckingButtonState();
}

class _FloatingCheckingButtonState extends State<FloatingCheckingButton> {
  bool stillProcessingClick = false;

  void onPressed() async {
    if (stillProcessingClick) return;
    stillProcessingClick = true;
    await widget.onPressed();

    await Future.delayed(Duration(milliseconds: 1500));
    stillProcessingClick = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.checkIfVisible()) {
      return const SizedBox.shrink();
    }

    final isActive = widget.checkIfActive == null || widget.checkIfActive!();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20),
      height: 42,
      child: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: isActive ? Colors.black : Colors.grey.shade300,
        foregroundColor: isActive ? Colors.white : Colors.grey.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(
            color: isActive ? Colors.black : Colors.white,
            width: 1,
          ),
        ),
        onPressed: isActive ? onPressed : null,
        label: Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      leading: BlocBuilder<StreakCubit, StreakState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(children: [StreakBadge()]),
          );
        },
      ),
      leadingWidth: 80,
      title: FractionallySizedBox(
        widthFactor: 0.8,
        child: BlocBuilder<StreakCubit, StreakState>(
          builder: (context, state) {
            final streakCubit = context.read<StreakCubit>();
            final count = streakCubit.getTodayCardCount();
            final progress = streakCubit.getDailyProgress();
            final isCompleted = count >= 20;

            return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$count/20",
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted
                              ? Colors.green
                              : Colors.blueGrey.shade800,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 4),
                    Expanded(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(isCompleted
                                    ? Colors.green
                                    : Colors.blueGrey.shade800),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ))),
                  ],
                ));
          },
        ),
      ),
      actions: [
        Builder(builder: (context) {
          final isPro =
              context.watch<AuthCubit>().state.user?.claims.isTrulyPremium ==
                  true;
          return IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor:
                  isPro ? Theme.of(context).primaryColor : Colors.grey.shade200,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PremiumScreen(),
                ),
              );
            },
            icon: Icon(Icons.diamond_outlined),
          );
        }),
        SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final today = context.read<StreakCubit>().getTodayCardCount();
    final streak = context.read<StreakCubit>().state.currentStreak;

    final isTodayWin = today > 19;

    if (!isTodayWin) {
      return IconButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          visualDensity: VisualDensity.compact,
          backgroundBuilder: (context, states, child) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ).add(Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                )),
              ),
              child: child),
        ),
        icon: Row(
          children: [
            if (streak > 0) ...[
              SizedBox(width: 1),
              Text(
                streak.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(width: 1),
            ],
            Icon(
              Icons.celebration_outlined,
              color: Colors.grey.shade300,
              size: 24,
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () {},
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
      label: Row(
        children: [
          SizedBox(width: 2),
          Text(
            streak.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 2),
          Icon(
            Icons.celebration_outlined,
            size: 21,
          ),
        ],
      ),
    );
  }
}
