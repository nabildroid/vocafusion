import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/auth_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/content_repository.dart';

class ContentState extends Equatable {
  final List<WordsFlow> flows;
  final List<WordCard> words;
  final List<Quiz> quizzes;

  ContentState({
    required this.flows,
    required this.words,
    required this.quizzes,
  });

  ContentState copyWith({
    List<WordsFlow>? flows,
    List<WordCard>? words,
    List<Quiz>? quizzes,
  }) {
    return ContentState(
      flows: flows ?? this.flows,
      words: words ?? this.words,
      quizzes: quizzes ?? this.quizzes,
    );
  }

  @override
  List<Object?> get props => [flows, words, quizzes];
}

class ContentCubit extends Cubit<ContentState> {
  ContentCubit()
      : super(ContentState(
          flows: [],
          words: [],
          quizzes: [],
        ));

  void loadRelevantData({
    List<WordsFlow>? flows,
    List<WordCard>? words,
    List<Quiz>? quizzes,
  }) {
    if (flows != null) {
      emit(state.copyWith(flows: flows));
    }

    if (quizzes != null) {
      // Use IDs to ensure no duplicates
      final quizzesMap = {for (var q in state.quizzes) q.id: q};
      for (var quiz in quizzes) {
        quizzesMap[quiz.id] =
            quiz; // New quizzes override old ones with same ID
      }
      emit(state.copyWith(quizzes: quizzesMap.values.toList()));
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

  Quiz? getQuiz(String id) {
    return state.quizzes.firstWhere((q) => q.id == id);
  }
}

extension FlashcardsPreselectionCubitExtention on ContentCubit {
  static final _listeners = CompositeSubscription();

  sync(BuildContext context) {
    final stream =
        context.read<AuthCubit>().stream.map((e) => e.user).distinct();

    final l = stream.listen((user) async {
      onUser(user!);
    });

    _listeners.add(l);
  }

  void onUser(User user) async {
    final repo = locator.get<ContentRepository>();
    final passedThrough = <String>{};

    repo
        .flows(FlowFilter(
            targetLanguage: user.targetLanguage,
            nativeLanguage: user.nativeLanguage))
        .listen((flows) {
      final news = flows.where((t) => passedThrough.add(t.id)).toList();

      loadRelevantData(flows: flows);

      final target = news.where((f) => f.level == user.level).firstOrNull;
      if (target == null) return;

      repo
          .words(target.id)
          .listen((data) => loadRelevantData(words: data))
          .addTo(_listeners);
      repo
          .quizzes(target.id)
          .listen((data) => loadRelevantData(quizzes: data))
          .addTo(_listeners);
    }).addTo(_listeners);
  }

  dispose() {
    _listeners.dispose();
  }
}
