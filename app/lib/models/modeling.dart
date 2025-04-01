class User {
  final String uid;
  final String nativeLanguage;
  final String targetLanguage;
  final int level;
  final DateTime createdAt;
  final bool isPremium;

  User({
    required this.uid,
    required this.nativeLanguage,
    required this.targetLanguage,
    required this.level,
    required this.createdAt,
    required this.isPremium,
  });

  // from json
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      nativeLanguage: json['nativeLanguage'],
      targetLanguage: json['targetLanguage'],
      level: json['level'],
      createdAt: DateTime.parse(json['createdAt']),
      isPremium: json['isPremium'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nativeLanguage': nativeLanguage,
      'targetLanguage': targetLanguage,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'isPremium': isPremium,
    };
  }
}

class WordCard {
  final String id;
  final String word;
  final String definition;
  final String previousCard;
  final String flowId;
  final String level;
  final String nativeLanguage;
  final String targetLanguage;
  final Map<String, String> intertwinedLanguages; // the story
  final Map<String, String>
      intertwinedAloneLanguages; // standalone context for the word
  final Map<String, String>
      intertwinedPreviousSummary; // summary of the all the previous cards
  final int estimatedReadingTimeMinutes;
  final DateTime updatedAt;

  // New fields
  final String nativeScript; // Word in native script
  final String targetScript; // Word in target script
  final String transliteration; // Transliteration to help pronunciation
  final String audioUrl; // Link to pronunciation audio

  WordCard({
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

  //to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'previousCard': previousCard,
      'flowId': flowId,
      'level': level,
      'nativeLanguage': nativeLanguage,
      'targetLanguage': targetLanguage,
      'intertwinedLanguages': intertwinedLanguages,
      'intertwinedAloneLanguages': intertwinedAloneLanguages,
      'intertwinedPreviousSummary': intertwinedPreviousSummary,
      'estimatedReadingTimeMinutes': estimatedReadingTimeMinutes,
      'updatedAt': updatedAt.toIso8601String(),
      'nativeScript': nativeScript,
      'targetScript': targetScript,
      'transliteration': transliteration,
      'audioUrl': audioUrl,
    };
  }

  // from json
  factory WordCard.fromJson(Map<String, dynamic> json) {
    return WordCard(
      id: json['id'],
      word: json['word'],
      definition: json['definition'],
      previousCard: json['previousCard'],
      flowId: json['flowId'],
      level: json['level'],
      nativeLanguage: json['nativeLanguage'],
      targetLanguage: json['targetLanguage'],
      intertwinedLanguages: Map.from(json['intertwinedLanguages']),
      intertwinedAloneLanguages: Map.from(json['intertwinedAloneLanguages']),
      intertwinedPreviousSummary: Map.from(json['intertwinedPreviousSummary']),
      estimatedReadingTimeMinutes: json['estimatedReadingTimeMinutes'],
      updatedAt: DateTime.parse(json['updatedAt']),
      nativeScript: json['nativeScript'],
      targetScript: json['targetScript'],
      transliteration: json['transliteration'],
      audioUrl: json['audioUrl'],
    );
  }
}

