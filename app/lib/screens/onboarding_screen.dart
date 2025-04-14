import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/learning/learning_session_cubit.dart';
import 'package:vocafusion/cubits/onboarding_cubit.dart';
import 'package:vocafusion/repositories/user_repository.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  final cards = [
    [
      "Learning new Words is easy, Actually",
      "this is proven technique to learn new words in real life context",
      "https://github.com/nabildroid.png"
    ],
    [
      "2Learning new Words is easy, Actually",
      "this is proven technique to learn new words in real life context",
      "https://github.com/next1.png"
    ],
  ];

  int page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: .45,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  image: DecorationImage(
                    image: NetworkImage(cards[page][2]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: .6,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: PageView(
                        onPageChanged: (i) => setState(() {
                          page = i;
                        }),
                        children: cards
                            .map(
                              (card) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                    card[0],
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    card[1],
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        child: Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: cards
                                .map((e) => CircleAvatar(
                                      radius: 5,
                                      backgroundColor: page == cards.indexOf(e)
                                          ? Colors.black
                                          : Colors.grey,
                                    ))
                                .toList()),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      persistentFooterButtons: [
        InteractiveOkButton(
            tag: "continue",
            text: "Next",
            onPressed: () async {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      OnboardingScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    var begin = Offset(1.0, 0.0); // Start from right
                    var end = Offset.zero;
                    var curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: Duration(milliseconds: 300),
                ),
              );
            })
      ],
    );
  }
}

class InteractiveOkButton extends StatelessWidget {
  final String? tag;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final String text;
  final VoidCallback? onPressed;
  final bool disabled;

  const InteractiveOkButton({
    super.key,
    this.color = const Color(0xff2D2C2D),
    this.textColor = Colors.white,
    this.borderColor = Colors.black,
    this.text = "Continue",
    this.onPressed,
    this.disabled = false,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: IgnorePointer(
          ignoring: disabled,
          child: Hero(
            tag: tag ?? Random().nextDouble().toString(),
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                //only bottom border

                foregroundBuilder: (ctx, state, child) => Padding(
                  padding: EdgeInsets.only(
                      top: state.contains(WidgetState.pressed) ? 3 : 0),
                  child: child,
                ),

                backgroundBuilder: (ctx, state, child) => Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border(
                      bottom: BorderSide(
                        color: borderColor,
                        width: state.contains(WidgetState.pressed) ? 0 : 3,
                      ),
                    ).add(Border.all(
                      color: borderColor,
                      width: 1,
                    )),
                  ),
                  child: child,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();

  void next() {
    if (controller.page == 8) {
      context.push("/register");
      return;
    } else {
      controller.nextPage(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (controller.page == 0) {
                context.pop();
                return;
              }
              controller.previousPage(
                duration: Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );

              setState(() {});
            },
          ),
          title: FractionallySizedBox(
            widthFactor: 0.9,
            child: Center(
              child: Builder(builder: (context) {
                final progress = ((controller.page ?? 0) + 1) / 7;
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  color: const Color.fromARGB(255, 110, 102, 187),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(100),
                );
              }),
            ),
          ),
        ),
        body: SizedBox.expand(
          child: PageView(
            controller: controller,
            physics: NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            children: [
              TargetLanguageChooser(),
              NativeLanguageChooser(),
              GenderChooser(),
              AgeGroupSelector(),
              LevelChooser(),
              TopicChooser(),
              CreateAccount(),
            ],
          ),
        ),
        persistentFooterButtons: [
          BlocListener<OnboardingCubit, OnboardingState>(
            listener: (context, state) {},
            child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return BlocBuilder<OnboardingCubit, OnboardingState>(
                      builder: (context, state) {
                    bool allowControll = true;

                    if (controller.page == 0) {
                      allowControll = state.targetLanguage != null;
                    } else if (controller.page == 1) {
                      allowControll = state.nativeLanguage != null;
                    } else if (controller.page == 2) {
                      allowControll = state.gender != null;
                    } else if (controller.page == 3) {
                      allowControll = state.age != null;
                    } else if (controller.page == 4) {
                      allowControll = state.languageLevel != null;
                    } else if (controller.page == 5) {
                      allowControll = state.selectedTopic != null;
                    }

                    if (controller.page == 6) return SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: InteractiveOkButton(
                        text: "Next",
                        tag: "continue",
                        disabled: !allowControll,
                        onPressed: next,
                      ),
                    );
                  });
                }),
          ),
        ]);
  }
}

