import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _driverProfileStreamProvider = StreamProvider.family<DriverProfile?, String>((ref, uid) {
  return FirebaseService.driverProfiles
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? DriverProfile.fromFirestore(s) : null);
});

class DriverProfilePage extends ConsumerWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final profileAsync = ref.watch(_driverProfileStreamProvider(user.uid));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Profile'),
            actions: [
              TextButton(
                onPressed: () {
                  // Navigate first — prevents Firestore streams from briefly
                  // showing permission-denied errors during sign-out transition.
                  context.go(RouteNames.login);
                  ref.read(authNotifierProvider.notifier).signOut();
                },
                child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
          body: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            // Suppress errors — a brief permission-denied fires during sign-out
            // as Firestore streams react to auth change. SizedBox.shrink() means
            // nothing is shown for that single frame before login renders.
            error: (e, _) => const SizedBox.shrink(),
            data: (profile) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _AvatarSection(user: user),
                const SizedBox(height: 20),
                if (profile != null) ...[
                  _AvailabilityToggle(profile: profile, uid: user.uid),
                  const SizedBox(height: 16),
                  _StatsCard(profile: profile),
                  const SizedBox(height: 16),
                  _VehicleCard(profile: profile),
                ],
                const SizedBox(height: 16),
                _InfoCard(user: user),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final UserModel user;
  const _AvatarSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.green100,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(user.fullName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 10),
          Text(user.fullName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(user.email,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delivery_dining_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Driver', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityToggle extends ConsumerWidget {
  final DriverProfile profile;
  final String uid;
  const _AvailabilityToggle({required this.profile, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: profile.isAvailable ? AppColors.green50 : AppColors.orange50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: profile.isAvailable
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            profile.isAvailable
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: profile.isAvailable ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.isAvailable ? 'Available for Deliveries' : 'Currently Unavailable',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  profile.isAvailable
                      ? 'You will receive new orders'
                      : 'Toggle on to start receiving orders',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: profile.isAvailable,
            onChanged: (v) => FirebaseService.driverProfiles
                .doc(uid)
                .update({'isAvailable': v, 'updatedAt': FieldValue.serverTimestamp()}),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final DriverProfile profile;
  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          _Stat(
            label: 'Deliveries',
            value: '${profile.totalDeliveries}',
            icon: Icons.local_shipping_outlined,
            color: AppColors.primary,
          ),
          SizedBox(height: 40, child: const VerticalDivider()),
          _Stat(
            label: 'Rating',
            value: profile.rating.toStringAsFixed(1),
            icon: Icons.star_rounded,
            color: AppColors.warning,
          ),
          SizedBox(height: 40, child: const VerticalDivider()),
          _Stat(
            label: 'Earned',
            value: Formatters.compact(profile.totalEarnings),
            icon: Icons.payments_outlined,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final DriverProfile profile;
  const _VehicleCard({required this.profile});

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
          const Text('Vehicle Information',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Divider(height: 20),
          _InfoRow(icon: Icons.two_wheeler_rounded, label: 'Type', value: profile.vehicleType),
          if (profile.vehiclePlate != null)
            _InfoRow(icon: Icons.pin_outlined, label: 'Plate', value: profile.vehiclePlate!),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

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
          const Text('Contact Information',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Divider(height: 20),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
          if (user.phone != null)
            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phone!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
