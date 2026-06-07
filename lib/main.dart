// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/customer_bloc.dart';
import 'bloc/customer_event.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(const TailorBookApp());
}

class TailorBookApp extends StatelessWidget {
  const TailorBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CustomerBloc()..add(LoadCustomers())),
      ],
      child: MaterialApp(
        title: 'TailorBook',
        theme: AppTheme.dark,
        home: const MainShell(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
