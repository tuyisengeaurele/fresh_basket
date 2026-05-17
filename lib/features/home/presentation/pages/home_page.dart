import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/products/presentation/providers/product_provider.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/product_card.dart';
import 'package:badges/badges.dart' as badges;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final cartCount = ref.watch(cartItemCountProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final fruitsAsync = ref.watch(fruitsProvider);
    final vegsAsync = ref.watch(vegetablesProvider);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: AppDimensions.pagePadding,
            title: Text(
              'FreshBasket',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              // Notifications
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(RouteNames.notifications),
              ),
              // Cart (shopping cart icon, high-contrast badge)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: badges.Badge(
                  showBadge: cartCount > 0,
                  badgeContent: Text(
                    cartCount > 9 ? '9+' : '$cartCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppColors.accent,
                    padding: EdgeInsets.all(5),
                    elevation: 2,
                  ),
                  position: badges.BadgePosition.topEnd(top: 2, end: 2),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.push(RouteNames.cart),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting (below AppBar) ─────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding,
                    14,
                    AppDimensions.pagePadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null
                            ? '$_greeting, ${user.fullName.split(' ').first} \u{1F44B}'
                            : '$_greeting \u{1F44B}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                      const SizedBox(height: 3),
                      Text(
                        'Discover fresh produce near you',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 80.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Search Bar ──────────────────────────────────────
                _SearchBar(),
                const SizedBox(height: 20),

                // ── Categories ──────────────────────────────────────
                _CategorySection(),
                const SizedBox(height: 20),

                // ── Promo Banner ────────────────────────────────────
                _PromoBanner().animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 20),

                // ── New Arrivals ────────────────────────────────────
                _SectionHeader(
                  title: 'New Arrivals',
                  onSeeAll: () => context.push(RouteNames.shop),
                ),
                const SizedBox(height: AppDimensions.sm),
              ],
            ),
          ),

          // Featured horizontal scroll
          SliverToBoxAdapter(
            child: featuredAsync.when(
              loading: () => SizedBox(
                height: AppDimensions.productCardHeight + 16,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePadding),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => const SizedBox(
                    width: AppDimensions.productCardWidth,
                    child: ProductCardSkeleton(),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (products) => SizedBox(
                height: AppDimensions.productCardHeight + 16,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePadding),
                  itemCount: products.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: AppDimensions.productCardWidth,
                      child: ProductCard(product: products[i], index: i),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Fruits section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.lg),
                _SectionHeader(
                  title: 'Fresh Fruits',
                  onSeeAll: () => context.push(
                    RouteNames.category.replaceFirst(':id', 'fruits'),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
              ],
            ),
          ),
          _ProductGrid(asyncProducts: fruitsAsync),

          // Vegetables section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.lg),
                _SectionHeader(
                  title: 'Fresh Vegetables',
                  onSeeAll: () => context.push(
                    RouteNames.category.replaceFirst(':id', 'vegetables'),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
              ],
            ),
          ),
          _ProductGrid(asyncProducts: vegsAsync),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(RouteNames.search),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePadding),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : AppColors.dividerLight,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.searchProducts,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ── Categories ─────────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding),
          child: Builder(
            builder: (ctx) => Text(
              'Categories',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding),
            children: const [
              _CategoryItem(
                label: 'All',
                icon: Icons.apps_rounded,
                color: AppColors.primary,
                category: null,
              ),
              SizedBox(width: 10),
              _CategoryItem(
                label: 'Fruits',
                icon: Icons.eco_rounded,
                color: Color(0xFFE91E63),
                category: ProductCategory.fruits,
              ),
              SizedBox(width: 10),
              _CategoryItem(
                label: 'Vegetables',
                icon: Icons.grass_rounded,
                color: AppColors.primary,
                category: ProductCategory.vegetables,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends ConsumerWidget {
  final String label;
  final IconData icon;
  final Color color;
  final ProductCategory? category;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider) == category;
    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = category;
        if (category != null) {
          context.push(
              RouteNames.category.replaceFirst(':id', category!.name));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.18),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? Colors.white : color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Promo Banner ───────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding),
      height: 130,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Free Delivery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Orders above\nRWF 5,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact),
            child: const Text('See All',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Product grid ───────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final AsyncValue<List<ProductModel>> asyncProducts;

  const _ProductGrid({required this.asyncProducts});

  @override
  Widget build(BuildContext context) {
    return asyncProducts.when(
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePadding),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const ProductCardSkeleton(),
            childCount: 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
        ),
      ),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (products) => SliverPadding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePadding),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ProductCard(product: products[i], index: i),
            childCount: products.take(6).length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
        ),
      ),
    );
  }
}
// colorScheme.onSurface auto-adapts: dark text in light mode, white in dark mode
