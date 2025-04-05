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
                icon: Icon(
                  isLoading
                      ? Icons.hourglass_empty
                      : isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: isLoading ? null : _toggleFavorite,
                iconSize: 21,
              ),
              Spacer(),
              Text(
                widget.item.word,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffFF0307),
                ),
              ),
              Spacer(),
              Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.definition,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          TextWithTextHighlited(
            widget.item.context,
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
