import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vocafusion/cubits/learning/biased_sorting_cubit.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';
import 'package:vocafusion/cubits/streak/streak_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/screens/learning_screen/widgets/quiz_widget.dart';
import 'package:vocafusion/screens/learning_screen/widgets/widgets.dart';
import 'package:vocafusion/screens/learning_screen/widgets/word_card.dart';
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
    return Stack(
      children: [
        Scaffold(
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
                          final opacity =
                              pointer - 2 >= i && fadeout ? .0 : 1.0;

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

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: QuizWidget(
                              item: item,
                            ),
                          );
                        }),
                      );
                    },
                  );
                }),
              )),
          bottomNavigationBar: CustomNavigationBar(
            onFavoriteTap: () {
              context.go('/learn/favorites');
            },
          ),
        ),
      ],
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
        child: BlocBuilder<StreakCubit, StreakState>(
          builder: (context, state) {
            return CircleAvatar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${state.currentStreak}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  if (state.currentStreak > 0)
                    Icon(
                      Icons.local_fire_department,
                      size: 10,
                      color: Colors.orange,
                    ),
                ],
              ),
              backgroundColor: Colors.grey.shade200,
              radius: 8,
            );
          },
        ),
      ),
      title: FractionallySizedBox(
        widthFactor: 0.8,
        child: BlocBuilder<StreakCubit, StreakState>(
          builder: (context, state) {
            final streakCubit = context.read<StreakCubit>();
            final count = streakCubit.getTodayCardCount();
            final progress = streakCubit.getDailyProgress();
            final isCompleted = count >= 20;

            return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
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
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(80),
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(isCompleted
                            ? Colors.green
                            : Colors.blueGrey.shade800),
                      ),
                    ),
                  ],
                ));
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton.filledTonal(
          onPressed: () {
            // context.read<BiasedSortingCubit>().sort();
            context.read<StreakCubit>().incrementCardCount();
            context.read<StreakCubit>().showCongratsIfNeeded(context);
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
