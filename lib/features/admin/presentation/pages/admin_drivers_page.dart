import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';

// Use asyncMap so errors propagate to the error: branch instead of silently
// becoming an empty list.
final _allDriversProvider = StreamProvider<List<_DriverWithUser>>((ref) {
  return FirebaseService.driverProfiles
      .limit(200)
      .snapshots()
      .asyncMap((snap) async {
    final profiles = <DriverProfile>[];
    for (final d in snap.docs) {
      try {
        profiles.add(DriverProfile.fromFirestore(d));
      } catch (e) {
        debugPrint('[AdminDrivers] profile parse error: $e');
      }
    }

    final result = <_DriverWithUser>[];
    for (final p in profiles) {
      try {
        final userDoc = await FirebaseService.users.doc(p.uid).get();
        if (userDoc.exists) {
          result.add(_DriverWithUser(
            profile: p,
            user: UserModel.fromFirestore(userDoc),
          ));
        }
      } catch (e) {
        debugPrint('[AdminDrivers] user fetch error for ${p.uid}: $e');
      }
    }

    // Sort newest first client-side
    result.sort((a, b) {
      final aTime = a.user.createdAt;
      final bTime = b.user.createdAt;
      return bTime.compareTo(aTime);
    });
    return result;
  });
});

class _DriverWithUser {
  final DriverProfile profile;
  final UserModel user;
  const _DriverWithUser({required this.profile, required this.user});
}

class AdminDriversPage extends ConsumerWidget {
  const AdminDriversPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(_allDriversProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Drivers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.adminCreateDriver),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Driver',
        child: const Icon(Icons.person_add_rounded, size: 26),
      ),
      body: driversAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => const ListItemSkeleton(),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 56, color: AppColors.error),
                const SizedBox(height: 12),
                const Text('Could not load drivers',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                // Show the real error — helps diagnose permission issues
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(_allDriversProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (drivers) {
          if (drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delivery_dining_outlined, size: 72, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No drivers yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Create a driver account to get started.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: drivers.length,
            itemBuilder: (_, i) => _DriverTile(data: drivers[i]),
          );
        },
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  final _DriverWithUser data;
  const _DriverTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.green100,
                  backgroundImage: data.user.photoUrl != null
                      ? NetworkImage(data.user.photoUrl!)
                      : null,
                  child: data.user.photoUrl == null
                      ? Text(data.user.fullName[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: data.profile.isAvailable ? AppColors.success : AppColors.textHint,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(data.user.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.two_wheeler_rounded, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(data.profile.vehicleType,
                          style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      if (data.profile.vehiclePlate != null) ...[
                        const Text(' · ', style: TextStyle(color: AppColors.textHint)),
                        Text(data.profile.vehiclePlate!,
                            style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(data.profile.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${data.profile.totalDeliveries} trips',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _toggleActive(data),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: data.user.isActive
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.user.isActive ? 'Active' : 'Banned',
                      style: TextStyle(
                        color: data.user.isActive ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(_DriverWithUser data) async {
    await FirebaseService.users
        .doc(data.user.uid)
        .update({'isActive': !data.user.isActive, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
