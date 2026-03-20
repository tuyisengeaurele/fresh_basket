import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _promoCtrl = TextEditingController();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.cart,
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                        'Are you sure you want to remove all items?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.pagePadding),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) => _CartItemTile(
                      item: cart.items[i],
                      index: i,
                    ),
                  ),
                ),
                _OrderSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final item;
  final int index;

  const _CartItemTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      key: ValueKey(item.product.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref
                .read(cartProvider.notifier)
                .removeItem(item.product.id),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Remove',
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: item.product.firstImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.product.firstImageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: AppColors.green50,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.textHint),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.product.sellerBusinessName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.currency(item.product.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Qty control
            Column(
              children: [
                _QtyBtn(
                  icon: Icons.add_rounded,
                  onTap: () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.product.id, item.quantity + 1),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                _QtyBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.product.id, item.quantity - 1),
                ),
              ],
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 50))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.1, end: 0),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  final cart;

  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.paddingOf(context).bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal',
            value: Formatters.currency(cart.subtotal),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Delivery Fee',
            value: cart.deliveryFee == 0
                ? 'FREE'
                : Formatters.currency(cart.deliveryFee),
            valueColor: cart.deliveryFee == 0 ? AppColors.success : null,
          ),
          if (cart.discount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Discount',
              value: '- ${Formatters.currency(cart.discount)}',
              valueColor: AppColors.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _SummaryRow(
            label: 'Total',
            value: Formatters.currency(cart.total),
            bold: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _handleCheckout(context, ref),
              child: Text(
                '${AppStrings.checkout} (${cart.totalItems} items)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _handleCheckout(BuildContext context, WidgetRef ref) {
  final user = ref.read(authNotifierProvider).value;
  final isGuest = user == null || user.email.isEmpty;
  if (isGuest) {
    _showGuestSheet(context);
    return;
  }
  context.push(RouteNames.checkout);
}

void _showGuestSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.paddingOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.green50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sign in to Checkout',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create an account or sign in to place your order.\nYour cart items will be saved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(RouteNames.login);
              },
              child: const Text('Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(RouteNames.register);
              },
              child: const Text('Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (bold ? AppColors.primary : AppColors.textPrimary),
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.green50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text(
            AppStrings.emptyCart,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          const Text(
            AppStrings.emptyCartDesc,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go(RouteNames.shop),
              child: const Text('Browse Products'),
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
// _showGuestSheet: intercepts checkout for unauthenticated/anonymous users
