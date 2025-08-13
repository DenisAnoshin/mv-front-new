import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/telegram_login_page.dart';
import 'pages/chat_list_page.dart';
import 'stores/chat_store.dart';
import 'stores/user_store.dart';
import 'theme/telegram_colors.dart';
import 'pages/home_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStore>(create: (_) => UserStore()),
        ChangeNotifierProvider<ChatStore>(create: (_) => ChatStore()),
      ],
      child: const MultivisionApp(),
    ),
  );
}

class MultivisionApp extends StatelessWidget {
  const MultivisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telegram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: TelegramColors.primary,
          primary: TelegramColors.primary,
          background: TelegramColors.background,
        ),
        scaffoldBackgroundColor: TelegramColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: TelegramColors.appBarBackground,
          foregroundColor: TelegramColors.appBarText,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: TelegramColors.primary,
          foregroundColor: TelegramColors.textOnPrimary,
        ),
        useMaterial3: true,
      ),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = context.read<UserStore>().initializeSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: TelegramColors.background,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TelegramColors.primary),
              ),
            ),
          );
        }

        final isLoggedIn = context.watch<UserStore>().isLoggedIn;
        return isLoggedIn ? const HomeShell() : const TelegramLoginPage();
      },
    );
  }
}