class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text("Create Account",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
          Spacer(),
          SizedBox(height: 20),
          Text(
            "137 Language Learners sign in today",
          ),
          SizedBox(height: 4),
          InteractiveOkButton(
            tag: "continue",
            onPressed: () async {
              final nativeLangauge =
                  context.read<OnboardingCubit>().state.nativeLanguage;

              final user = await locator<UserRepository>()
                  .loginWithGoogle(nativeLanguage: nativeLangauge);

              await Future.delayed(Duration(seconds: 1));
              context.go("/learn");

              print(user);
            },
            text: "Sign in with Google",
          ),
          SizedBox(height: 16),
          TextButton(
            child: Text(
              "Skip",
            ),
            onPressed: () {},
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class TargetLanguageChooser extends StatefulWidget {
  const TargetLanguageChooser({super.key});

  @override
  State<TargetLanguageChooser> createState() => _TargetLanguageChooserState();
}

class _TargetLanguageChooserState extends State<TargetLanguageChooser> {
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Turkish',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Target Language",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
          SizedBox(height: 16),
          Text(
              "This will be the language you are about to learn +1000 new words in",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  )),
          SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, state) {
              return ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SelectableItem(
                      isSelected: state.targetLanguage == _languages[index],
                      onSelected: () {
                        context
                            .read<OnboardingCubit>()
                            .setTargetLanguage(_languages[index]);
                      },
                      child: Center(child: Text(_languages[index])),
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }
}

class AgeGroupSelector extends StatefulWidget {
  const AgeGroupSelector({super.key});

  @override
  State<AgeGroupSelector> createState() => AgeGroupSelectorState();
}

class AgeGroupSelectorState extends State<AgeGroupSelector> {
  final List<String> _ages = [
    'Under 18',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Your Age",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
          SizedBox(height: 16),
          Text(
              "So we can Pick you the most interesting topics that keep you engage with with language",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  )),
          SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, state) {
              return ListView.builder(
                itemCount: _ages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SelectableItem(
                      isSelected: state.age == _ages[index],
                      onSelected: () {
                        context.read<OnboardingCubit>().setAge(_ages[index]);
                      },
                      child: Center(child: Text(_ages[index])),
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }
}

class GenderChooser extends StatefulWidget {
  const GenderChooser({super.key});

  @override
  State<GenderChooser> createState() => GenderChooserState();
}

class GenderChooserState extends State<GenderChooser> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Your Gender",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
          SizedBox(height: 16),
          Text(
              "We will Select The most interesting Topics that provides better contexts for learning",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  )),
          SizedBox(height: 20),
          Expanded(child: BlocBuilder<OnboardingCubit, OnboardingState>(
              builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SelectableItem(
                    isSelected: state.gender == "male",
                    onSelected: () {
                      context.read<OnboardingCubit>().setGender("male");
                    },
                    child: Center(child: Text("Male")),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SelectableItem(
                    isSelected: state.gender == "female",
                    onSelected: () {
                      context.read<OnboardingCubit>().setGender("female");
                    },
                    child: Center(child: Text("Female")),
                  ),
                )
              ],
            );
          }))
        ],
      ),
    );
  }
}

class TopicChooser extends StatefulWidget {
  const TopicChooser({super.key});

  @override
  State<TopicChooser> createState() => TopicChooserState();
}

class TopicChooserState extends State<TopicChooser> {
  Widget _buildOption(
    String id, {
    required String leading,
    required String text,
    required String subtext,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SelectableItem(
        isSelected: context.read<OnboardingCubit>().state.selectedTopic == id,
        onSelected: () {
          context.read<OnboardingCubit>().setSelectedTopic(id);
          context.read<LearningSessionCubit>().setCurrentFlowId(id);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(
                leading,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    subtext,
                    softWrap: true,
                    maxLines: 3,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = context.read<OnboardingCubit>().state.targetLanguage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Color(0xff2D2C2D),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text("Congratulations\n your custom plan is ready",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    )),
            SizedBox(height: 8),
            Text("You should Learn:",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    )),
            SizedBox(height: 4),
            Chip(
              label: Text(
                "+1000 $target words by November 15",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xff2D2C2D)),
              ),
              backgroundColor: Colors.grey.shade200,
              shape: StadiumBorder(),
              side: BorderSide.none,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Topic Recomendation",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                  Text(
                    "You can edit this any time",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                  SizedBox(height: 8),
                  BlocBuilder<OnboardingCubit, OnboardingState>(
                      builder: (context, state) {
                    return Column(
                      spacing: 12,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...state.filtredFlows
                                ?.map((flow) => _buildOption(
                                      flow.id,
                                      leading: [
                                        "A1",
                                        "A2",
                                        "B1",
                                        "B2",
                                        "C1",
                                        "C2"
                                      ][flow.level],
                                      text: flow.id,
                                      subtext: flow.title,
                                    ))
                                .toList() ??
                            [],
                      ],
                    );
                  }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LevelChooser extends StatefulWidget {
  const LevelChooser({super.key});

  @override
  State<LevelChooser> createState() => LevelChooserState();
}

class LevelChooserState extends State<LevelChooser> {
  Widget _buildOption(
    int index, {
    required String leading,
    required String text,
    required String subtext,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SelectableItem(
        isSelected:
            context.read<OnboardingCubit>().state.languageLevel == index,
        onSelected: () {
          context.read<OnboardingCubit>().setLanguageLevel(index);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(
                leading,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    subtext,
                    softWrap: true,
                    maxLines: 3,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = context.read<OnboardingCubit>().state.targetLanguage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Are you good at $target",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
          SizedBox(height: 16),
          Text(
              "Pick your current level with $target now, se we can help you reach the next level",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  )),
          SizedBox(height: 20),
          Expanded(child: BlocBuilder<OnboardingCubit, OnboardingState>(
              builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOption(
                    1,
                    leading: "A1",
                    text: "Basic greetings?",
                    subtext:
                        "I can say hello, goodbye and ask simple questions.",
                  ),
                  _buildOption(
                    2,
                    leading: "A2",
                    text: "Ask simple questions?",
                    subtext:
                        "I can talk about myself and my routine in basic sentences.",
                  ),
                  _buildOption(
                    3,
                    leading: "B1",
                    text: "Manage daily tasks?",
                    subtext:
                        "I can handle common travel, work and social situations.",
                  ),
                  _buildOption(
                    4,
                    leading: "B2",
                    text: "Fluent interaction?",
                    subtext:
                        "I can chat with native speakers with few misunderstandings.",
                  ),
                  _buildOption(
                    5,
                    leading: "C1",
                    text: "Speak with ease?",
                    subtext:
                        "I can express ideas fluently and grasp demanding texts.",
                  ),
                  _buildOption(
                    6,
                    leading: "C2",
                    text: "Native‑like fluency?",
                    subtext:
                        "I can summarize and reconstruct complex arguments effortlessly.",
                  ),
                ],
              ),
            );
          }))
        ],
      ),
    );
  }
}

