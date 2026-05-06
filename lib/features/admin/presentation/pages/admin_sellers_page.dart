import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';

final _allSellerProfilesProvider =
    StreamProvider<List<_SellerWithUser>>((ref) async* {
  final snapshots = FirebaseService.sellerProfiles
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots();

  await for (final snap in snapshots) {
    final profiles = snap.docs.map((d) => SellerProfile.fromFirestore(d)).toList();
    final withUsers = <_SellerWithUser>[];
    for (final p in profiles) {
      try {
        final userDoc = await FirebaseService.users.doc(p.uid).get();
        if (userDoc.exists) {
          withUsers.add(_SellerWithUser(
            profile: p,
            user: UserModel.fromFirestore(userDoc),
          ));
        }
      } catch (_) {}
    }
    yield withUsers;
  }
});

class _SellerWithUser {
  final SellerProfile profile;
  final UserModel user;
  const _SellerWithUser({required this.profile, required this.user});
}

class AdminSellersPage extends ConsumerStatefulWidget {
  const AdminSellersPage({super.key});

  @override
  ConsumerState<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends ConsumerState<AdminSellersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _statuses = [null, SellerStatus.pending, SellerStatus.approved, SellerStatus.rejected];
  static const _labels = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(_allSellerProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sellers'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: sellersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => const ListItemSkeleton(),
        ),
        error: (e, _) => QueryErrorView(error: e),
        data: (sellers) => TabBarView(
          controller: _tabController,
          children: _statuses.map((status) {
            final filtered = status == null
                ? sellers
                : sellers.where((s) => s.profile.status == status).toList();
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_outlined, size: 64, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('No sellers', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _SellerTile(
                data: filtered[i],
                onApprove: () => _approveSeller(filtered[i]),
                onReject: () => _rejectSeller(context, filtered[i]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _approveSeller(_SellerWithUser data) async {
    await FirebaseService.sellerProfiles.doc(data.profile.uid).update({
      'status': SellerStatus.approved.name,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseService.users.doc(data.profile.uid).update({
      'role': 'seller',
      'isActive': true,
    });
    try {
      await EmailService.sendSellerApproval(
        to: data.user.email,
        name: data.user.fullName,
        approved: true,
      );
    } catch (_) {}
    await FirebaseService.logAudit(
      action: 'seller_approved',
      actorId: FirebaseService.currentUid ?? '',
      actorName: 'Admin',
      targetId: data.profile.uid,
      targetType: 'seller_profile',
      details: {'businessName': data.profile.businessName},
    );
  }

  Future<void> _rejectSeller(BuildContext context, _SellerWithUser data) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejecting ${data.profile.businessName}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseService.sellerProfiles.doc(data.profile.uid).update({
        'status': SellerStatus.rejected.name,
        'rejectionReason': reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      });
      // Reset user role back to customer on rejection
      await FirebaseService.users.doc(data.profile.uid).update({
        'role': 'customer',
      });
      await FirebaseService.logAudit(
        action: 'seller_rejected',
        actorId: FirebaseService.currentUid ?? '',
        actorName: 'Admin',
        targetId: data.profile.uid,
        targetType: 'seller_profile',
        details: {
          'businessName': data.profile.businessName,
          'reason': reasonCtrl.text.trim(),
        },
      );
    }
    reasonCtrl.dispose();
  }
}

class _SellerTile extends StatelessWidget {
  final _SellerWithUser data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SellerTile({
    required this.data,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      SellerStatus.pending: AppColors.warning,
      SellerStatus.approved: AppColors.success,
      SellerStatus.rejected: AppColors.error,
      SellerStatus.suspended: AppColors.error,
    };
    final color = statusColors[data.profile.status] ?? AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      data.profile.businessName[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.profile.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(data.user.fullName,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(data.user.email,
                          style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(data.profile.storeAddress,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data.profile.status.name,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (data.profile.status == SellerStatus.pending)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Text(
                    'Applied ${Formatters.relativeTime(data.profile.createdAt)}',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
