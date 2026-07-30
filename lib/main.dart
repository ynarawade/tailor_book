import 'package:atelier/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/customer_bloc.dart';
import 'core/theme/atelier_theme.dart';
import 'core/theme/theme_controller.dart';

final themeController = ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CustomerBloc>(
          create: (context) =>
              CustomerBloc(), // or your Bloc initialization logic
        ),
      ],
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Atelier',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.themeMode,
            theme: AtelierTheme.lightTheme(),
            darkTheme: AtelierTheme.darkTheme(),

            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
