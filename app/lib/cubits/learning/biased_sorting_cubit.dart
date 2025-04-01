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
    final sorted = entries.map((e) => e.value).toList();

    emit(state.copyWith(sorted: sorted));
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
