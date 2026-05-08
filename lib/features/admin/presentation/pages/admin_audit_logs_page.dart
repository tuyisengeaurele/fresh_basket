import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';

final _auditLogsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseService.auditLogs
      .orderBy('timestamp', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());
});

class AdminAuditLogsPage extends ConsumerStatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  ConsumerState<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends ConsumerState<AdminAuditLogsPage> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(_auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Filter by action or actor...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => QueryErrorView(error: e),
        data: (logs) {
          final filtered = _search.isEmpty
              ? logs
              : logs
                  .where((l) =>
                      (l['action'] as String? ?? '')
                          .toLowerCase()
                          .contains(_search.toLowerCase()) ||
                      (l['actorId'] as String? ?? '')
                          .toLowerCase()
                          .contains(_search.toLowerCase()))
                  .toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No audit logs', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _LogTile(log: filtered[i]),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? '';
    final actorId = log['actorId'] as String? ?? '';
    final actorName = log['actorName'] as String?;
    final targetId = log['targetId'] as String?;
    final targetType = log['targetType'] as String?;
    final details = log['details'] as Map<String, dynamic>?;
    final timestamp = log['timestamp'];
    DateTime? dt;
    if (timestamp != null) {
      try {
        dt = (timestamp as dynamic).toDate() as DateTime;
      } catch (_) {}
    }

    // Display actor: prefer name, fallback to truncated UID
    final actorDisplay = actorName?.isNotEmpty == true
        ? actorName!
        : (actorId.length > 12 ? '${actorId.substring(0, 12)}…' : actorId);

    final color = _actionColor(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_actionIcon(action), color: color, size: 18),
        ),
        title: Text(
          _formatAction(action),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(actorDisplay,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            if (targetId != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.label_outline_rounded,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${targetType ?? 'target'}: ${targetId.length > 10 ? '${targetId.substring(0, 10)}…' : targetId}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                details.entries
                    .take(2)
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' · '),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: dt != null
            ? Text(Formatters.relativeTime(dt),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint))
            : null,
        isThreeLine: true,
      ),
    );
  }

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  Color _actionColor(String action) {
    if (action.contains('approved') || action.contains('created')) return AppColors.success;
    if (action.contains('rejected') || action.contains('deleted') || action.contains('banned')) {
      return AppColors.error;
    }
    if (action.contains('updated') || action.contains('broadcast')) return AppColors.info;
    if (action.contains('suspended')) return AppColors.warning;
    return AppColors.textSecondary;
  }

  IconData _actionIcon(String action) {
    if (action.contains('driver')) return Icons.delivery_dining_rounded;
    if (action.contains('seller')) return Icons.store_outlined;
    if (action.contains('order')) return Icons.receipt_outlined;
    if (action.contains('notification')) return Icons.notifications_outlined;
    if (action.contains('user')) return Icons.person_outline_rounded;
    return Icons.history_rounded;
  }
}
