import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/theme_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Header
                _ProfileHeader(user: user),
                const SizedBox(height: AppDimensions.lg),

                // Menu
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  title: AppStrings.editProfile,
                  onTap: () => context.push(RouteNames.editProfile),
                  index: 0,
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  title: AppStrings.myAddresses,
                  onTap: () => context.push(RouteNames.addresses),
                  index: 1,
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: AppStrings.notifications,
                  onTap: () => context.push(RouteNames.notifications),
                  index: 2,
                ),
                const Divider(
                    indent: AppDimensions.pagePadding,
                    endIndent: AppDimensions.pagePadding),
                _MenuItem(
                  icon: Icons.dark_mode_outlined,
                  title: AppStrings.darkMode,
                  onTap: null,
                  trailing: CupertinoSwitch(
                    value: isDark,
                    onChanged: (v) => ref
                        .read(themeProvider.notifier)
                        .setTheme(
                            v ? ThemeMode.dark : ThemeMode.light),
                    activeColor: AppColors.primary,
                  ),
                  index: 3,
                ),
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  title: AppStrings.helpSupport,
                  onTap: () => context.push(RouteNames.helpSupport),
                  index: 4,
                ),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: AppStrings.privacyPolicy,
                  onTap: () => context.push(RouteNames.privacyPolicy),
                  index: 5,
                ),
                const Divider(
                    indent: AppDimensions.pagePadding,
                    endIndent: AppDimensions.pagePadding),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  title: AppStrings.logout,
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () => _confirmSignOut(context, ref),
                  index: 6,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      // Use rootNavigator so the dialog sits on top of the ShellRoute navigator
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;

  const _ProfileHeader({required this.user});

  Color get _roleColor {
    switch (user?.role) {
      case UserRole.seller:
        return AppColors.roleSeller;
      case UserRole.driver:
        return AppColors.roleDriver;
      case UserRole.admin:
        return AppColors.roleAdmin;
      default:
        return AppColors.roleCustomer;
    }
  }

  String get _roleName {
    switch (user?.role) {
      case UserRole.seller:
        return 'Seller';
      case UserRole.driver:
        return 'Driver';
      case UserRole.admin:
        return 'Admin';
      default:
        return 'Customer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.paddingOf(context).top + 24, 24, 32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: AppDimensions.avatarXl,
                height: AppDimensions.avatarXl,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.35), width: 3),
                ),
                child: ClipOval(
                  child: user?.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: user!.photoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(
                            child: Text(
                              user?.fullName.isNotEmpty == true
                                  ? user!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          )
              .animate()
              .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? 'Guest',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _roleColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _roleName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final int index;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textHint,
                )
              : null),
      onTap: onTap,
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05);
  }
}
