import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/seed_data.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _platformSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseService.platformSettings
      .doc('config')
      .snapshots()
      .map((s) => s.data() ?? {});
});

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  final _deliveryFeeCtrl = TextEditingController();
  final _freeDeliveryThresholdCtrl = TextEditingController();
  final _supportPhoneCtrl = TextEditingController();
  bool _maintenanceMode = false;
  bool _registrationOpen = true;
  bool _saving = false;
  bool _seeding = false;
  bool _loaded = false;

  void _loadSettings(Map<String, dynamic> data) {
    if (!_loaded) {
      _deliveryFeeCtrl.text = (data['deliveryFee'] ?? 500).toString();
      _freeDeliveryThresholdCtrl.text = (data['freeDeliveryThreshold'] ?? 5000).toString();
      _supportPhoneCtrl.text = data['supportPhone'] ?? '+250 780 605 880';
      _maintenanceMode = data['maintenanceMode'] ?? false;
      _registrationOpen = data['registrationOpen'] ?? true;
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _deliveryFeeCtrl.dispose();
    _freeDeliveryThresholdCtrl.dispose();
    _supportPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(_platformSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Suppress errors — brief permission-denied fires during sign-out.
        error: (e, _) => const SizedBox.shrink(),
        data: (settings) {
          _loadSettings(settings);
          final admin = ref.watch(authNotifierProvider).value;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Admin profile card ───────────────────────────────
              _AdminProfileCard(admin: admin),
              const SizedBox(height: 20),

              _SettingsCard(
                title: 'Delivery Settings',
                children: [
                  TextFormField(
                    controller: _deliveryFeeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Fee (RWF)',
                      prefixIcon: Icon(Icons.delivery_dining_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _freeDeliveryThresholdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Free Delivery Threshold (RWF)',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                      helperText: 'Orders above this amount get free delivery',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Support',
                children: [
                  TextFormField(
                    controller: _supportPhoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Support Phone',
                      prefixIcon: Icon(Icons.support_agent_rounded),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Platform Control',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Maintenance Mode',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text(
                        'Disables the app for all non-admin users',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: CupertinoSwitch(
                      value: _maintenanceMode,
                      onChanged: (v) => setState(() => _maintenanceMode = v),
                      activeColor: AppColors.error,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Open Registration',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Allow new users to register',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: CupertinoSwitch(
                      value: _registrationOpen,
                      onChanged: (v) => setState(() => _registrationOpen = v),
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Settings'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: _seeding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.science_outlined),
                  label: Text(_seeding ? 'Seeding...' : 'Seed Test Accounts'),
                  onPressed: (_saving || _seeding) ? null : _runSeed,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // ── Sign out ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Sign Out',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _confirmSignOut(context),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _runSeed() async {
    setState(() => _seeding = true);
    try {
      final results = await SeedData.run();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Seed Complete'),
          content: SingleChildScrollView(
            child: Text(results.join('\n')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seed failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate first — prevents Firestore streams from briefly
              // showing permission-denied errors during sign-out transition.
              context.go(RouteNames.login);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseService.platformSettings.doc('config').set({
        'deliveryFee': int.tryParse(_deliveryFeeCtrl.text) ?? 500,
        'freeDeliveryThreshold': int.tryParse(_freeDeliveryThresholdCtrl.text) ?? 5000,
        'supportPhone': _supportPhoneCtrl.text.trim(),
        'maintenanceMode': _maintenanceMode,
        'registrationOpen': _registrationOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AdminProfileCard extends StatelessWidget {
  final dynamic admin; // UserModel?
  const _AdminProfileCard({required this.admin});

  @override
  Widget build(BuildContext context) {
    if (admin == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage:
                admin.photoUrl != null ? NetworkImage(admin.photoUrl!) : null,
            child: admin.photoUrl == null
                ? Text(
                    admin.fullName.isNotEmpty ? admin.fullName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.fullName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text(admin.email,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Admin',
                style: TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

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
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
