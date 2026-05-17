import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../shared/models/product_model.dart';
import '../providers/product_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  int _qty = 1;
  late TabController _tabController;
  int _selectedImage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync =
        ref.watch(productDetailProvider(widget.productId));
    final cartQty = ref.watch(cartProvider).quantityOf(widget.productId);

    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (product) {
        if (product == null) {
          return const Scaffold(
            body: Center(child: Text('Product not found')),
          );
        }
        return _buildContent(context, product, cartQty);
      },
    );
  }

  Widget _buildContent(
      BuildContext context, ProductModel product, int cartQty) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image App Bar
          SliverAppBar(
            expandedHeight: size.height * 0.42,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrls[_selectedImage],
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.green50,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                size: 80, color: AppColors.textHint),
                          ),
                        ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black26, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Image thumbnails
                  if (product.imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: product.imageUrls.asMap().entries.map((e) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImage = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: e.key == _selectedImage ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: e.key == _selectedImage
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            leading: _CircleBackButton(),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _CircleActionButton(
                  icon: Icons.share_outlined,
                  onTap: () {},
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusXl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & category
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            _FreshnessIndicator(
                                score: product.freshnessScore),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.green50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.category.name.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.star),
                            const SizedBox(width: 3),
                            Text(
                              '${Formatters.rating(product.rating)} (${product.reviewCount} reviews)',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price & quantity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.currency(product.price),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'per ${product.unit}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            _QuantitySelector(
                              quantity: _qty,
                              onDecrement: () {
                                if (_qty > 1) setState(() => _qty--);
                              },
                              onIncrement: () {
                                if (_qty < product.stock) {
                                  setState(() => _qty++);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Stock info
                        Row(
                          children: [
                            Icon(
                              product.stock > 0
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 16,
                              color: product.stock > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.stock > 0
                                  ? '${product.stock} units available'
                                  : 'Out of stock',
                              style: TextStyle(
                                color: product.stock > 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Seller info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.sellerBusinessName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (product.sellerName != product.sellerBusinessName)
                                      Text(
                                        'by ${product.sellerName}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tabs
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textHint,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: const [
                            Tab(text: 'Details'),
                            Tab(text: 'Reviews'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Details
                              SingleChildScrollView(
                                child: Text(
                                  product.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.6,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // Reviews
                              _ReviewsPreview(productId: product.id),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.paddingOf(context).bottom + 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                ),
                Text(
                  Formatters.currency(product.price * _qty),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: product.stock > 0
                      ? () {
                          ref
                              .read(cartProvider.notifier)
                              .addItem(product, quantity: _qty);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${product.name} added to cart!'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    cartQty > 0
                        ? 'Update Cart (${cartQty + _qty})'
                        : 'Add to Cart',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _FreshnessIndicator extends StatelessWidget {
  final int score;

  const _FreshnessIndicator({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: _color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Btn(icon: Icons.remove_rounded, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _Btn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}

class _ReviewsPreview extends ConsumerWidget {
  final String productId;

  const _ReviewsPreview({required this.productId});

  Future<void> _openWriteReview(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to write a review')),
      );
      return;
    }

    // Prevent duplicate reviews — one per user per product
    final alreadyReviewed = await ref
        .read(productRepositoryProvider)
        .hasUserReviewed(productId, user.uid);
    if (alreadyReviewed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already reviewed this product.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WriteReviewSheet(
        productId: productId,
        userId: user.uid,
        userName: user.fullName,
        userPhotoUrl: user.photoUrl,
      ),
    );
    // Refresh reviews after submission
    ref.invalidate(productReviewsProvider(productId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Write a review button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openWriteReview(context, ref),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('Write a Review'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reviews list
        Expanded(
          child: reviewsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading reviews'),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const Center(
                  child: Text(
                    'No reviews yet.\nBe the first to review!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint),
                  ),
                );
              }
              return ListView.separated(
                itemCount: reviews.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = reviews[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.green50,
                          backgroundImage: r.userPhotoUrl != null
                              ? CachedNetworkImageProvider(r.userPhotoUrl!)
                              : null,
                          child: r.userPhotoUrl == null
                              ? Text(
                                  r.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.userName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (s) => Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: s < r.rating
                                            ? AppColors.star
                                            : AppColors.dividerLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.comment,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Write Review Sheet ──────────────────────────────────────────────────────

class _WriteReviewSheet extends ConsumerStatefulWidget {
  final String productId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const _WriteReviewSheet({
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  int _stars = 5;
  late final TextEditingController _commentCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      // Use the repository (batch write: review doc + product rating update)
      // This is the correct pattern — avoids direct Firestore calls in the UI.
      final review = ReviewModel(
        id: '',
        productId: widget.productId,
        userId: widget.userId,
        userName: widget.userName,
        userPhotoUrl: widget.userPhotoUrl,
        rating: _stars.toDouble(),
        comment: comment,
        createdAt: DateTime.now(),
      );
      await ref.read(productRepositoryProvider).submitReview(review);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Write a Review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          // Star picker
          const Text(
            'Rating',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.star_rounded,
                    size: 36,
                    color: i < _stars ? AppColors.star : AppColors.dividerLight,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Comment
          const Text(
            'Your comment',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your experience with this product...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
// _WriteReviewSheet: posts to reviews collection, updates product rating via transaction
