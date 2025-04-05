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
  final String nativeDefinition;
  final String previousCard;
  final String flowId;
  final String level;
  final String nativeLanguage;
  final String targetLanguage;
  final String context; // the story (was intertwinedLanguages)
  final String
      aloneContext; // standalone context for the word (was intertwinedAloneLanguages)
  final String
      previousSummary; // summary of all previous cards (was intertwinedPreviousSummary)
  final int estimatedReadingTimeMinutes;
  final DateTime updatedAt;

  // New fields
  final String nativeWord; // Word in native script
  final String transliteration; // Transliteration to help pronunciation
  final String audioUrl; // Link to pronunciation audio

  WordCard({
    required this.context,
    required this.aloneContext,
    required this.previousSummary,
    required this.id,
    required this.word,
    required this.definition,
    required this.nativeDefinition,
    required this.previousCard,
    required this.flowId,
    required this.level,
    required this.nativeLanguage,
    required this.targetLanguage,
    required this.estimatedReadingTimeMinutes,
    required this.updatedAt,
    required this.nativeWord,
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
      'language': context,
      'aloneLanguage': aloneContext,
      'previousSummary': previousSummary,
      'estimatedReadingTimeMinutes': estimatedReadingTimeMinutes,
      'updatedAt': updatedAt.toIso8601String(),
      'nativeScript': nativeWord,
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
      context: json['language'],
      aloneContext: json['aloneLanguage'],
      previousSummary: json['previousSummary'],
      estimatedReadingTimeMinutes: json['estimatedReadingTimeMinutes'],
      updatedAt: DateTime.parse(json['updatedAt']),
      nativeWord: json['nativeScript'],
      transliteration: json['transliteration'],
      audioUrl: json['audioUrl'],
      nativeDefinition: json['nativeDefinition'] ?? '',
    );
  }
}

