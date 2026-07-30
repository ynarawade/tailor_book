import 'package:atelier/core/theme/atelier_theme.dart';
import 'package:flutter/material.dart';

class TbAvatar extends StatelessWidget {
  const TbAvatar({super.key, required this.name, this.radius = 24});

  final String name;
  final double radius;

  String get _initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB955), Color(0xFFF5A623)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: AtelierTheme.brandPrimary,
        ).copyWith(fontSize: radius * 0.75, fontWeight: FontWeight.w700),
      ),
    );
  }
}
