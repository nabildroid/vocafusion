import 'package:equatable/equatable.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:vocafusion/models/core/access_token_model.dart';

final class UserCustomClaims extends Equatable {
  const UserCustomClaims({
    required this.premiumExpires,
  });

  final DateTime premiumExpires;

  bool get isPremium => DateTime.now().isBefore(premiumExpires);

  bool get isTrulyPremium =>
      premiumExpires.difference(DateTime.now()).inDays < 1000;

  Map<String, dynamic> toJson() {
    return {
      "premiumExpires": isPremium ? premiumExpires.toIso8601String() : null,
    };
  }

  factory UserCustomClaims.fromJson(Map<String, dynamic> data) {
    var expiresAt = DateTime.now().add(Duration(days: 10000));
    if (data["premiumExpires"] != null) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(data["premiumExpires"]);
    }
    return UserCustomClaims(
      premiumExpires: expiresAt,
    );
  }

  @override
  List<Object?> get props => [premiumExpires];
}

class User extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String nativeLanguage;
  final UserCustomClaims claims;

  final DateTime createdAt;

  User({
    required this.uid,
    required this.nativeLanguage,
    required this.createdAt,
    this.photoURL,
    this.displayName = 'User',
    required this.claims,
    required this.email,
  });

  // from json
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      nativeLanguage: json['nativeLanguage'],
      createdAt: DateTime.parse(json['createdAt']),
      displayName: json['displayName'] ?? 'User',
      photoURL: json['photoURL'],
      claims: UserCustomClaims.fromJson(json['claims'] ?? {}),
      email: json['email'] ?? '',
    );
  }

  factory User.fromAccessToken(AccessTokenModel accessToken) {
    final token = accessToken.token;
    final Map<String, dynamic> data = JwtDecoder.decode(token);
    return User.fromJson(data);
  }

  @override
  List<Object?> get props => [uid, email, displayName, createdAt, claims];
}

class WordCard {
  final String id;
  final String word;
  final String targetDefinition;
  final String nativeDefinition;
  final String? previousCard;
  final String flowId;
  final String level;
  final String nativeLanguage;
  final String targetLanguage;
  final String context; // the story (was intertwinedLanguages)
  final String
      aloneContext; // standalone context for the word (was intertwinedAloneLanguages)
  final String
      previousSummary; // summary of all previous cards (was intertwinedPreviousSummary)

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
    required this.targetDefinition,
    required this.nativeDefinition,
    required this.flowId,
    required this.level,
    required this.nativeLanguage,
    required this.targetLanguage,
    required this.nativeWord,
    required this.transliteration,
    required this.audioUrl,
    this.previousCard,
  });

  //to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': targetDefinition,
      'previousCard': previousCard,
      'flowId': flowId,
      'level': level,
      'nativeLanguage': nativeLanguage,
      'targetLanguage': targetLanguage,
      'language': context,
      'aloneLanguage': aloneContext,
      'previousSummary': previousSummary,
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
      targetDefinition: json['definition'],
      previousCard: json['previousCard'],
      flowId: json['flowId'],
      level: json['level'],
      nativeLanguage: json['nativeLanguage'],
      targetLanguage: json['targetLanguage'],
      context: json['language'],
      aloneContext: json['aloneLanguage'],
      previousSummary: json['previousSummary'],
      nativeWord: json['nativeScript'],
      transliteration: json['transliteration'],
      audioUrl: json['audioUrl'],
      nativeDefinition: json['nativeDefinition'] ?? '',
    );
  }

  String get srID => word;
}

