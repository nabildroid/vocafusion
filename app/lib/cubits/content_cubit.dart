import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/auth_cubit.dart';
import 'package:vocafusion/cubits/learning/learning_session_cubit.dart';
import 'package:vocafusion/cubits/onboarding_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/content_repository.dart';
import 'package:vocafusion/utils/utils.dart';

class ContentState extends Equatable {
  final List<WordsFlow> flows;
  final List<WordCard> words;

  ContentState({
    required this.flows,
    required this.words,
  });

  ContentState copyWith({
    List<WordsFlow>? flows,
    List<WordCard>? words,
  }) {
    return ContentState(
      flows: flows ?? this.flows,
      words: words ?? this.words,
    );
  }

  @override
  List<Object?> get props => [flows, words];
}

class ContentCubit extends Cubit<ContentState> {
  ContentCubit()
      : super(ContentState(
          flows: [],
          words: [],
        ));

  void loadRelevantData({
    List<WordsFlow>? flows,
    List<WordCard>? words,
  }) {
    if (flows != null) {
      emit(state.copyWith(flows: flows));
    }

    if (words != null) {
      // Use IDs to ensure no duplicates
      final cardsMap = {for (var card in state.words) card.id: card};
      for (var card in words) {
        cardsMap[card.id] = card; // New cards override old ones with same ID
      }
      emit(state.copyWith(words: cardsMap.values.toList()));
    }
  }
}

extension FlashcardsPreselectionCubitExtention on ContentCubit {
  sync(BuildContext context) async {
    final repo = locator.get<ContentRepository>();

    final rootFlow = context.read<OnboardingCubit>().state.selectedTopic;
    if (rootFlow == null) return;

    final allflows = await waitForTwo(
        repo.getFlowsById(rootFlow), repo.getFlowsByParentFlowId(rootFlow));

    final ids = allflows.value.map((e) => e.id).toList()..add(rootFlow);
    final words = await Future.wait(ids.map((id) => repo.getWordsByFlowId(id)));

    loadRelevantData(
      words: words.expand((element) => element).toList(),
      flows: [allflows.key, ...allflows.value],
    );
  }
}