final DummyCards = <WordCard>[
  WordCard(
    id: '1',
    word: 'ephemeral',
    definition: 'Lasting for a very short time; transient.',
    nativeDefinition: 'زائل؛ عابر؛ يدوم لفترة قصيرة جداً.',
    previousCard: '',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Greene suggests initial attraction is often **ephemeral**, a fleeting spark that requires careful cultivation to endure.',
    aloneContext: 'ephemeral',
    previousSummary: 'Introduction to fleeting attraction',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'زائل',
    transliteration: 'za\'il',
    audioUrl: 'https://audio.com/ephemeral.mp3',
  ),
  WordCard(
    id: '2',
    word: 'idiosyncrasy',
    definition:
        'A mode of behaviour or way of thought peculiar to an individual; a distinctive or peculiar feature or characteristic.',
    nativeDefinition:
        'خصوصية؛ ميزة فريدة؛ طريقة سلوك أو تفكير غريبة خاصة بفرد.',
    previousCard: '1',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Understanding your target\'s **idiosyncrasy** is paramount; their unique quirks are keys to unlocking their desires.',
    aloneContext: 'idiosyncrasy',
    previousSummary: 'The importance of understanding unique traits',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'خصوصية',
    transliteration: 'khususiyya',
    audioUrl: 'https://audio.com/idiosyncrasy.mp3',
  ),
  WordCard(
    id: '3',
    word: 'penchant',
    definition:
        'A strong or habitual liking for something or tendency to do something.',
    nativeDefinition:
        'ميل؛ ولع؛ إعجاب قوي أو اعتيادي بشيء ما أو ميل للقيام بشيء ما.',
    previousCard: '2',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Discover their hidden **penchant** – that secret taste or inclination they rarely reveal to others.',
    aloneContext: 'penchant',
    previousSummary: 'Finding hidden preferences',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'ميل',
    transliteration: 'mayl',
    audioUrl: 'https://audio.com/penchant.mp3',
  ),
  WordCard(
    id: '4',
    word: 'dissemble',
    definition:
        'Conceal or disguise one\'s true motives, feelings, or beliefs.',
    nativeDefinition: 'راوغ؛ نافق؛ أخفى دوافعه أو مشاعره أو معتقداته الحقيقية.',
    previousCard: '3',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Effective seducers often **dissemble**, presenting a carefully crafted persona rather than their unvarnished self.',
    aloneContext: 'dissemble',
    previousSummary: 'The art of concealing true motives',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'راوغ',
    transliteration: 'rawagh',
    audioUrl: 'https://audio.com/dissemble.mp3',
  ),
  WordCard(
    id: '5',
    word: 'insinuate',
    definition:
        'Suggest or hint (something bad or reprehensible) in an indirect and unpleasant way; manoeuvre oneself into (a position of favour) by subtle manipulation.',
    nativeDefinition:
        'دسّ؛ ألمح إلى (شيء سيء) بطريقة غير مباشرة؛ تسلل إلى (مكانة محبوبة) عن طريق التلاعب الخفي.',
    previousCard: '4',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Rather than direct confrontation, the art often lies in the ability to **insinuate** ideas subtly into the target\'s mind.',
    aloneContext: 'insinuate',
    previousSummary: 'The power of subtle suggestion',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'دسّ',
    transliteration: 'dass',
    audioUrl: 'https://audio.com/insinuate.mp3',
  ),
  WordCard(
    id: '6',
    word: 'mercurial',
    definition:
        '(Of a person) subject to sudden or unpredictable changes of mood or mind.',
    nativeDefinition:
        'متقلب؛ زئبقي؛ (عن شخص) خاضع لتغيرات مفاجئة أو غير متوقعة في المزاج أو العقل.',
    previousCard: '5',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'A **mercurial** temperament can be captivating, keeping the target intrigued and slightly off-balance.',
    aloneContext: 'mercurial',
    previousSummary: 'The appeal of unpredictability',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'متقلب',
    transliteration: 'mutaqallib',
    audioUrl: 'https://audio.com/mercurial.mp3',
  ),
  WordCard(
    id: '7',
    word: 'ubiquitous',
    definition: 'Present, appearing, or found everywhere.',
    nativeDefinition: 'واسع الانتشار؛ كلي الوجود؛ موجود أو ظاهر في كل مكان.',
    previousCard: '6',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'The dynamics of seduction, Greene argues, are **ubiquitous**, underlying much of human interaction, seen or unseen.',
    aloneContext: 'ubiquitous',
    previousSummary: 'The omnipresence of seduction techniques',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'واسع الانتشار',
    transliteration: 'wasi\' al-intishar',
    audioUrl: 'https://audio.com/ubiquitous.mp3',
  ),
  WordCard(
    id: '8',
    word: 'beguile',
    definition:
        'Charm or enchant (someone), often in a deceptive way; help (time) pass pleasantly.',
    nativeDefinition: 'سحر؛ خدع؛ فتن (شخصًا ما)، غالبًا بطريقة خادعة.',
    previousCard: '7',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'The aim is often to **beguile** the target, creating an enchanting atmosphere where resistance melts away.',
    aloneContext: 'beguile',
    previousSummary: 'Creating enchantment to lower resistance',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'سحر',
    transliteration: 'sahar',
    audioUrl: 'https://audio.com/beguile.mp3',
  ),
  WordCard(
    id: '9',
    word: 'subterfuge',
    definition: 'Deceit used in order to achieve one\'s goal.',
    nativeDefinition: 'حيلة؛ خدعة؛ مكيدة؛ خداع يُستخدم لتحقيق هدف المرء.',
    previousCard: '8',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Strategic retreats and feigned indifference are forms of **subterfuge** detailed in the book\'s tactical arsenal.',
    aloneContext: 'subterfuge',
    previousSummary: 'Strategic deception as a tactic',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'حيلة',
    transliteration: 'hila',
    audioUrl: 'https://audio.com/subterfuge.mp3',
  ),
  WordCard(
    id: '10',
    word: 'enigmatic',
    definition: 'Difficult to interpret or understand; mysterious.',
    nativeDefinition: 'غامض؛ محير؛ صعب التفسير أو الفهم.',
    previousCard: '9',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Cultivating an **enigmatic** aura makes you a puzzle the target feels compelled to solve.',
    aloneContext: 'enigmatic',
    previousSummary: 'The power of mystery',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'غامض',
    transliteration: 'ghamid',
    audioUrl: 'https://audio.com/enigmatic.mp3',
  ),
  // Additional cards with connections between words
  WordCard(
    id: '11',
    word: 'ephemeral',
    definition: 'Lasting for a very short time; transient.',
    nativeDefinition: 'زائل؛ عابر؛ يدوم لفترة قصيرة جداً.',
    previousCard: '10',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Don\'t mistake the intensity of an **ephemeral** encounter for deep connection; true understanding requires seeing past the surface *idiosyncrasy*.',
    aloneContext: 'ephemeral',
    previousSummary: 'The danger of mistaking intensity for depth',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'زائل',
    transliteration: 'za\'il',
    audioUrl: 'https://audio.com/ephemeral.mp3',
  ),
  WordCard(
    id: '12',
    word: 'idiosyncrasy',
    definition:
        'A mode of behaviour or way of thought peculiar to an individual; a distinctive or peculiar feature or characteristic.',
    nativeDefinition:
        'خصوصية؛ ميزة فريدة؛ طريقة سلوك أو تفكير غريبة خاصة بفرد.',
    previousCard: '11',
    flowId: 'art-of-seduction',
    level: 'C1',
    nativeLanguage: 'Arabic',
    targetLanguage: 'English',
    context:
        'Appealing to someone\'s core *idiosyncrasy* often means validating their secret *penchant*.',
    aloneContext: 'idiosyncrasy',
    previousSummary: 'Connecting with unique traits and preferences',
    estimatedReadingTimeMinutes: 2,
    updatedAt: DateTime.now(),
    nativeWord: 'خصوصية',
    transliteration: 'khususiyya',
    audioUrl: 'https://audio.com/idiosyncrasy.mp3',
  ),
  // Continue with remaining entries (13-30)
  // ... Add all remaining entries following the same pattern
];

