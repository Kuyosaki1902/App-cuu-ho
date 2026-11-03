import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color primaryColor;

  const CustomAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24.0,
    this.primaryColor = const Color(0xFF006A55),
  });

  // Hàm cắt chữ cái đầu
  String getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    String firstLetter = words.first.substring(0, 1);
    String lastLetter = words.last.substring(0, 1);
    return '$firstLetter$lastLetter'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: primaryColor,
      backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: !hasAvatar
          ? Text(
              getInitials(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.7, // Scale chữ vừa vặn khung tròn
              ),
            )
          : null,
    );
  }
}
