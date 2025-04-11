import 'package:flutter/material.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/favorites_repository.dart';
import 'package:vocafusion/screens/learning_screen/widgets/widgets.dart';

class CardWidget extends StatefulWidget {
  final WordCard item;
  const CardWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  bool isFavorite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final favRepository = locator.get<FavoritesRepository>();
    final isFav = await favRepository.isFavorite(widget.item.id);

    if (mounted) {
      setState(() {
        isFavorite = isFav;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isLoading = true;
    });

    final favRepository = locator.get<FavoritesRepository>();
    final isFav = await favRepository.toggleFavorite(widget.item.id);

    if (mounted) {
      setState(() {
        isFavorite = isFav;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xffFFF3EB),
            Color(0xffDBE5FF),
          ],
          stops: const [0.18, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.all(Radius.elliptical(13, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 0),
            blurRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              '"${widget.item.word}"',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xffE30004),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.targetDefinition,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          TextWithTextHighlited(
            widget.item.context,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              WordActionButton(
                icon: Icons.favorite_border,
                onPress: () {},
              ),
              Spacer(),
              WordActionButton(
                icon: Icons.mic,
                onPress: () {},
              ),
              const SizedBox(width: 8),
              WordActionButton(
                icon: Icons.play_arrow,
                onPress: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WordActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPress;
  const WordActionButton({
    super.key,
    required this.icon,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white70,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.elliptical(7, 10)),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      elevation: 6,
      child: InkWell(
        onTap: onPress,
        borderRadius: BorderRadius.all(Radius.elliptical(7, 10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(
            icon,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
