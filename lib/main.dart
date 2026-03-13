// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:provider/provider.dart';
import 'package:where_ma_money_go/blocs/auth/auth_bloc.dart';
import 'package:where_ma_money_go/blocs/auth/auth_event.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_bloc.dart';
import 'package:where_ma_money_go/blocs/envelop/envelop_bloc.dart';
import 'package:where_ma_money_go/blocs/notes/notes_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/providers/user/user_provider.dart';
import 'package:where_ma_money_go/repositories/auth_repository.dart';
import 'package:where_ma_money_go/repositories/bills_repository.dart';
import 'package:where_ma_money_go/repositories/category_repository.dart';
import 'package:where_ma_money_go/repositories/envelop_repository.dart';
import 'package:where_ma_money_go/repositories/notes_repository.dart';
import 'package:where_ma_money_go/repositories/saving_repository.dart';
import 'package:where_ma_money_go/screens/dashboard.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';
import 'package:where_ma_money_go/screens/login.dart';
import 'package:where_ma_money_go/screens/main_shell.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE INITIALIZATION
  // ============================================================
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => BillsBloc(
              billsRepository: BillsRepository(),
              savingRepository: SavingRepository(),
              envelopRepository: EnvelopRepository(),
            ),
          ),
          BlocProvider(
            create: (_) =>
                CategoryBloc(categoryRepository: CategoryRepository()),
          ),
          BlocProvider(
            create: (ctx) => AuthBloc(
              authRepository: AuthRepository(),
              userProvider: ctx.read<UserProvider>(),
            )..add(AuthCheckCurrentUser()),
          ),
          BlocProvider(
            create: (_) => SavingBloc(savingRepository: SavingRepository()),
          ),
          BlocProvider(
            create: (context) => EnvelopBloc(
              repository: EnvelopRepository(),
              billsBloc: context.read<BillsBloc>(),
            ),
          ),
          BlocProvider(
            create: (_) => NotesBloc(noteRepository: NotesRepository()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void updateSystemUI(ThemeProvider themeProvider) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeProvider.isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: themeProvider.colors.background,
        systemNavigationBarIconBrightness: themeProvider.isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    updateSystemUI(themeProvider);

    return MaterialApp(
      title: 'Where Ma Money Go?',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.lightSurface,
          error: AppColors.error,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.darkSurface,
          error: AppColors.error,
        ),
      ),
      home: LoginScreen(),
    );
  }
}
