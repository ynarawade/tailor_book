//
// Hosts the bottom nav and switches between the two top-level tabs.
// HomeScreen (Clients) and BackupScreen live here as persistent pages
// so their state is preserved when switching tabs.

import 'package:flutter/material.dart';
import 'package:tailor_book/widgets/tb_bottom_nav.dart';

import 'backup_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _pages = [HomeScreen(), BackupScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: TbBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
