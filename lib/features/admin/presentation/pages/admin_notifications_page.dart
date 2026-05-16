import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../shared/models/user_model.dart';

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends ConsumerState<AdminNotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  UserRole? _targetRole;
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Notification')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.campaign_rounded, color: AppColors.warning, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Broadcast notifications are sent to all users of the selected role, or all users if no role is selected.',
                    style: TextStyle(fontSize: 13, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Card(
            title: 'Target Audience',
            child: DropdownButtonFormField<UserRole?>(
              value: _targetRole,
              decoration: const InputDecoration(
                labelText: 'Target Role',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              items: [
                const DropdownMenuItem<UserRole?>(value: null, child: Text('All Users')),
                ...UserRole.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name[0].toUpperCase() + r.name.substring(1) + 's'),
                    )),
              ],
              onChanged: (v) => setState(() => _targetRole = v),
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Message',
            child: Column(
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Notification Title'),
                  maxLength: 60,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bodyCtrl,
                  decoration: const InputDecoration(labelText: 'Message Body'),
                  maxLines: 4,
                  maxLength: 240,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Send Notification'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and message.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      // Fetch target user UIDs
      Query<Map<String, dynamic>> q = FirebaseService.users.where('isActive', isEqualTo: true);
      if (_targetRole != null) {
        q = q.where('role', isEqualTo: _targetRole!.name);
      }
      final snap = await q.get();

      // Batch-write notifications
      final batch = FirebaseService.firestore.batch();
      for (final doc in snap.docs) {
        final notifRef = FirebaseService.notifications.doc();
        batch.set(notifRef, {
          'userId': doc.id,
          'title': _titleCtrl.text.trim(),
          'body': _bodyCtrl.text.trim(),
          'type': 'broadcast',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {'targetRole': _targetRole?.name ?? 'all'},
        });
      }
      await batch.commit();

      // Log audit
      await FirebaseService.logAudit(
        action: 'broadcast_notification',
        actorId: FirebaseService.currentUid ?? '',
        actorName: 'Admin',
        details: {
          'title': _titleCtrl.text.trim(),
          'targetRole': _targetRole?.name ?? 'all',
          'recipientCount': snap.docs.length,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Notification sent to ${snap.docs.length} user${snap.docs.length != 1 ? 's' : ''}'),
            backgroundColor: AppColors.primary,
          ),
        );
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() => _targetRole = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
