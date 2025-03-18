import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

abstract class AudioEffectsService {
  static final _player = AudioPlayer();

  static void learningContinue() async {
    await _player.play(AssetSource('sounds/lightweight-choice.mp3'));
  }

  static void answerCorrect() async {
    (await _player.play(AssetSource('sounds/correct.mp3')));
  }

  static void answerInCorrect() async {
    (await _player.play(AssetSource('sounds/incorrect.mp3')));
  }

  static void sessionSuccess() async {
    (await _player.play(AssetSource('sounds/endstate.mp3')));
  }

  static void sessionStart() async {
    (await _player.play(AssetSource('sounds/start-lesson.mp3')));
  }
}
