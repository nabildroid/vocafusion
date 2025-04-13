import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:vocafusion/repositories/content_repository.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';
import 'package:vocafusion/repositories/progress_repository.dart';
import 'package:vocafusion/repositories/user_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:vocafusion/repositories/favorites_repository.dart';

final GetIt locator = GetIt.instance;

Future<void> setUpLocator({required Database sembastInstance}) async {
  locator.registerSingleton(Logger());
  locator.registerSingleton(sembastInstance);

  locator.registerSingleton(PreferenceRepository());
  locator.registerSingleton(UserRepository()..getUser());
  locator.registerSingleton(ProgressRepository());
  locator.registerSingleton(ContentRepository());
  locator.registerLazySingleton(() => FavoritesRepository());

  locator.registerSingleton(RouteObserver<ModalRoute<dynamic>>());
}
