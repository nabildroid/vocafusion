import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';
import 'package:vocafusion/utils/utils.dart';

// Learning item type enum
enum LearningItemType {
  learning,
  testCurrentFlow,
  testOtherFlow,
  feedbackCurrentFlow,
  feedbackOtherFlow,
}

// Learning item class
class LearningItem {
  final String id;
  final WordCard word;
  final String flowId;
  final LearningItemType type;

  LearningItem({
    required this.id,
    required this.word,
    required this.flowId,
    required this.type,
  });
}

// Learning session state
class LearningSessionState {
  final List<LearningItem> itemList; // Changed from Queue to List
  final String currentFlowId;
  final List<String> failedTests;
  final List<SREntry> words; // Add words from SrCubit

  const LearningSessionState({
    required this.itemList, // Changed from itemQueue to itemList
    required this.currentFlowId,
    required this.failedTests,
    required this.words,
  });

  LearningSessionState copyWith({
    List<LearningItem>? itemList, // Changed from itemQueue to itemList
    String? currentFlowId,
    List<String>? failedTests,
    List<SREntry>? words,
  }) {
    return LearningSessionState(
      itemList: itemList ?? this.itemList, // Changed from itemQueue to itemList
      currentFlowId: currentFlowId ?? this.currentFlowId,
      failedTests: failedTests ?? this.failedTests,
      words: words ?? this.words,
    );
  }
}

// Learning session cubit
class LearningSessionCubit extends HydratedCubit<LearningSessionState> {
  LearningSessionCubit()
      : super(LearningSessionState(
          itemList: [], // Changed from Queue to empty List
          currentFlowId: '',
          failedTests: [],
          words: [],
        ));

  @override
  Map<String, dynamic> toJson(LearningSessionState state) {
    return {
      'currentFlowId': state.currentFlowId,
    };
  }

  @override
  LearningSessionState fromJson(Map<String, dynamic> json) {
    return LearningSessionState(
      itemList: [],
      currentFlowId: json['currentFlowId'] as String? ?? '',
      failedTests: [],
      words: [],
    );
  }

  void setCurrentFlowId(String flowId) async {
    emit(state.copyWith(currentFlowId: flowId));
  }

  Future<void> loadData(
    List<SREntry> entries,
  ) async {
    // Get data from SrCubit

    // Update words in state
    emit(state.copyWith(words: entries));

    // If current flow is not established, pick the first one
    if (state.currentFlowId.isEmpty && entries.isNotEmpty) {
      setCurrentFlowId(entries.first.value.flowId);
    }

    // Process data if list is empty and we have a current flow
    if (state.itemList.isEmpty && state.currentFlowId.isNotEmpty) {
      await processData();
    }
  }