class NativeLanguageChooser extends StatefulWidget {
  const NativeLanguageChooser({super.key});

  @override
  State<NativeLanguageChooser> createState() => NativeLanguageChooserState();
}

class NativeLanguageChooserState extends State<NativeLanguageChooser> {
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Turkish',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Your Native Language",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
          SizedBox(height: 16),
          Text("the Language You master",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  )),
          SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, state) {
              return ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SelectableItem(
                      isSelected: state.nativeLanguage == _languages[index],
                      onSelected: () {
                        context
                            .read<OnboardingCubit>()
                            .setNativeLanguage(_languages[index]);
                      },
                      child: Center(child: Text(_languages[index])),
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }
}

class SelectableItem extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onSelected;
  const SelectableItem({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Color(0xff2D2C2D) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onSelected,
        child: DefaultTextStyle(
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xff2D2C2D),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
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
                          context
                              .read<OnboardingCubit>()
                              .setNativeLanguage(language);
                        },
                        selectedLanguage: state.nativeLanguage,
                      ),

                      // Target Language Page
                      _buildLanguagePage(
                        title: 'Choose Your Target Language',
                        onLanguageSelected: (language) {
                          context
                              .read<OnboardingCubit>()
                              .setTargetLanguage(language);
                        },
                        selectedLanguage: state.targetLanguage,
                      ),

                      // Language Level Page
                      _buildLevelPage(state),

                      // Profile Page (Age & Gender)
                      _buildProfilePage(state),

                      // Topics Page
                      _buildTopicsPage(state),
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
                        onPressed:
                            _isNextButtonEnabled(state) ? _nextPage : null,
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
      },
    );
  }

  bool _isNextButtonEnabled(OnboardingState state) {
    switch (_currentPage) {
      case 0:
        return true; // Welcome page, always enabled
      case 1:
        return state.nativeLanguage != null; // Native language page
      case 2:
        return state.targetLanguage != null; // Target language page
      case 3:
        return state.languageLevel != null; // Level page
      case 4:
        return state.age != null && state.gender != null; // Profile page
      case 5:
        return state.selectedTopic != null; // Topics page
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
  Widget _buildLevelPage(OnboardingState state) {
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
            'Select your current level in ${state.targetLanguage ?? "your target language"}',
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
                final isSelected = state.languageLevel == index + 1;

                return GestureDetector(
                  onTap: () {
                    context.read<OnboardingCubit>().setLanguageLevel(index + 1);
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
  Widget _buildProfilePage(OnboardingState state) {
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
              final isSelected = state.age == ageGroup;
              return ChoiceChip(
                label: Text(ageGroup),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    context.read<OnboardingCubit>().setAge(ageGroup);
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
              final isSelected = state.gender == genderOption;
              return ChoiceChip(
                label: Text(genderOption),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    context.read<OnboardingCubit>().setGender(genderOption);
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
  Widget _buildTopicsPage(OnboardingState state) {
    final flows = context.read<OnboardingCubit>().state.filtredFlows;
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
              itemCount: flows?.length ?? 0,
              itemBuilder: (context, index) {
                final topic = flows![index];
                final isSelected = state.selectedTopic == topic.id;

                return GestureDetector(
                  onTap: () {
                    context.read<OnboardingCubit>().setSelectedTopic(topic.id);
                    context
                        .read<LearningSessionCubit>()
                        .setCurrentFlowId(topic.id);
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
                          Icons.book,
                          size: 48,
                          color:
                              isSelected ? Colors.white : Colors.blueGrey[800],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          topic.title,
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
