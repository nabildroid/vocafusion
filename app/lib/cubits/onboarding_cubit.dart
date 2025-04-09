import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/content_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/content_repository.dart';
import 'package:vocafusion/utils/utils.dart';

class OnboardingState extends Equatable {
  final String? nativeLanguage;
  final String? targetLanguage;
  final int? languageLevel;
  final String? age;
  final String? gender;
  final String? selectedTopic;
  final List<WordsFlow>? filtredFlows;
  final List<WordsFlow>? allFlows;

  const OnboardingState({
    this.nativeLanguage,
    this.targetLanguage,
    this.languageLevel,
    this.age,
    this.gender,
    this.selectedTopic,
    this.filtredFlows,
    this.allFlows,
  });

  OnboardingState copyWith({
    String? identifyAs,
    String? grade,
    List<String>? focusOn,
    int? desiredDuration,
    bool? skipLearning,
    String? nativeLanguage,
    String? targetLanguage,
    int? languageLevel,
    String? age,
    String? gender,
    String? selectedTopic,
    List<WordsFlow>? filtredFlows,
    List<WordsFlow>? allFlows,
  }) {
    return OnboardingState(
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      languageLevel: languageLevel ?? this.languageLevel,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      selectedTopic: selectedTopic ?? this.selectedTopic,
      filtredFlows: filtredFlows ?? this.filtredFlows,
      allFlows: allFlows ?? this.allFlows,
    );
  }

  @override
  List<Object?> get props => [
        nativeLanguage,
        targetLanguage,
        languageLevel,
        age,
        gender,
        selectedTopic,
        filtredFlows,
        allFlows,
      ];
}

class OnboardingCubit extends HydratedCubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingState());

  // New methods for onboarding screen
  void setNativeLanguage(String language) {
    emit(state.copyWith(nativeLanguage: language));
  }

  void setTargetLanguage(String language) {
    emit(state.copyWith(targetLanguage: language));

    final filter = FlowFilter(
        targetLanguage: language, nativeLanguage: state.nativeLanguage ?? "");

    locator.get<ContentRepository>().getFlowsByFilters(filter).then((flows) {
      if (state.targetLanguage != language) return;
      final topLevelFlows =
          flows.where((flow) => flow.parentFlow == null).toList();

      emit(state.copyWith(allFlows: topLevelFlows));
    });
  }

  void setLanguageLevel(int level) {
    emit(state.copyWith(languageLevel: level));

    // by hear, we can register the user!
  }

  void setAge(String age) {
    emit(state.copyWith(age: age));
  }

  void setGender(String gender) {
    emit(state.copyWith(gender: gender));
  }

  @override
  void onChange(Change<OnboardingState> change) {
    super.onChange(change);

    final isReadyToFilterFlows = change.nextState.age != null &&
        change.nextState.allFlows != null &&
        change.nextState.languageLevel != null &&
        change.nextState.gender != null;

    final isNothingChanged = change.currentState.age == change.nextState.age &&
        change.currentState.languageLevel == change.nextState.languageLevel &&
        change.currentState.allFlows == change.nextState.allFlows &&
        change.currentState.gender == change.nextState.gender;
    if (isNothingChanged) return;

    if (isReadyToFilterFlows) {
      final flows = List<WordsFlow>.from(change.nextState.allFlows!);
      flows.removeWhere((e) => e.level != change.nextState.languageLevel);

      flows.sort(
        (a, b) => a.suggestor
            .score(
                ageGroup: change.nextState.age!,
                gender: change.nextState.gender!)
            .compareTo(b.suggestor.score(
                ageGroup: change.nextState.age!,
                gender: change.nextState.gender!)),
      );

      Future.delayed(Duration(milliseconds: 100), () {
        emit(
          state.copyWith(filtredFlows: flows.sublist(0, min(10, flows.length))),
        );
      });
    }
  }

  void setSelectedRootFlow(WordsFlow rootFlow) {
    emit(state.copyWith(selectedTopic: rootFlow.id));

    // Load subflows of the selected root flow
    final contentRepository = locator.get<ContentRepository>();
    contentRepository.getFlowsByParentFlowId(rootFlow.id).then((subFlows) {
      final contentCubit = locator.get<ContentCubit>();
      contentCubit.loadRelevantData(flows: subFlows);
    });
  }

  void setSelectedTopic(String topic) {
    emit(state.copyWith(selectedTopic: topic));
  }

  @override
  OnboardingState? fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      nativeLanguage: json["nativeLanguage"],
      targetLanguage: json["targetLanguage"],
      languageLevel: json["languageLevel"],
      age: json["age"],
      gender: json["gender"],
      selectedTopic: json["selectedTopic"],
    );
  }

  @override
  Map<String, dynamic>? toJson(OnboardingState state) {
    return {
      "nativeLanguage": state.nativeLanguage,
      "targetLanguage": state.targetLanguage,
      "languageLevel": state.languageLevel,
      "age": state.age,
      "gender": state.gender,
      "selectedTopic": state.selectedTopic,
    };
  }
}
