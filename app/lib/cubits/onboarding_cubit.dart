import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:vocafusion/utils/utils.dart';

class OnboardingState extends Equatable {
  final String? identifyAs;
  final String? grade;
  final List<String> focusOn;
  final int desiredDuration;

  final bool skipLearning;

  const OnboardingState({
    this.identifyAs,
    this.grade,
    this.focusOn = const [],
    this.desiredDuration = 5,
    this.skipLearning = false,
  });

  OnboardingState copyWith({
    String? identifyAs,
    String? grade,
    List<String>? focusOn,
    int? desiredDuration,
    bool? skipLearning,
  }) {
    return OnboardingState(
      identifyAs: identifyAs ?? this.identifyAs,
      grade: grade ?? this.grade,
      focusOn: focusOn ?? this.focusOn,
      desiredDuration: desiredDuration ?? this.desiredDuration,
      skipLearning: skipLearning ?? this.skipLearning,
    );
  }

  @override
  List<Object?> get props =>
      [identifyAs, grade, focusOn, desiredDuration, skipLearning];
}

class OnboardingCubit extends HydratedCubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingState());

  void identifyAs(String identifyAs) {
    emit(state.copyWith(identifyAs: identifyAs));
  }

  int _currentI = 0;
  void grade(String grade) async {
    emit(state.copyWith(grade: grade));

    final seenI = ++_currentI;
    if (seenI != _currentI) return;
  }

  void desiredDuration(int desiredDuration) {
    emit(state.copyWith(desiredDuration: desiredDuration));
  }

  void toggleFocusOn(
    String focusOn, {
    required BuildContext context,
  }) async {
    final focusOns = List<String>.from(state.focusOn);
    if (focusOns.contains(focusOn)) {
      focusOns.remove(focusOn);
    } else {
      focusOns.add(focusOn);
    }
    emit(state.copyWith(focusOn: focusOns));

    try {
      await prepareForLearning(context);
      emit(state.copyWith(skipLearning: false));
    } catch (e) {
      emit(state.copyWith(skipLearning: true));
    }
  }

  @override
  OnboardingState? fromJson(Map<String, dynamic> json) {
    // return OnboardingState(
    //   identifyAs: json["identifyAs"],
    //   grade: json["grade"],
    //   focusOn: List<String>.from(json["focusOn"]),
    // );
  }

  @override
  Map<String, dynamic>? toJson(OnboardingState state) {
    return {
      "identifyAs": state.identifyAs,
      "grade": state.grade,
      "focusOn": state.focusOn,
    };
  }
}

extension on OnboardingCubit {
  Future<void> prepareForLearning(BuildContext context) async {}
}
