import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/content_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/favorites_repository.dart';

class FavScreen extends StatefulWidget {
  const FavScreen({Key? key}) : super(key: key);

  @override
  State<FavScreen> createState() => _FavScreenState();
}

class _FavScreenState extends State<FavScreen> {
  List<String> favoriteIds = [];
  List<WordCard> favoriteWords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    final favRepository = locator.get<FavoritesRepository>();
    final ids = await favRepository.getFavorites();

    final allWords = context.read<ContentCubit>().state.words;
    final favoriteWords =
        allWords.where((word) => ids.contains(word.id)).toList();

    setState(() {
      this.favoriteIds = ids;
      this.favoriteWords = favoriteWords;
      isLoading = false;
    });
  }

  Future<void> _removeFromFavorites(String id) async {
    final favRepository = locator.get<FavoritesRepository>();
    await favRepository.toggleFavorite(id);
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            Divider(),

            // Content
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : favoriteWords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No favorites yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap the heart icon on a word to add it to favorites',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(16),
                          itemCount: favoriteWords.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final word = favoriteWords[index];
                            return FavoriteWordCard(
                              word: word,
                              onRemove: () => _removeFromFavorites(word.id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteWordCard extends StatelessWidget {
  final WordCard word;
  final VoidCallback onRemove;

  const FavoriteWordCard({
    Key? key,
    required this.word,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                word.word,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF0307),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                onPressed: onRemove,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            word.definition,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            word.context,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
