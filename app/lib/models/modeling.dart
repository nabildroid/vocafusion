class User {
  final String id;
  final String nativeLanguage;
  final String targetLanguage;
  final int level;
  final DateTime createdAt;
  final bool isPremium;

  User({
    required this.id,
    required this.nativeLanguage,
    required this.targetLanguage,
    required this.level,
    required this.createdAt,
    required this.isPremium,
  });
}

class Card {
  final String id;
  final String word;
  final String definition;
  final String previousCard;
  final String flowId;
  final String level;
  final String nativeLanguage;
  final String targetLanguage;
  final Map<int, String> intertwinedLanguages;
  final Map<int, String> intertwinedAloneLanguages;
  final Map<int, String> intertwinedPreviousSummary;
  final int estimatedReadingTimeMinutes;
  final DateTime updatedAt;

  // New fields
  final String nativeScript; // Word in native script
  final String targetScript; // Word in target script
  final String transliteration; // Transliteration to help pronunciation
  final String audioUrl; // Link to pronunciation audio

  Card({
    required this.intertwinedLanguages,
    required this.intertwinedAloneLanguages,
    required this.intertwinedPreviousSummary,
    required this.id,
    required this.word,
    required this.definition,
    required this.previousCard,
    required this.flowId,
    required this.level,
    required this.nativeLanguage,
    required this.targetLanguage,
    required this.estimatedReadingTimeMinutes,
    required this.updatedAt,
    required this.nativeScript,
    required this.targetScript,
    required this.transliteration,
    required this.audioUrl,
  });
}

class Quiz {
  final String id;
  final String cardId;
  final String type; // e.g., "fill-in-blank", "multiple-choice", etc.
  final Map<int, String> intertwineLanguages;

  // final int difficultyLevel;
  Quiz({
    required this.intertwineLanguages,
    required this.id,
    required this.cardId,
    required this.type,
  });
}

class Flow {
  final String id;
  final String language;
  final String level;
  final String title;

  Flow({
    required this.id,
    required this.language,
    required this.level,
    required this.title,
  });
}
