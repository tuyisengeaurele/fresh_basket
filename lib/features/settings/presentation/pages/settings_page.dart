import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../shared/providers/theme_provider.dart' show themeProvider;

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _SectionLabel(label: 'Appearance'),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: isDark ? Colors.indigo : AppColors.warning,
            title: 'Dark Mode',
            trailing: CupertinoSwitch(
              value: isDark,
              onChanged: (v) => ref
                  .read(themeProvider.notifier)
                  .setTheme(v ? ThemeMode.dark : ThemeMode.light),
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            title: 'Edit Profile',
            onTap: () => context.push(RouteNames.editProfile),
          ),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.accent,
            title: 'Saved Addresses',
            onTap: () => context.push(RouteNames.addresses),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.info,
            title: 'Change Password',
            onTap: () => context.push(RouteNames.forgotPassword),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.warning,
            title: 'Notification Preferences',
            subtitle: 'Manage push notification settings',
            onTap: () => context.push(RouteNames.notificationPreferences),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'App Version',
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Text(
                snap.data != null ? 'v${snap.data!.version}' : '...',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.textSecondary,
            title: 'Privacy Policy',
            onTap: () => context.push(RouteNames.privacyPolicy),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.textSecondary,
            title: 'Terms of Service',
            onTap: () => context.push(RouteNames.termsOfService),
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'Danger Zone'),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.error,
            title: 'Delete Account',
            titleColor: AppColors.error,
            onTap: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please contact support to delete your account.')),
      );
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20)
                : null),
      ),
    );
  }
}
