import 'package:flutter/material.dart';

import '../features/XacMinh/models/xac_minh_model.dart';

const xmBlue = Color(0xFF1565C0),
    xmInk = Color(0xFF193052),
    xmMuted = Color(0xFF71829B);
const xmCanvas = Color(0xFFF6F7FB), xmBorder = Color(0xFFE0E7F0);
ThemeData verificationTheme(BuildContext context) => Theme.of(context).copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: xmBlue,
    primary: xmBlue,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: xmCanvas,
  textTheme: Theme.of(
    context,
  ).textTheme.apply(bodyColor: xmInk, displayColor: xmInk),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: xmInk,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: xmInk,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: xmInk, size: 22),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: xmBorder),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: xmBorder,
    space: 24,
    thickness: 1,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: xmBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: xmBlue,
      minimumSize: const Size(0, 44),
      side: const BorderSide(color: Color(0xFFBCD0E8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: xmBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: xmBorder),
    ),
  ),
);

class XmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const XmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: xmBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F2947),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class XmPanel extends StatelessWidget {
  final String label;
  final Widget child;
  const XmPanel({super.key, required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEEF2F6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: xmMuted, fontSize: 13)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

Widget xmHeading(String text) => Text(
  text.toUpperCase(),
  style: const TextStyle(
    color: xmMuted,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: .4,
  ),
);
Color xmStatusColor(String status) => switch (status) {
  'da_duyet' => const Color(0xFF059669),
  'tu_choi' || 'khoa' => const Color(0xFFDC2626),
  _ => const Color(0xFFE58A00),
};

class XmStatus extends StatelessWidget {
  final String status;
  const XmStatus(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = xmStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'da_duyet' ? Icons.check_circle_outline : Icons.schedule,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            verificationStatuses[status] ?? status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class XmAvatar extends StatelessWidget {
  final String name, collection;
  const XmAvatar(this.name, this.collection, {super.key});
  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = words
        .take(2)
        .map((s) => s.characters.first)
        .join()
        .toUpperCase();
    final color = collection == profileCollections.first
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF0F766E);
    return CircleAvatar(
      radius: 25,
      backgroundColor: color.withValues(alpha: .13),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class XmType extends StatelessWidget {
  final String collection;
  const XmType(this.collection, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = collection == profileCollections.first
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        verificationTypes[collection] ?? 'Chưa xác định',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
