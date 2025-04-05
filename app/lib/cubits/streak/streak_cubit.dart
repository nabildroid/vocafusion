import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:vocafusion/screens/learning_screen/widgets/streak_congrats_sheet.dart';
import 'package:equatable/equatable.dart';

class StreakState extends Equatable {
  final int currentStreak;
  final Map<String, int> dailyProgress;
  final DateTime lastCompletionDate;
  final List<DateTime> streakMilestones;

  StreakState({
    this.currentStreak = 0,
    this.dailyProgress = const {},
    DateTime? lastCompletionDate,
    this.streakMilestones = const [],
  }) : lastCompletionDate = lastCompletionDate ?? DateTime(1970);

  bool get hasCompletedTodayGoal {
    final today = _dateOnly(DateTime.now());
    final dailyCount = dailyProgress[today] ?? 0;
    return dailyCount >= 20;
  }

  int get todayCount {
    final today = _dateOnly(DateTime.now());
    return dailyProgress[today] ?? 0;
  }

  static String _dateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  StreakState copyWith({
    int? currentStreak,
    Map<String, int>? dailyProgress,
    DateTime? lastCompletionDate,
    List<DateTime>? streakMilestones,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      streakMilestones: streakMilestones ?? this.streakMilestones,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'dailyProgress': dailyProgress,
      'lastCompletionDate': lastCompletionDate.toIso8601String(),
      'streakMilestones':
          streakMilestones.map((date) => date.toIso8601String()).toList(),
    };
  }

  factory StreakState.fromJson(Map<String, dynamic> json) {
    return StreakState(
      currentStreak: json['currentStreak'] as int,
      dailyProgress: Map<String, int>.from(json['dailyProgress'] as Map),
      lastCompletionDate: DateTime.parse(json['lastCompletionDate'] as String),
      streakMilestones: (json['streakMilestones'] as List)
          .map((dateStr) => DateTime.parse(dateStr as String))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [currentStreak, dailyProgress, lastCompletionDate, streakMilestones];
}

class StreakCubit extends HydratedCubit<StreakState> {
  StreakCubit() : super(StreakState());

  void incrementCardCount() {
    final today = _dateOnlyString(DateTime.now());
    final currentCount = state.dailyProgress[today] ?? 0;
    final newCount = currentCount + 1;

    final updatedProgress = Map<String, int>.from(state.dailyProgress);
    updatedProgress[today] = newCount;

    emit(state.copyWith(dailyProgress: updatedProgress));

    // Check if we've just reached the daily goal
    if (newCount == 20) {
      _updateStreak();
    }
  }

  void _updateStreak() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(
      state.lastCompletionDate.year,
      state.lastCompletionDate.month,
      state.lastCompletionDate.day,
    );

    // Check if this is a new day compared to the last completion
    if (lastDate.isBefore(todayDate)) {
      // Check if this is consecutive (lastDate was yesterday)
      final yesterday = todayDate.subtract(const Duration(days: 1));

      if (lastDate.isAtSameMomentAs(yesterday)) {
        // Consecutive day, increment streak
        final newStreak = state.currentStreak + 1;
        final milestones = List<DateTime>.from(state.streakMilestones);

        // Check if this is a milestone day
        if (_isMilestoneDay(newStreak)) {
          milestones.add(todayDate);
        }

        emit(state.copyWith(
          currentStreak: newStreak,
          lastCompletionDate: todayDate,
          streakMilestones: milestones,
        ));
      } else {
        // Non-consecutive day, reset streak to 1
        emit(state.copyWith(
          currentStreak: 1,
          lastCompletionDate: todayDate,
          streakMilestones: [todayDate],
        ));
      }
    }
  }

  bool _isMilestoneDay(int day) {
    return day == 1 ||
        day == 3 ||
        day == 7 ||
        day == 10 ||
        day == 14 ||
        day == 21 ||
        day == 30 ||
        day == 60 ||
        day == 90 ||
        day == 180 ||
        day == 365;
  }

  String _dateOnlyString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int getTodayCardCount() {
    return state.todayCount;
  }

  bool hasCompletedDailyGoal() {
    return state.hasCompletedTodayGoal;
  }

  double getDailyProgress() {
    final count = getTodayCardCount();
    return count / 20.0 > 1.0 ? 1.0 : count / 20.0;
  }

  void showCongratsIfNeeded(BuildContext context) {
    final today = _dateOnlyString(DateTime.now());
    final count = state.dailyProgress[today] ?? 0;

    // Show congrats only when exactly hitting 20
    if (count == 20) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StreakCongratsSheet(
          currentStreak: state.currentStreak,
          milestones: state.streakMilestones,
        ),
      );
    }
  }

  @override
  StreakState? fromJson(Map<String, dynamic> json) {
    return StreakState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(StreakState state) {
    return state.toJson();
  }
}
