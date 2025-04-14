import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vocafusion/config/custom_router.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/auth_cubit.dart';
import 'package:vocafusion/cubits/content_cubit.dart';
import 'package:vocafusion/cubits/learning/learning_session_cubit.dart';
import 'package:vocafusion/cubits/learning/sr_cubit.dart';
import 'package:vocafusion/cubits/onboarding_cubit.dart';
import 'package:vocafusion/cubits/premium_cubit.dart';
import 'package:vocafusion/cubits/streak_cubit.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';
import 'package:vocafusion/startup.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sembast/sembast_io.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // await SentryFlutter.init((options) {
  //   options.dsn =
  //       'https://6bd7170267ea55c71dbc51d7d40935f3@o4508544912850944.ingest.us.sentry.io/4508829718806528';

  //   options.tracesSampleRate = kReleaseMode ? 0.5 : 0;
  //   options.profilesSampleRate = kReleaseMode ? 0.1 : 0;
  //   options.sampleRate = kReleaseMode ? 0.1 : 0;
  //   options.debug = !kReleaseMode;
  // });

  FlutterError.onError = (FlutterErrorDetails details) {
    // Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Sentry.captureException(error, stackTrace: stack);
    return true;
  };

  if (Platform.isAndroid) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    Future.delayed(const Duration(seconds: 2), () {
      FlutterNativeSplash.remove();
    });
  }

  if (Platform.isAndroid) {
    // final config =
    //     PostHogConfig('phc_qKJNHn1RX2l75TYuzvr2zbToLu2ilYTI1n8k6lTqXIK');
    // // config.debug = true;
    // config.captureApplicationLifecycleEvents = true;
    // config.debug = !kReleaseMode;
    // config.host = 'https://eu.i.posthog.com';

    // await Posthog().setup(config);
  }

  prefetchDNS();

  /// Initialize the Storages
  final dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);

  final db = await databaseFactoryIo.openDatabase(
    join(dir.path, 'me.laknabil.vocafusion_v0.09.db'),
  );
  await setUpLocator(sembastInstance: db);

  final blocHydartionPath = Directory(
      join(dir.path, 'hydrated_bloc${PreferenceExtension.globalPrefix}'));
  await blocHydartionPath.create(recursive: true);

  HydratedBloc.storage =
      await HydratedStorage.build(storageDirectory: blocHydartionPath);

  /////
  await initializeDateFormatting(Platform.localeName);
  tz.initializeTimeZones();

  EquatableConfig.stringify = true;

  ////

  // await FirebaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit()..init(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => ContentCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => SrCubit()..sync(context),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => StreakCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => OnboardingCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => PremiumCubit()..sync(context),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => LearningSessionCubit()..sync(context),
          lazy: false,
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: [
          AppLocalizations.delegate, // Add this line
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
        ],
        debugShowCheckedModeBanner: false,
        title: 'VocaFusion',
        locale: const Locale('en'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          textTheme: GoogleFonts.vazirmatnTextTheme(),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
