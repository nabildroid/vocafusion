import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' hide Card;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fsrs/fsrs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/content_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/progress_repository.dart';

typedef SREntry = MapEntry<double, WordCard>;

/// final List of Flashcards that goes straight to the learner
class SRState extends Equatable {
  final List<WordCard> all;
  final List<SREntry> entries;

  const SRState({
    required this.entries,
    required this.all,
  });

  SRState copyWith({
    List<WordCard>? all,
    List<SREntry>? entries,
    int? index,
  }) {
    return SRState(
      all: all ?? this.all,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [all, entries];
}

class SrCubit extends Cubit<SRState> {
  SrCubit() : super(SRState(all: [], entries: []));
  final sr = SpaceRepetition();

  Future<void> init(List<WordCard> all) async {
    emit(state.copyWith(all: all));
    _refreshQueue();
  }

  void _refreshQueue() {
    final all = state.all;

    final entries = all.map((e) {
      // the higher the spaced repetition score the lower the priority
      final sigmoiedSR = 1 / (1 + sr.getCardScore(e.srID));

      final score = sigmoiedSR;

      return SREntry(score, e);
    }).toList();

    emit(state.copyWith(entries: entries));
  }

  recordQuizAnswer(
    WordCard word,
    bool answer, {
    bool? secondTry,
  }) {
    if (answer == false) {
      sr.recordRecall(word.srID, isIncorrect: true);
    } else {
      if (secondTry == true) {
        sr.recordRecall(
          word.srID,
          isHard: true,
        );
      } else {
        sr.recordRecall(
          word.srID,
          isGood: true,
        );
      }
    }

    _refreshQueue();
  }

  @override
  Future<void> close() async {
    await dispose();
    return super.close();
  }
}

class SpaceRepetition {
  SpaceRepetition();
  final sr = FSRS();
  final Map<String, Card> cards = {};

  init(List<MapEntry<String, dynamic>> cards) async {
    for (var card in cards) {
      this.cards[card.key] = Card.fromJson(card.value);
    }
  }

  void save(String id) {
    locator<ProgressRepository>().updateSR(
      MapEntry(id, cards[id]!.toJson()),
    );
  }

  void addCard(String id) {
    cards.addAll({
      id: Card(),
    });

    save(id);
  }

  double getCardScore(String id) {
    if (cards[id] == null) {
      addCard(id);
    }

    final card = cards[id]!;

    final rFactor = 1; // retrievability factor
    final sFactor = 1; // stability factor
    final dFactor = 1; // difficulty factor

    final r =
        card.getRetrievability(DateTime.now().add(Duration(days: 1))) ?? 0;

    final s = card.stability;
    final d = card.difficulty / 10;

    return r * rFactor + s * sFactor + d * dFactor;
  }

  void recordRecall(
    String id, {
    bool? isIncorrect,
    bool? isEasy,
    bool? isGood,
    bool? isHard,
  }) {
    final recall = sr.repeat(cards[id]!, DateTime.now());

    Rating rate = Rating.again;

    if (isIncorrect == true) rate = Rating.again;
    if (isEasy == true) rate = Rating.easy;
    if (isGood == true) rate = Rating.good;
    if (isHard == true) rate = Rating.hard;

    final newCard = recall[rate]!.card;

    cards[id] = newCard;

    save(id);
  }
}

extension FlashcardsQueueCubitExtention on SrCubit {
  static final _listeners = CompositeSubscription();

  sync(BuildContext context) {
    final srDataStream = locator.get<ProgressRepository>().spacedRepetition();
    final dataCubit = context.read<ContentCubit>();

    srDataStream.listen((value) async {
      sr.init(value);
      await Future.delayed(Duration(milliseconds: 100));
      init(dataCubit.state.words);
    }).addTo(_listeners);

    final dataCubitStream = dataCubit.stream.map((e) => e.words).distinct();
    dataCubitStream.listen((data) async {
      sr.init(srDataStream.value);
      await Future.delayed(Duration(milliseconds: 100));
      init(data);
    }).addTo(_listeners);
  }

  Future<void> dispose() async {
    await _listeners.dispose();
  }
}
