import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routes/route_names.dart';
import '../../core/utils/formatters.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../models/product_model.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final int index;

  const ProductCard({super.key, required this.product, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final qty = cart.quantityOf(product.id);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(
        RouteNames.productDetail.replaceFirst(':id', product.id),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusLg),
                  ),
                  child: product.firstImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.firstImageUrl,
                          height: AppDimensions.productImageHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _shimmerBox(),
                          errorWidget: (_, __, ___) => _placeholderBox(),
                        )
                      : _placeholderBox(),
                ),
                // Promo / seasonal badge
                if (product.promoTag != null || product.isSeasonal)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.promoTag != null
                            ? AppColors.accent
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull),
                      ),
                      child: Text(
                        product.promoTag ?? 'Seasonal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Freshness badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          size: 12,
                          color: _freshnessColor(product.freshnessScore),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${product.freshnessScore}%',
                          style: TextStyle(
                            color: _freshnessColor(product.freshnessScore),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        Formatters.rating(product.rating),
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 3),
                      Text('(${product.reviewCount})', style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${Formatters.currency(product.price)}/${product.unit}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      qty > 0
                          ? _QtyControl(product: product)
                          : _AddButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 60))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.15, end: 0),
    );
  }

  Color _freshnessColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Widget _shimmerBox() => Shimmer.fromColors(
        baseColor: AppColors.green50,
        highlightColor: Colors.white,
        child: Container(
          height: AppDimensions.productImageHeight,
          color: AppColors.green50,
        ),
      );

  Widget _placeholderBox() => Container(
        height: AppDimensions.productImageHeight,
        color: AppColors.green50,
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: AppColors.textHint,
            size: 40,
          ),
        ),
      );
}

class _AddButton extends ConsumerWidget {
  final ProductModel product;

  const _AddButton({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (product.stock > 0) {
          ref.read(cartProvider.notifier).addItem(product);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: product.stock > 0
              ? AppColors.primary
              : AppColors.dividerLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 20,
          color: product.stock > 0 ? Colors.white : AppColors.textHint,
        ),
      ),
    );
  }
}

class _QtyControl extends ConsumerWidget {
  final ProductModel product;

  const _QtyControl({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider).quantityOf(product.id);
    return Row(
      children: [
        _CircleBtn(
          icon: Icons.remove_rounded,
          onTap: () => ref
              .read(cartProvider.notifier)
              .updateQuantity(product.id, qty - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$qty',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        _CircleBtn(
          icon: Icons.add_rounded,
          onTap: () => ref
              .read(cartProvider.notifier)
              .updateQuantity(product.id, qty + 1),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
