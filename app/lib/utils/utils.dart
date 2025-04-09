import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sembast/sembast_io.dart';
import 'package:vocafusion/cubits/streak_cubit.dart';

double mapLinear(double value, double inputMin, double inputMax,
    double outputMin, double outputMax) {
  double clamped = value.clamp(inputMin, inputMax);

  // Check if the clamped value is finite
  if (!clamped.isFinite) {
    return outputMin; // Return the lower bound if the value is infinite or NaN
  }

  // Calculate the slope and intercept for the linear equation
  final slope = (outputMax - outputMin) / (inputMax - inputMin);
  final intercept = outputMin - slope * inputMin;

  // Apply the linear equation
  return slope * clamped + intercept;
}

/// A generic weighted random selection function that can work with any type.
///
/// Returns an item from [items] where the probability of selection is proportional
/// to its weight in [weights]. Both lists must be the same length.
///
/// - [items]: List of items to choose from
/// - [weights]: List of weights corresponding to each item
/// - [random]: Optional Random instance for testing or seed control
///
/// Example:
/// ```
/// final result = weightedRandomSelect(['A', 'B', 'C'], [0.7, 0.2, 0.1]);
/// ```
T weightedRandomSelect<T>(List<T> items, List<double> weights,
    {Random? random}) {
  assert(items.length == weights.length && items.isNotEmpty);

  // Use provided random or create a new one
  final r = random ?? Random();

  // Normalize weights
  final totalWeight = weights.reduce((a, b) => a + b);
  final normalizedWeights = weights.map((w) => w / totalWeight).toList();

  // Select based on cumulative probability
  final randomValue = r.nextDouble();
  double cumulativeWeight = 0.0;

  for (int i = 0; i < items.length; i++) {
    cumulativeWeight += normalizedWeights[i];
    if (randomValue <= cumulativeWeight) {
      return items[i];
    }
  }

  // In case of floating-point rounding issues, return the last item
  return items.last;
}

String dayInitalLetters(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return 'الاثنين';
    case DateTime.tuesday:
      return 'الثلاثاء';
    case DateTime.wednesday:
      return 'الأربعاء';
    case DateTime.thursday:
      return 'الخميس';
    case DateTime.friday:
      return 'الجمعة';
    case DateTime.saturday:
      return 'السبت';
    case DateTime.sunday:
      return 'الأحد';
    default:
      return '';
  }
}

Future<MapEntry<T, B>> waitForTwo<T, B>(Future<T> a, Future<B> b) async {
  final results = await Future.wait([a, b]);

  return MapEntry(results[0] as T, results[1] as B);
}

List<DateTime> preventDayDuplication(List<DateTime> days) {
  if (days.isEmpty) return [];

  final d = List<DateTime>.from(days);
  d.sort((a, b) => a.compareTo(b));

  final Map<String, DateTime> outputs = {};
  for (final e in d) {
    outputs["${e.month}-${e.day}-${e.year}"] = e;
  }

  return outputs.values.toList();
}

DateTime monthDayDeadline(DateTime date) {
  // todo what about deadline is 5/01 and today is 12/31
  final now = DateTime.now();
  final deadline = DateTime(now.year, date.month, date.day);

  return deadline;
}

/// Waits for a variable to meet a condition, checking every [interval] until [timeout].
///
/// - [getValue]: Function that returns the current value of the variable.
/// - [isFilled]: Predicate that checks if the value meets the desired condition.
/// - [timeout]: Maximum duration to wait before throwing a timeout.
/// - [interval]: Duration between checks (default: 1 second).
Future<T> waitForVariable<T>({
  required T? Function() getValue,
  required bool Function(T?) isFilled,
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(seconds: 1),
}) async {
  final startTime = DateTime.now();
  while (true) {
    final currentValue = getValue();
    if (isFilled(currentValue)) {
      return currentValue as T; // Safe cast as condition is met
    }
    if (DateTime.now().difference(startTime) > timeout) {
      throw TimeoutException('Timeout waiting for variable to be filled');
    }
    await Future.delayed(interval);
  }
}

class StreakHelper {
  /// Increments the card count and shows congrats if needed
  static void incrementCardCount(BuildContext context) {
    final streakCubit = context.read<StreakCubit>();
    streakCubit.incrementCardCount();
    streakCubit.showCongratsIfNeeded(context);
  }

  /// Gets the current daily progress (0.0 to 1.0)
  static double getDailyProgress(BuildContext context) {
    return context.read<StreakCubit>().getDailyProgress();
  }

  /// Gets the count of cards completed today
  static int getTodayCardCount(BuildContext context) {
    return context.read<StreakCubit>().getTodayCardCount();
  }

  /// Checks if the daily goal is completed
  static bool hasDailyGoalCompleted(BuildContext context) {
    return context.read<StreakCubit>().hasCompletedDailyGoal();
  }
}
