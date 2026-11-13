import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

class TeamMembersCard extends StatelessWidget {
  const TeamMembersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final members = c.teamMembers;
    final hasTeam = members.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasTeam ? () => _showTeamSheet(context) : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: rcCardDecoration(),
          child: Row(
            children: [
              if (hasTeam) ...[
                _AvatarStack(names: members.map((m) => m['name'].toString()).toList()),
                const SizedBox(width: 12),
              ] else ...[
                const Icon(Icons.person_outline, color: RC.muted, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTeam
                          ? '${members.length} đồng đội cùng ca'
                          : 'Chỉ mình bạn tiếp nhận ca này',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RC.ink,
                      ),
                    ),
                    if (hasTeam) ...[
                      const SizedBox(height: 2),
                      Text(
                        _summary(members),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: RC.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasTeam) const Icon(Icons.chevron_right, color: RC.muted),
            ],
          ),
        ),
      ),
    );
  }

  static String _summary(List<Map<String, dynamic>> members) {
    final counts = <String, int>{};
    for (final m in members) {
      final s = m['status'].toString();
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.value} ${e.key.toLowerCase()}').join(' · ');
  }

  void _showTeamSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: context.read<RescueProcessController>(),
        child: const _TeamSheet(),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> names;
  const _AvatarStack({required this.names});

  @override
  Widget build(BuildContext context) {
    final shown = names.take(3).toList();
    return SizedBox(
      width: 32 + (shown.length - 1) * 20.0,
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RC.blueSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  shown[i].isNotEmpty ? shown[i].trim().split(' ').last[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RC.blue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamSheet extends StatelessWidget {
  const _TeamSheet();

  static Color _statusColor(String s) {
    switch (s) {
      case 'Hoàn thành':
        return RC.green;
      case 'Đã hủy':
      case 'Đã từ chối':
        return RC.red;
      case 'Đang cứu nạn':
        return RC.redDark;
      case 'Đã đến nơi':
        return RC.blue;
      default:
        return RC.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final members = c.teamMembers;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RcGrabHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Đồng đội cùng ca (${members.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: RC.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: RC.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: RC.line),
          Flexible(
            child: members.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Chưa có đồng đội nào khác cùng tiếp nhận ca này.',
                        style: TextStyle(color: RC.muted),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: members.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: RC.line),
                    itemBuilder: (context, i) {
                      final m = members[i];
                      final status = m['status'].toString();
                      final color = _statusColor(status);
                      final phone = m['phone'].toString();
                      final name = m['name'].toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: RC.blueSoft,
                              child: Text(
                                name.isNotEmpty ? name.trim().split(' ').last[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: RC.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: RC.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m['role'].toString(),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: RC.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RcPill(
                                    text: status,
                                    fg: color,
                                    bg: color.withOpacity(0.10),
                                  ),
                                ],
                              ),
                            ),
                            if (phone.isNotEmpty)
                              RcRoundButton(
                                icon: Icons.phone,
                                color: RC.green,
                                tooltip: 'Gọi $name',
                                onTap: () {
                                  Navigator.pop(context);
                                  c.makePhoneCall(phone);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