final DummyCards = <WordCard>[
  WordCard(
    id: '1',
    word: 'ephemeral',
    targetDefinition: 'Lasting for a very short time; transient.',
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
    nativeWord: 'زائل',
    transliteration: 'za\'il',
    audioUrl: 'https://audio.com/ephemeral.mp3',
  ),
  WordCard(
    id: '2',
    word: 'idiosyncrasy',
    targetDefinition:
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
    nativeWord: 'خصوصية',
    transliteration: 'khususiyya',
    audioUrl: 'https://audio.com/idiosyncrasy.mp3',
  ),
  WordCard(
    id: '3',
    word: 'penchant',
    targetDefinition:
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
    nativeWord: 'ميل',
    transliteration: 'mayl',
    audioUrl: 'https://audio.com/penchant.mp3',
  ),
  WordCard(
    id: '4',
    word: 'dissemble',
    targetDefinition:
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
    nativeWord: 'راوغ',
    transliteration: 'rawagh',
    audioUrl: 'https://audio.com/dissemble.mp3',
  ),
  WordCard(
    id: '5',
    word: 'insinuate',
    targetDefinition:
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
    nativeWord: 'دسّ',
    transliteration: 'dass',
    audioUrl: 'https://audio.com/insinuate.mp3',
  ),
  WordCard(
    id: '6',
    word: 'mercurial',
    targetDefinition:
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
    nativeWord: 'متقلب',
    transliteration: 'mutaqallib',
    audioUrl: 'https://audio.com/mercurial.mp3',
  ),
  WordCard(
    id: '7',
    word: 'ubiquitous',
    targetDefinition: 'Present, appearing, or found everywhere.',
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
    nativeWord: 'واسع الانتشار',
    transliteration: 'wasi\' al-intishar',
    audioUrl: 'https://audio.com/ubiquitous.mp3',
  ),
  WordCard(
    id: '8',
    word: 'beguile',
    targetDefinition:
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
    nativeWord: 'سحر',
    transliteration: 'sahar',
    audioUrl: 'https://audio.com/beguile.mp3',
  ),
  WordCard(
    id: '9',
    word: 'subterfuge',
    targetDefinition: 'Deceit used in order to achieve one\'s goal.',
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
    nativeWord: 'حيلة',
    transliteration: 'hila',
    audioUrl: 'https://audio.com/subterfuge.mp3',
  ),
  WordCard(
    id: '10',
    word: 'enigmatic',
    targetDefinition: 'Difficult to interpret or understand; mysterious.',
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
    nativeWord: 'غامض',
    transliteration: 'ghamid',
    audioUrl: 'https://audio.com/enigmatic.mp3',
  ),
  // Additional cards with connections between words
  WordCard(
    id: '11',
    word: 'ephemeral',
    targetDefinition: 'Lasting for a very short time; transient.',
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
    nativeWord: 'زائل',
    transliteration: 'za\'il',
    audioUrl: 'https://audio.com/ephemeral.mp3',
  ),
  WordCard(
    id: '12',
    word: 'idiosyncrasy',
    targetDefinition:
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
    nativeWord: 'خصوصية',
    transliteration: 'khususiyya',
    audioUrl: 'https://audio.com/idiosyncrasy.mp3',
  ),
  // Continue with remaining entries (13-30)
  // ... Add all remaining entries following the same pattern
];

class WordsFlowSuggestor {
  final Map<double, String> scoredAgeGroups;
  final Map<double, String> genders;

  const WordsFlowSuggestor(
      {required this.scoredAgeGroups, required this.genders});

  double score({
    required String ageGroup,
    required String gender,
  }) {
    // First, find the score for the given age group
    double ageGroupScore = 0;
    for (var entry in scoredAgeGroups.entries) {
      if (entry.value == ageGroup) {
        ageGroupScore = entry.key;
        break;
      }
    }

    // Next, find the score for the given gender
    double genderScore = 0;
    for (var entry in genders.entries) {
      if (entry.value == gender) {
        genderScore = entry.key;
        break;
      }
    }

    // Calculate and return the combined score
    // We're using a simple addition here, but other formulas can be used
    return ageGroupScore + genderScore;
  }

  // to json
  Map<String, dynamic> toJson() {
    Map<String, String> ageGroupMap = {};
    scoredAgeGroups.forEach((score, ageGroup) {
      ageGroupMap[score.toString()] = ageGroup;
    });

    Map<String, String> genderMap = {};
    genders.forEach((score, gender) {
      genderMap[score.toString()] = gender;
    });

    return {
      'scoredAgeGroups': ageGroupMap,
      'genders': genderMap,
    };
  }

  // from json
  factory WordsFlowSuggestor.fromJson(Map<String, dynamic> json) {
    Map<double, String> ageGroups = {};
    if (json['scoredAgeGroups'] != null) {
      Map<String, dynamic> ageMap = json['scoredAgeGroups'];
      ageMap.forEach((scoreStr, ageGroup) {
        ageGroups[double.parse(scoreStr)] = ageGroup;
      });
    }

    Map<double, String> genderMap = {};
    if (json['genders'] != null) {
      Map<String, dynamic> gMap = json['genders'];
      gMap.forEach((scoreStr, gender) {
        genderMap[double.parse(scoreStr)] = gender;
      });
    }

    return WordsFlowSuggestor(
      scoredAgeGroups: ageGroups,
      genders: genderMap,
    );
  }
}

class WordsFlow {
  final String id;
  final String targetLanguage;
  final String nativeLanguage;
  final int level;
  final String title;
  final String? parentFlow;
  final WordsFlowSuggestor suggestor;

  WordsFlow({
    required this.id,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.level,
    required this.title,
    this.parentFlow,
    this.suggestor = const WordsFlowSuggestor(genders: {}, scoredAgeGroups: {}),
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
      'suggestor': suggestor.toJson(),
    };
  }

  // from json
  factory WordsFlow.fromJson(Map<String, dynamic> json) {
    return WordsFlow(
      id: json['id'],
      targetLanguage: json['targetLanguage'],
      level: json['level'],
      title: json['title'],
      parentFlow: json['parentFlow'],
      nativeLanguage: json['nativeLanguage'],
      suggestor: WordsFlowSuggestor.fromJson(json['suggestor'] ?? {}),
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
