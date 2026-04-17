import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _sellerProfileProvider =
    StreamProvider.family<SellerProfile?, String>((ref, uid) {
  return FirebaseService.sellerProfiles
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? SellerProfile.fromFirestore(s) : null);
});

class SellerStorePage extends ConsumerStatefulWidget {
  const SellerStorePage({super.key});

  @override
  ConsumerState<SellerStorePage> createState() => _SellerStorePageState();
}

class _SellerStorePageState extends ConsumerState<SellerStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _tinCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _tinCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile(SellerProfile profile) {
    if (!_loaded) {
      _businessNameCtrl.text = profile.businessName;
      _addressCtrl.text = profile.storeAddress;
      _tinCtrl.text = profile.tinNumber ?? '';
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final profileAsync = ref.watch(_sellerProfileProvider(user.uid));

        return Scaffold(
          appBar: AppBar(title: const Text('My Store')),
          body: profileAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox.shrink(),
            data: (profile) {
              if (profile != null) _initFromProfile(profile);

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StoreAvatar(
                      businessName:
                          profile?.businessName ?? user.fullName),
                  const SizedBox(height: 24),

                  // ── Read-only info view ─────────────────────────
                  if (!_isEditing)
                    _StoreInfoViewCard(
                      profile: profile,
                      onEdit: () => setState(() => _isEditing = true),
                    ),

                  // ── Edit form ───────────────────────────────────
                  if (_isEditing)
                    _InfoCard(
                      title: 'Edit Store Information',
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _businessNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Business Name',
                                prefixIcon: Icon(Icons.store_outlined),
                              ),
                              validator: Validators.required,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Store Address',
                                prefixIcon:
                                    Icon(Icons.location_on_outlined),
                              ),
                              validator: Validators.required,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _tinCtrl,
                              decoration: const InputDecoration(
                                labelText: 'TIN Number (optional)',
                                prefixIcon:
                                    Icon(Icons.numbers_rounded),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _saving
                                        ? null
                                        : () => setState(
                                            () => _isEditing = false),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _saving
                                        ? null
                                        : () => _save(user.uid),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white),
                                          )
                                        : const Text('Save Changes'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (profile != null) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Store Stats',
                      child: Row(
                        children: [
                          _StatTile(
                              icon: Icons.star_rounded,
                              label: 'Rating',
                              value:
                                  profile.rating.toStringAsFixed(1),
                              color: AppColors.warning),
                          const VerticalDivider(),
                          _StatTile(
                              icon: Icons.rate_review_outlined,
                              label: 'Reviews',
                              value: '${profile.totalReviews}',
                              color: AppColors.info),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Sign Out ────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    label: const Text('Sign Out',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side:
                          const BorderSide(color: AppColors.error, width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(RouteNames.login);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseService.sellerProfiles.doc(uid).set({
        'uid': uid,
        'businessName': _businessNameCtrl.text.trim(),
        'storeAddress': _addressCtrl.text.trim(),
        'tinNumber': _tinCtrl.text.trim().isEmpty
            ? null
            : _tinCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _saving = false;
          _isEditing = false; // Return to view mode on success
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── Store info read-only card ──────────────────────────────────────────────────

class _StoreInfoViewCard extends StatelessWidget {
  final SellerProfile? profile;
  final VoidCallback onEdit;
  const _StoreInfoViewCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Store Information',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                onPressed: onEdit,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const Divider(height: 20),
          if (profile == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'No store information yet. Tap Edit to add your details.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else ...[
            _InfoRow(Icons.store_outlined, 'Business Name',
                profile!.businessName),
            _InfoRow(Icons.location_on_outlined, 'Address',
                profile!.storeAddress),
            if (profile!.tinNumber != null)
              _InfoRow(
                  Icons.numbers_rounded, 'TIN', profile!.tinNumber!),
          ],
        ],
      ),
    );
  }

  Widget _InfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label:  ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _StoreAvatar extends StatelessWidget {
  final String businessName;
  const _StoreAvatar({required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.green100,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: Text(
                businessName.isNotEmpty
                    ? businessName[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(businessName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
