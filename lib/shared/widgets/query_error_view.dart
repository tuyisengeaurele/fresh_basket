import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A friendly error widget for failed Firestore queries / stream providers.
/// Replace `error: (e, _) => Center(child: Text(e.toString()))` with this.
class QueryErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? message;

  const QueryErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isPermission = error.toString().contains('permission-denied');
    final isNetwork = error.toString().contains('network') ||
        error.toString().contains('unavailable');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission
                  ? Icons.lock_outline_rounded
                  : isNetwork
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              message ??
                  (isPermission
                      ? 'Access denied'
                      : isNetwork
                          ? 'No connection'
                          : 'Something went wrong'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPermission
                  ? 'You don\'t have permission to view this data.'
                  : isNetwork
                      ? 'Check your internet connection and try again.'
                      : 'An unexpected error occurred. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
