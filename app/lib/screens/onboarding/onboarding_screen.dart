import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding data stored only in state
  String? nativeLanguage;
  String? targetLanguage;
  String? languageLevel;
  String? age;
  String? gender;
  String? selectedTopic;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Korean',
    'Chinese',
    'Arabic',
    'Hindi',
    'Turkish',
    'Dutch',
    'Swedish',
  ];

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  final List<String> _ages = [
    'Under 18',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+'
  ];

  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  final List<Map<String, dynamic>> _topics = [
    {'id': 'science', 'title': 'Science & Technology', 'icon': Icons.science},
    {'id': 'business', 'title': 'Business & Economics', 'icon': Icons.business},
    {'id': 'arts', 'title': 'Arts & Literature', 'icon': Icons.palette},
    {'id': 'travel', 'title': 'Travel & Culture', 'icon': Icons.flight},
    {
      'id': 'health',
      'title': 'Health & Wellness',
      'icon': Icons.health_and_safety
    },
    {'id': 'history', 'title': 'History & Politics', 'icon': Icons.history_edu},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On last page, complete onboarding
      context.go('/learn');
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 6,
                backgroundColor: Colors.grey[300],
                color: Colors.blueGrey[800],
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // Welcome Page
                  _buildWelcomePage(),

                  // Native Language Page
                  _buildLanguagePage(
                    title: 'Choose Your Native Language',
                    onLanguageSelected: (language) {
                      setState(() {
                        nativeLanguage = language;
                      });
                    },
                    selectedLanguage: nativeLanguage,
                  ),

                  // Target Language Page
                  _buildLanguagePage(
                    title: 'Choose Your Target Language',
                    onLanguageSelected: (language) {
                      setState(() {
                        targetLanguage = language;
                      });
                    },
                    selectedLanguage: targetLanguage,
                  ),

                  // Language Level Page
                  _buildLevelPage(),

                  // Profile Page (Age & Gender)
                  _buildProfilePage(),

                  // Topics Page
                  _buildTopicsPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _currentPage > 0
                      ? TextButton(
                          onPressed: _previousPage,
                          child: const Text('Back'),
                        )
                      : const SizedBox(width: 80),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _isNextButtonEnabled() ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentPage == 5 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isNextButtonEnabled() {
    switch (_currentPage) {
      case 0:
        return true; // Welcome page, always enabled
      case 1:
        return nativeLanguage != null; // Native language page
      case 2:
        return targetLanguage != null; // Target language page
      case 3:
        return languageLevel != null; // Level page
      case 4:
        return age != null && gender != null; // Profile page
      case 5:
        return selectedTopic != null; // Topics page
      default:
        return false;
    }
  }

  // Welcome Page
  Widget _buildWelcomePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.language,
              size: 120,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 40),
            Text(
              'Welcome to VocaFusion',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Your personal language learning assistant that helps you expand your vocabulary through personalized content.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Language Selection Page (reused for native and target language)
  Widget _buildLanguagePage({
    required String title,
    required Function(String) onLanguageSelected,
    required String? selectedLanguage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the language from the list below',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                return ListTile(
                  title: Text(language),
                  leading: Radio<String>(
                    value: language,
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      if (value != null) {
                        onLanguageSelected(value);
                      }
                    },
                  ),
                  onTap: () {
                    onLanguageSelected(language);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Language Level Page
  Widget _buildLevelPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'What\'s Your Proficiency Level?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your current level in ${targetLanguage ?? "your target language"}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                final level = _levels[index];
                final isSelected = languageLevel == level;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      languageLevel = level;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueGrey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueGrey[800]!
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            level,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blueGrey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLevelDescription(level),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white70
                                  : Colors.blueGrey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case 'A1':
        return 'Beginner';
      case 'A2':
        return 'Elementary';
      case 'B1':
        return 'Intermediate';
      case 'B2':
        return 'Upper Intermediate';
      case 'C1':
        return 'Advanced';
      case 'C2':
        return 'Proficient';
      default:
        return '';
    }
  }

  // Profile Page (Age & Gender)
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'About You',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your learning experience',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Age selection
          Text(
            'Age Group',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _ages.map((ageGroup) {
              final isSelected = age == ageGroup;
              return ChoiceChip(
                label: Text(ageGroup),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      age = ageGroup;
                    });
                  }
                },
                selectedColor: Colors.blueGrey[200],
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Gender selection
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _genders.map((genderOption) {
              final isSelected = gender == genderOption;
              return ChoiceChip(
                label: Text(genderOption),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      gender = genderOption;
                    });
                  }
                },
                selectedColor: Colors.blueGrey[200],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Topics Page
  Widget _buildTopicsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Select a Topic',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a topic you\'d like to learn vocabulary from',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isSelected = selectedTopic == topic['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTopic = topic['id'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueGrey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueGrey[800]!
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blueGrey.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          topic['icon'],
                          size: 48,
                          color:
                              isSelected ? Colors.white : Colors.blueGrey[800],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          topic['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