  Future<void> processData() async {
    if (state.currentFlowId.isEmpty || state.words.isEmpty) {
      return;
    }

    final random = Random();

    // Filter words by flow
    final currentFlowWords = state.words
        .where((word) => word.value.flowId == state.currentFlowId)
        .toList();
    final otherFlowWords = state.words
        .where((word) => word.value.flowId != state.currentFlowId)
        .toList();

    // remover the other flows that was never been touched, SR score (key) == 1
    final touchedFlows = otherFlowWords.fold(<String>{}, (acc, v) {
      if (v.key != 1) acc.add(v.value.flowId);
      return acc;
    });
    otherFlowWords
        .removeWhere((word) => !touchedFlows.contains(word.value.flowId));

    // Get the last learning item to determine the next word in order
    LearningItem? lastLearningItem;
    for (final item in state.itemList.reversed) {
      if (item.type == LearningItemType.learning) {
        lastLearningItem = item;
        break;
      }
    }

    // Find the next word for learning
    WordCard? nextLearningWord;
    if (lastLearningItem != null) {
      nextLearningWord = currentFlowWords
          .firstWhere((e) => e.value.previousCard == lastLearningItem!.word.id)
          .value;
    } else if (currentFlowWords.isNotEmpty) {
      // If no learning word in queue, start from the beginning
      nextLearningWord = currentFlowWords[0].value;
    }

    // Define the weights
    const double learningWeight = 0.7;
    const double testCurrentFlowWeight = 0.2;
    const double testOtherFlowWeight = 0.1;
    const double feedbackCurrentFlowWeight = .3;
    const double feedbackOtherFlowWeight = .4;

    // Create options and weights lists for weighted selection
    List<LearningItemType> options = [];
    List<double> weights = [];

    // Always add learning option if there's a next learning word
    if (nextLearningWord != null) {
      options.add(LearningItemType.learning);
      weights.add(learningWeight);
    }

    // Add currentFlow test options
    if (currentFlowWords.isNotEmpty) {
      final sawWords =
          state.itemList.any((e) => e.type == LearningItemType.learning);
      final previouslyTestedWords = currentFlowWords.any((e) => e.key != 1);
      if (sawWords || previouslyTestedWords) {
        options.add(LearningItemType.testCurrentFlow);
        weights.add(testCurrentFlowWeight);
      }
    }

    if (otherFlowWords.isNotEmpty) {
      final previouslyTested = otherFlowWords.any((e) => e.key != 1);
      if (previouslyTested) {
        options.add(LearningItemType.testOtherFlow);
        weights.add(testOtherFlowWeight);
      }
    }

    // Add feedback options only if there are failed tests
    List<String> currentFlowFailedTests = [];
    List<String> otherFlowFailedTests = [];

    for (final testId in state.failedTests) {
      final isCurrentFlow =
          currentFlowWords.any((word) => word.value.id == testId);
      if (isCurrentFlow) {
        currentFlowFailedTests.add(testId);
      } else {
        otherFlowFailedTests.add(testId);
      }
    }

    if (currentFlowFailedTests.isNotEmpty) {
      options.add(LearningItemType.feedbackCurrentFlow);
      weights.add(feedbackCurrentFlowWeight);
    }

    if (otherFlowFailedTests.isNotEmpty) {
      options.add(LearningItemType.feedbackOtherFlow);
      weights.add(feedbackOtherFlowWeight);
    }

    // Use the weightedRandomSelect utility to select an option
    LearningItemType? selectedType = options.isNotEmpty
        ? weightedRandomSelect(options, weights, random: random)
        : null;

    // Create a new item based on the selected type
    LearningItem? newItem;

    if (selectedType == LearningItemType.learning && nextLearningWord != null) {
      newItem = LearningItem(
        id: nextLearningWord.id,
        word: nextLearningWord,
        flowId: state.currentFlowId,
        type: LearningItemType.learning,
      );
    } else if (selectedType == LearningItemType.testCurrentFlow) {
      // Find word with the worst spaced repetition score (lowest key value indicates worse performance)
      // but also allow some exploration of other words

      // Create weights for selection based on SR scores (lower score = higher weight)
      List<SREntry> eligibleWords = List.from(currentFlowWords);
      List<double> selectionWeights = [];

      // Check which words were recently shown in the itemList (last 10 items)
      Set<String> recentlyShownWordIds = {};
      int recentItemCount = min(10, state.itemList.length);
      for (int i = state.itemList.length - 1;
          i >= state.itemList.length - recentItemCount && i >= 0;
          i--) {
        recentlyShownWordIds.add(state.itemList[i].id);
      }

      for (var wordEntry in eligibleWords) {
        double weight = wordEntry.key;

        // Boost weight for words with very low scores (needs more practice)
        if (wordEntry.key < 0.1) {
          weight *= 5;
        }

        // Reduce weight if word was never shown prevoisly
        if (!recentlyShownWordIds.contains(wordEntry.value.id)) {
          weight *= 0.5;
        }

        // Ensure weight is positive
        selectionWeights.add(max(0.1, weight));
      }

      // Select word based on weighted probability
      final selectedWordEntry =
          weightedRandomSelect(eligibleWords, selectionWeights, random: random);

      newItem = LearningItem(
        id: selectedWordEntry.value.id,
        word: selectedWordEntry.value,
        flowId: state.currentFlowId,
        type: LearningItemType.testCurrentFlow,
      );
    } else if (selectedType == LearningItemType.testOtherFlow) {
      final word = otherFlowWords[random.nextInt(otherFlowWords.length)];
      newItem = LearningItem(
        id: word.value.id,
        word: word.value,
        flowId: word.value.flowId,
        type: LearningItemType.testOtherFlow,
      );
    } else if (selectedType == LearningItemType.feedbackCurrentFlow) {
      final testId =
          currentFlowFailedTests[random.nextInt(currentFlowFailedTests.length)];
      final word = currentFlowWords.firstWhere((w) => w.value.id == testId);
      newItem = LearningItem(
        id: word.value.id,
        word: word.value,
        flowId: state.currentFlowId,
        type: LearningItemType.feedbackCurrentFlow,
      );
    } else if (selectedType == LearningItemType.feedbackOtherFlow) {
      final testId =
          otherFlowFailedTests[random.nextInt(otherFlowFailedTests.length)];
      final word = otherFlowWords.firstWhere((w) => w.value.id == testId);
      newItem = LearningItem(
        id: word.value.id,
        word: word.value,
        flowId: word.value.flowId,
        type: LearningItemType.feedbackOtherFlow,
      );
    }

    // Add the new item to the list if one was created
    if (newItem != null) {
      final updatedList = List<LearningItem>.from(state.itemList)..add(newItem);
      emit(state.copyWith(itemList: updatedList));
    }
  }

  int _getHourlySeed() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour)
        .millisecondsSinceEpoch;
  }

  void registerFailedTest(String testId) {
    if (!state.failedTests.contains(testId)) {
      final updatedFailedTests = List<String>.from(state.failedTests)
        ..add(testId);
      emit(state.copyWith(failedTests: updatedFailedTests));
    }
  }

  void removeFailedTest(String testId) {
    if (state.failedTests.contains(testId)) {
      final updatedFailedTests = List<String>.from(state.failedTests)
        ..remove(testId);
      emit(state.copyWith(failedTests: updatedFailedTests));
    }
  }
}

// Extension for sync and processing data
extension LearningSessionCubitSync on LearningSessionCubit {
  Future<void> sync(BuildContext context) async {
    context.read<SrCubit>().stream.listen((state) async {
      await loadData(state.entries);
    });
  }
}
