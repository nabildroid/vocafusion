import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/progress_repository.dart';

class BiasedSortingState extends Equatable {
  final List<SREntry> entries;
  final List<WordCard> sorted;

  const BiasedSortingState({
    required this.entries,
    required this.sorted,
  });

  BiasedSortingState copyWith({
    List<SREntry>? entries,
    List<WordCard>? sorted,
  }) {
    return BiasedSortingState(
      entries: entries ?? this.entries,
      sorted: sorted ?? this.sorted,
    );
  }

  @override
  List<Object?> get props => [entries, sorted];
}

/// to try to stick to the word flow (story) as much as possible, so when possible, we ignore the spaced repetition score
class BiasedSortingCubit extends Cubit<BiasedSortingState> {
  BiasedSortingCubit()
      : super(
          BiasedSortingState(
            entries: [],
            sorted: [],
          ),
        );

  void loadData(List<SREntry> entries) {
    emit(state.copyWith(entries: entries));
    sort();
  }

  void sort() {
    final entries = state.entries;
    if (entries.isEmpty) {
      emit(state.copyWith(sorted: []));
      return;
    }

    // Create a map of cards by their ID for quick lookup
    final Map<String, WordCard> cardsById = {};
    final Map<String, SREntry> entriesById = {};
    for (var entry in entries) {
      cardsById[entry.value.id] = entry.value;
      entriesById[entry.value.id] = entry;
    }

    // Build a graph of card relationships (which card follows which)
    // Since we have previous pointers, we'll build a next map from them
    final Map<String, String> nextCardMap = {};
    for (var card in cardsById.values) {
      if (card.previousCard != null &&
          cardsById.containsKey(card.previousCard)) {
        // If A points to B as previous, then B points to A as next
        nextCardMap[card.previousCard!] = card.id;
      }
    }

    // Start with all cards and sort by SR priority (assuming lower score is higher priority)
    List<SREntry> prioritySorted = List.from(entries)
      ..sort((a, b) => a.key.compareTo(b.key));

    List<WordCard> result = [];
    Set<String> added = {};

    // Start with the highest priority card
    String? currentId = prioritySorted.first.value.id;
    result.add(cardsById[currentId]!);
    added.add(currentId);

    // Build the sequence trying to balance priority and flow
    while (added.length < entries.length) {
      // Check if there's a next card in the flow
      String? nextInFlow = nextCardMap[currentId];

      // Priority factor - how much we value SR score vs flow
      // Value between 0-1, higher means more weight to SR score
      double priorityFactor = 0.7;

      // If the next card in flow exists and we haven't added it yet
      if (nextInFlow != null && !added.contains(nextInFlow)) {
        // Calculate the priority rank of the next card
        int nextCardPriorityRank =
            prioritySorted.indexWhere((entry) => entry.value.id == nextInFlow);

        // If the next card is high priority (in top 30%) or random chance based on priorityFactor
        if (nextCardPriorityRank < entries.length * 0.3 ||
            (nextCardPriorityRank < entries.length * 0.6 &&
                _randomChance(priorityFactor))) {
          // Follow the flow
          currentId = nextInFlow;
          result.add(cardsById[currentId]!);
          added.add(currentId);
          continue;
        }
      }

      // Otherwise, pick the highest priority card we haven't added yet
      for (var entry in prioritySorted) {
        if (!added.contains(entry.value.id)) {
          currentId = entry.value.id;
          result.add(cardsById[currentId]!);
          added.add(currentId);
          break;
        }
      }
    }

    emit(state.copyWith(sorted: result));
  }

  // Helper method to introduce some randomness in decision making
  bool _randomChance(double probability) {
    return (DateTime.now().microsecondsSinceEpoch % 100) / 100 < probability;
  }
}

extension BiasedSortingCubitExtension on BiasedSortingCubit {
  static final _listeners = CompositeSubscription();

  sync(BuildContext context) async {
    final stream = context
        .read<SrCubit>()
        .stream
        .where((e) => e.entries.isNotEmpty)
        .throttleTime(Duration(seconds: 1));

    stream.listen((state) {
      loadData(state.entries);
    }).addTo(_listeners);
  }

  Future<void> close() async {
    await _listeners.cancel();
    return this.close();
  }
}
