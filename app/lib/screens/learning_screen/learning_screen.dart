import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocafusion/cubits/learning/biased_sorting_cubit.dart';
import 'package:vocafusion/models/modeling.dart';

class LearningScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final words = context.watch<BiasedSortingCubit>().state.sorted;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: PageView(
          controller: PageController(viewportFraction: 0.8),
          scrollDirection: Axis.vertical,
          children: List.generate(
            words.length * 2,
            (i) => Center(
              child: i % 2 == 0
                  ? CardWidget(
                      item: words[i ~/ 2 + i % 2],
                    )
                  : QuizWidget(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        elevation: 0,
        child: Text("Next"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomNavigationBar(),
    );
  }
}

class QuizWidget extends StatelessWidget {
  const QuizWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 0),
            blurRadius: 12,
            spreadRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            "Quiz Time!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Choose the correct definition for the word:",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            "Word: [word to be quizzed]", // Replace with actual word
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          // Add your quiz options here, for example:
          ElevatedButton(
            onPressed: () {},
            child: Text("Option 1"),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("Option 2"),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("Option 3"),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("Option 4"),
          ),
        ],
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final WordCard item;
  const CardWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                icon: Icon(Icons.favorite_border),
                onPressed: () {},
                iconSize: 21,
              ),
              Spacer(),
              Text(
                item.word,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffFF0307),
                ),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.definition,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          TextWithTextHighlited(
            item.intertwinedLanguages["hard"] ??
                item.intertwinedAloneLanguages["hard"]!,
            target: item.word,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton.filledTonal(
                icon: Icon(Icons.mic),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: Icon(Icons.play_arrow),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.format_quote),
          label: 'Vocabulary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorite',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          child: Text("3"),
          backgroundColor: Colors.grey.shade200,
          radius: 8,
        ),
      ),
      title: FractionallySizedBox(
        widthFactor: 0.8,
        child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text("2/20",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(width: 4),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.2,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(80),
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        AlwaysStoppedAnimation(Colors.blueGrey.shade800),
                  ),
                ),
              ],
            )),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton.filledTonal(
          onPressed: () {},
          icon: Icon(Icons.diamond_outlined),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class TextWithTextHighlited extends StatelessWidget {
  final String text;
  final String target;
  const TextWithTextHighlited(
    this.text, {
    super.key,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final index = text.indexOf(target);

    // If target is not found in the text
    if (index == -1) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final before = text.substring(0, index);
    final after = text.substring(index + target.length);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 26,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: target,
            style: TextStyle(
              color: Color(0xffFF0307),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
