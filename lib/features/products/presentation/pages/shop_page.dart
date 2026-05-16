import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../providers/product_provider.dart';

class ShopPage extends ConsumerStatefulWidget {
  final ProductCategory? initialCategory;

  const ShopPage({super.key, this.initialCategory});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  ProductCategory? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = _category != null
        ? (_category == ProductCategory.fruits
            ? ref.watch(fruitsProvider)
            : ref.watch(vegetablesProvider))
        : ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding, 10, AppDimensions.pagePadding, 0),
            child: TextField(
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search products...',
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category filter chips — full-width row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'All',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterChip(
                    label: 'Fruits',
                    selected: _category == ProductCategory.fruits,
                    onTap: () =>
                        setState(() => _category = ProductCategory.fruits),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterChip(
                    label: 'Vegetables',
                    selected: _category == ProductCategory.vegetables,
                    onTap: () =>
                        setState(() => _category = ProductCategory.vegetables),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: productsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePadding),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ListItemSkeleton(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Text('No products found'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimensions.pagePadding,
                      4,
                      AppDimensions.pagePadding,
                      16),
                  itemCount: products.length,
                  itemBuilder: (_, i) =>
                      _ProductListTile(product: products[i], index: i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.green50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Product list tile ──────────────────────────────────────────────────────

class _ProductListTile extends ConsumerWidget {
  final ProductModel product;
  final int index;

  const _ProductListTile({required this.product, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider).quantityOf(product.id);

    return GestureDetector(
      onTap: () => context.push(
        RouteNames.productDetail.replaceFirst(':id', product.id),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: product.firstImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.firstImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.currency(product.price)} / ${product.unit}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.star),
                        const SizedBox(width: 3),
                        Text(
                          '${Formatters.rating(product.rating)} (${product.reviewCount})',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Add / qty control
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: qty > 0
                  ? _QtyRow(product: product, qty: qty)
                  : _AddBtn(product: product),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 50))
          .fadeIn(duration: 350.ms)
          .slideX(begin: 0.05),
    );
  }

  Widget _placeholder() => Container(
        width: 80,
        height: 80,
        color: AppColors.green50,
        child: const Icon(Icons.eco_rounded,
            color: AppColors.primary, size: 32),
      );
}

class _AddBtn extends ConsumerWidget {
  final ProductModel product;
  const _AddBtn({required this.product});

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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: product.stock > 0 ? AppColors.primary : AppColors.dividerLight,
          borderRadius: BorderRadius.circular(10),
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

class _QtyRow extends ConsumerWidget {
  final ProductModel product;
  final int qty;
  const _QtyRow({required this.product, required this.qty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmBtn(
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
        _SmBtn(
          icon: Icons.add_rounded,
          onTap: () => ref
              .read(cartProvider.notifier)
              .updateQuantity(product.id, qty + 1),
        ),
      ],
    );
  }
}

class _SmBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmBtn({required this.icon, required this.onTap});

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
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
// Row with 3 Expanded _FilterChip children replaces horizontal scrollable chips
