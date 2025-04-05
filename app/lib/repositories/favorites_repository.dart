import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  static const String _favoritesKey = 'favorites';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites;
  }

  Future<bool> toggleFavorite(String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];

    bool isFavorite = false;
    if (favorites.contains(wordId)) {
      favorites.remove(wordId);
    } else {
      favorites.add(wordId);
      isFavorite = true;
    }

    await prefs.setStringList(_favoritesKey, favorites);
    return isFavorite;
  }

  Future<bool> isFavorite(String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites.contains(wordId);
  }
}