class Quiz {
  final String id;
  final String cardId;
  // final String type; // e.g., "fill-in-blank", "multiple-choice", etc.
  final String flowId;
  final String question;
  final List<String> options;
  final String answer;

  // final int difficultyLevel;
  Quiz({
    required this.id,
    required this.cardId,
    required this.flowId,
    required this.answer,
    required this.options,
    required this.question,
  });

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'flowId': flowId,
      'answer': answer,
      'options': options,
      'question': question,
    };
  }

  // from json
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      cardId: json['cardId'],
      flowId: json['flowId'],
      answer: json['answer'],
      options: List<String>.from(json['options']),
      question: json['question'],
    );
  }
}

final DummyQuizzes = [
  Quiz(
    id: '1',
    cardId: '1',
    flowId: 'pencil-journey',
    question: 'What is the meaning of "crayon" in English?',
    options: ['Book', 'Pencil', 'Car', 'Apple'],
    answer: 'Pencil',
  ),
  Quiz(
    id: '2',
    cardId: '2',
    flowId: 'pencil-journey',
    question: 'What does "écrire" mean in English?',
    options: ['To Read', 'To Eat', 'To Write', 'To Sleep'],
    answer: 'To Write',
  ),
  Quiz(
    id: '3',
    cardId: '3',
    flowId: 'pencil-journey',
    question: 'What is "papier" in English?',
    options: ['Pencil', 'Paper', 'Desk', 'Chair'],
    answer: 'Paper',
  ),
  Quiz(
    id: '4',
    cardId: '4',
    flowId: 'pencil-journey',
    question: 'What is the meaning of "bureau" in English?',
    options: ['Desk/Office', 'Book', 'Pencil', 'Apple'],
    answer: 'Desk/Office',
  ),
  Quiz(
    id: '5',
    cardId: '5',
    flowId: 'pencil-journey',
    question: 'What does "trouver" mean in English?',
    options: ['To Lose', 'To Find', 'To Eat', 'To Sleep'],
    answer: 'To Find',
  ),
  Quiz(
    id: '6',
    cardId: '6',
    flowId: 'pencil-journey',
    question: 'What is "utiliser" in English?',
    options: ['To Break', 'To Sell', 'To Use', 'To Give'],
    answer: 'To Use',
  ),
  Quiz(
    id: '7',
    cardId: '7',
    flowId: 'pencil-journey',
    question: 'What is the meaning of "important" in English?',
    options: ['Useless', 'Trivial', 'Important', 'Normal'],
    answer: 'Important',
  ),
  Quiz(
    id: '8',
    cardId: '8',
    flowId: 'pencil-journey',
    question: 'What is "voyage" in English?',
    options: ['Home', 'Work', 'Journey/Trip', 'School'],
    answer: 'Journey/Trip',
  ),
  Quiz(
    id: '9',
    cardId: '9',
    flowId: 'pencil-journey',
    question: 'What does "rencontrer" mean in English?',
    options: ['To Avoid', 'To Ignore', 'To Meet', 'To Run'],
    answer: 'To Meet',
  ),
  Quiz(
    id: '10',
    cardId: '10',
    flowId: 'pencil-journey',
    question: 'What is "signature" in English?',
    options: ['Sign', 'Picture', 'Signature', 'Drawing'],
    answer: 'Signature',
  ),
];

class WordsFlow {
  final String id;
  final String targetLanguage;
  final String nativeLanguage;
  final int level;
  final String title;
  final String parentFlow;

  WordsFlow({
    required this.id,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.level,
    required this.title,
    this.parentFlow = '',
  });

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetLanguage': targetLanguage,
      'nativeLanguage': nativeLanguage,
      'level': level,
      'parentFlow': parentFlow,
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
      parentFlow: json['parentFlow'] ?? '',
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