final DummyCards = <WordCard>[
  WordCard(
    id: '1',
    word: 'crayon',
    definition: 'pencil',
    previousCard: '',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard": 'Je viens d\'acheter un nouveau crayon à la papeterie.'
    },
    intertwinedAloneLanguages: {"hard": 'crayon'},
    intertwinedPreviousSummary: {"hard": 'Our story begins with a new pencil'},
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'pencil',
    targetScript: 'crayon',
    transliteration: 'kray-ohn',
    audioUrl: 'https://audio.com/crayon.mp3',
  ),
  WordCard(
    id: '2',
    word: 'écrire',
    definition: 'to write',
    previousCard: '1',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard": 'Marie utilise le crayon pour écrire ses devoirs tous les jours.'
    },
    intertwinedAloneLanguages: {"hard": 'écrire'},
    intertwinedPreviousSummary: {
      "hard": 'A student uses the pencil for homework'
    },
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'to write',
    targetScript: 'écrire',
    transliteration: 'ay-kreer',
    audioUrl: 'https://audio.com/ecrire.mp3',
  ),
  WordCard(
    id: '3',
    word: 'papier',
    definition: 'paper',
    previousCard: '2',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard": 'Le crayon glisse facilement sur le papier blanc.'
    },
    intertwinedAloneLanguages: {"hard": 'papier'},
    intertwinedPreviousSummary: {"hard": 'The pencil writes smoothly on paper'},
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'paper',
    targetScript: 'papier',
    transliteration: 'pap-yay',
    audioUrl: 'https://audio.com/papier.mp3',
  ),
  WordCard(
    id: '4',
    word: 'bureau',
    definition: 'desk/office',
    previousCard: '3',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard": 'Marie oublie le crayon sur son bureau à l\'école.'
    },
    intertwinedAloneLanguages: {"hard": 'bureau'},
    intertwinedPreviousSummary: {"hard": 'The pencil is left on a desk'},
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'desk',
    targetScript: 'bureau',
    transliteration: 'bur-oh',
    audioUrl: 'https://audio.com/bureau.mp3',
  ),
  WordCard(
    id: '5',
    word: 'trouver',
    definition: 'to find',
    previousCard: '4',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard":
          'Le directeur de l\'école trouve le crayon dans la salle de classe.'
    },
    intertwinedAloneLanguages: {"hard": 'trouver'},
    intertwinedPreviousSummary: {
      "hard": 'The school principal finds the pencil'
    },
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'to find',
    targetScript: 'trouver',
    transliteration: 'troo-vay',
    audioUrl: 'https://audio.com/trouver.mp3',
  ),
  WordCard(
    id: '6',
    word: 'utiliser',
    definition: 'to use',
    previousCard: '5',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard":
          'Le directeur décide d\'utiliser le crayon pour signer des documents importants.'
    },
    intertwinedAloneLanguages: {"hard": 'utiliser'},
    intertwinedPreviousSummary: {
      "hard": 'The principal uses the pencil for official documents'
    },
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'to use',
    targetScript: 'utiliser',
    transliteration: 'oo-tee-lee-zay',
    audioUrl: 'https://audio.com/utiliser.mp3',
  ),
  WordCard(
    id: '7',
    word: 'important',
    definition: 'important',
    previousCard: '6',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard": 'Le crayon écrit sur des documents très importants maintenant.'
    },
    intertwinedAloneLanguages: {"hard": 'important'},
    intertwinedPreviousSummary: {
      "hard": 'The pencil writes on important documents'
    },
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'important',
    targetScript: 'important',
    transliteration: 'am-por-tahn',
    audioUrl: 'https://audio.com/important.mp3',
  ),
  WordCard(
    id: '8',
    word: 'voyage',
    definition: 'journey/trip',
    previousCard: '7',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard":
          'Un jour, le crayon part en voyage à la capitale dans la poche du directeur.'
    },
    intertwinedAloneLanguages: {"hard": 'voyage'},
    intertwinedPreviousSummary: {
      "hard": 'The pencil travels to the capital city'
    },
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'journey',
    targetScript: 'voyage',
    transliteration: 'voy-ahj',
    audioUrl: 'https://audio.com/voyage.mp3',
  ),
  WordCard(
    id: '9',
    word: 'rencontrer',
    definition: 'to meet',
    previousCard: '8',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard":
          'À la réunion, le directeur va rencontrer le président et oublie le crayon sur la table.'
    },
    intertwinedAloneLanguages: {"hard": 'rencontrer'},
    intertwinedPreviousSummary: {
      "hard": 'The pencil is left at a meeting with the president'
    },
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'to meet',
    targetScript: 'rencontrer',
    transliteration: 'rahn-con-tray',
    audioUrl: 'https://audio.com/rencontrer.mp3',
  ),
  WordCard(
    id: '10',
    word: 'signature',
    definition: 'signature',
    previousCard: '9',
    flowId: 'pencil-journey',
    level: 'A2',
    nativeLanguage: 'English',
    targetLanguage: 'French',
    intertwinedLanguages: {
      "hard":
          'Le président trouve et utilise maintenant ce crayon pour sa signature sur les lois du pays.'
    },
    intertwinedAloneLanguages: {"hard": 'signature'},
    intertwinedPreviousSummary: {
      "hard": 'The pencil becomes the president\'s official signing tool'
    },
    estimatedReadingTimeMinutes: 1,
    updatedAt: DateTime.now(),
    nativeScript: 'signature',
    targetScript: 'signature',
    transliteration: 'see-nya-tuhr',
    audioUrl: 'https://audio.com/signature.mp3',
  ),
];

class Quiz {
  final String id;
  final String cardId;
  final String type; // e.g., "fill-in-blank", "multiple-choice", etc.
  final Map<int, String> intertwineLanguages;
  final String flowId;

  // final int difficultyLevel;
  Quiz({
    required this.intertwineLanguages,
    required this.id,
    required this.cardId,
    required this.flowId,
    required this.type,
  });

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'flowId': flowId,
      'type': type,
      'intertwineLanguages': intertwineLanguages,
    };
  }

  // from json
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      cardId: json['cardId'],
      flowId: json['flowId'],
      type: json['type'],
      intertwineLanguages: json['intertwineLanguages'],
    );
  }
}

class WordsFlow {
  final String id;
  final String targetLanguage;
  final String nativeLanguage;
  final int level;
  final String title;

  WordsFlow({
    required this.id,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.level,
    required this.title,
  });

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetLanguage': targetLanguage,
      'nativeLanguage': nativeLanguage,
      'level': level,
      'title': title,
    };
  }

  // from json
  factory WordsFlow.fromJson(Map<String, dynamic> json) {
    return WordsFlow(
      id: json['id'],
      targetLanguage: json['targetLanguage'],
      level: json['level'],
      title: json['title'],
      nativeLanguage: json['nativeLanguage'],
    );
  }
}

final DummyFlows = <WordsFlow>[
  WordsFlow(
    id: 'pencil-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Pencil',
  ),
  WordsFlow(
    id: 'apple-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of an Apple',
  ),
  WordsFlow(
    id: 'car-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Car',
  ),
  WordsFlow(
    id: 'book-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Book',
  ),
  WordsFlow(
    id: 'pen-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Pen',
  ),
  WordsFlow(
    id: 'phone-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Phone',
  ),
  WordsFlow(
    id: 'computer-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Computer',
  ),
  WordsFlow(
    id: 'keyboard-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Keyboard',
  ),
  WordsFlow(
    id: 'mouse-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Mouse',
  ),
  WordsFlow(
    id: 'monitor-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of a Monitor',
  ),
  WordsFlow(
    id: 'headphones-journey',
    targetLanguage: 'French',
    nativeLanguage: 'English',
    level: 2,
    title: 'The Journey of Headphones',
  ),
];
