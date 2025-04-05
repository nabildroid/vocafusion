import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';

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
  final List<WordCard> words; // Add words from SrCubit

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
    List<WordCard>? words,
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
class LearningSessionCubit extends Cubit<LearningSessionState> {
  LearningSessionCubit()
      : super(LearningSessionState(
          itemList: [], // Changed from Queue to empty List
          currentFlowId: '',
          failedTests: [],
          words: [],
        ));

  void setCurrentFlowId(String flowId) async {
    emit(state.copyWith(currentFlowId: flowId));
  }

  Future<void> loadData(
    List<SREntry> entries,
  ) async {
    // Get data from SrCubit

    final words = entries.map((e) => e.value).toList();

    // Update words in state
    emit(state.copyWith(words: words));

    // If current flow is not established, pick the first one
    if (state.currentFlowId.isEmpty && words.isNotEmpty) {
      setCurrentFlowId(words.first.flowId);
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

    final random = Random(_getHourlySeed());

    // Filter words by flow
    final currentFlowWords = state.words
        .where((word) => word.flowId == state.currentFlowId)
        .toList();
    final otherFlowWords = state.words
        .where((word) => word.flowId != state.currentFlowId)
        .toList();

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
      // Find the word that comes after the last learning word
      final index = currentFlowWords
          .indexWhere((word) => word.id == lastLearningItem?.id);
      if (index != -1 && index < currentFlowWords.length - 1) {
        nextLearningWord = currentFlowWords[index + 1];
      }
    } else if (currentFlowWords.isNotEmpty) {
      // If no learning word in queue, start from the beginning
      nextLearningWord = currentFlowWords[0];
    }

    // Define the weights
    const double learningWeight = 0.7;
    const double testCurrentFlowWeight = 0.1;
    const double testOtherFlowWeight = 0.2;
    const double feedbackCurrentFlowWeight = 0.2;
    const double feedbackOtherFlowWeight = 0.3;

    // Create a list of options with their weights
    List<MapEntry<LearningItemType, double>> options = [];

    // Always add learning option if there's a next learning word
    if (nextLearningWord != null) {
      options.add(MapEntry(LearningItemType.learning, learningWeight));
    }

    // Add test options
    if (currentFlowWords.isNotEmpty) {
      options.add(
          MapEntry(LearningItemType.testCurrentFlow, testCurrentFlowWeight));
    }

    if (otherFlowWords.isNotEmpty) {
      options
          .add(MapEntry(LearningItemType.testOtherFlow, testOtherFlowWeight));
    }

    // Add feedback options only if there are failed tests
    List<String> currentFlowFailedTests = [];
    List<String> otherFlowFailedTests = [];

    for (final testId in state.failedTests) {
      final isCurrentFlow = currentFlowWords.any((word) => word.id == testId);
      if (isCurrentFlow) {
        currentFlowFailedTests.add(testId);
      } else {
        otherFlowFailedTests.add(testId);
      }
    }

    if (currentFlowFailedTests.isNotEmpty) {
      options.add(MapEntry(
          LearningItemType.feedbackCurrentFlow, feedbackCurrentFlowWeight));
    }

    if (otherFlowFailedTests.isNotEmpty) {
      options.add(MapEntry(
          LearningItemType.feedbackOtherFlow, feedbackOtherFlowWeight));
    }

    // Normalize weights
    double totalWeight = options.fold(0.0, (sum, option) => sum + option.value);
    final normalizedOptions = options
        .map((option) => MapEntry(option.key, option.value / totalWeight))
        .toList();

    // Select an option based on weighted random
    double randomValue = random.nextDouble();
    double cumulativeWeight = 0.0;
    LearningItemType? selectedType;

    for (final option in normalizedOptions) {
      cumulativeWeight += option.value;
      if (randomValue <= cumulativeWeight) {
        selectedType = option.key;
        break;
      }
    }

    // Create a new item based on the selected type
    LearningItem? newItem;

    if (selectedType == LearningItemType.learning && nextLearningWord != null) {
      newItem = LearningItem(
        id: nextLearningWord.id,
        word: nextLearningWord, // Fix: use content instead of id for word
        flowId: state.currentFlowId,
        type: LearningItemType.learning,
      );
    } else if (selectedType == LearningItemType.testCurrentFlow) {
      final word = currentFlowWords[random.nextInt(currentFlowWords.length)];
      newItem = LearningItem(
        id: word.id,
        word: word,
        flowId: state.currentFlowId,
        type: LearningItemType.testCurrentFlow,
      );
    } else if (selectedType == LearningItemType.testOtherFlow) {
      final word = otherFlowWords[random.nextInt(otherFlowWords.length)];
      newItem = LearningItem(
        id: word.id,
        word: word,
        flowId: word.flowId,
        type: LearningItemType.testOtherFlow,
      );
    } else if (selectedType == LearningItemType.feedbackCurrentFlow) {
      final testId =
          currentFlowFailedTests[random.nextInt(currentFlowFailedTests.length)];
      final word = currentFlowWords.firstWhere((w) => w.id == testId);
      newItem = LearningItem(
        id: word.id,
        word: word,
        flowId: state.currentFlowId,
        type: LearningItemType.feedbackCurrentFlow,
      );
    } else if (selectedType == LearningItemType.feedbackOtherFlow) {
      final testId =
          otherFlowFailedTests[random.nextInt(otherFlowFailedTests.length)];
      final word = otherFlowWords.firstWhere((w) => w.id == testId);
      newItem = LearningItem(
        id: word.id,
        word: word,
        flowId: word.flowId,
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
}

// Extension for sync and processing data
extension LearningSessionCubitSync on LearningSessionCubit {
  Future<void> sync(BuildContext context) async {
    context.read<SrCubit>().stream.listen((state) async {
      await loadData(state.entries);
    });
  }
}
