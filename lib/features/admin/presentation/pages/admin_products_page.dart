import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';

/// Admin-only stream — returns ALL products regardless of availability.
final _adminAllProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseService.products
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map((d) => ProductModel.fromFirestore(d)).toList());
});

class AdminProductsPage extends ConsumerStatefulWidget {
  const AdminProductsPage({super.key});

  @override
  ConsumerState<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends ConsumerState<AdminProductsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _search = '';

  static const _tabs = ['All', 'Available', 'Unavailable'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(_adminAllProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.sellerAddProduct),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Product',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: productsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          itemBuilder: (_, __) => const ListItemSkeleton(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        data: (products) {
          final searched = _search.isEmpty
              ? products
              : products
                  .where((p) =>
                      p.name.toLowerCase().contains(_search.toLowerCase()) ||
                      p.sellerBusinessName
                          .toLowerCase()
                          .contains(_search.toLowerCase()))
                  .toList();

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final filtered = _filterProducts(searched, tab);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No products found',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _AdminProductTile(
                  product: filtered[i],
                  onDelete: () => _confirmDelete(context, filtered[i]),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products, String tab) {
    switch (tab) {
      case 'Available':
        return products.where((p) => p.isAvailable).toList();
      case 'Unavailable':
        return products.where((p) => !p.isAvailable).toList();
      default:
        return products;
    }
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content:
            Text('Delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await FirebaseService.products.doc(product.id).delete();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('"${product.name}" deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AdminProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onDelete;

  const _AdminProductTile({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: product.imageUrls.first,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.sellerBusinessName,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            Text(
              '${Formatters.currency(product.price)} / ${product.unit}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvailabilityToggle(product: product),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              onPressed: () =>
                  context.push('/seller/products/edit/${product.id}'),
              tooltip: 'Edit',
              constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Delete',
              constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: AppColors.green50,
        child:
            const Icon(Icons.image_outlined, color: AppColors.primary, size: 24),
      );
}

class _AvailabilityToggle extends StatelessWidget {
  final ProductModel product;
  const _AvailabilityToggle({required this.product});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: CupertinoSwitch(
        value: product.isAvailable,
        activeColor: AppColors.primary,
        onChanged: (v) async {
          await FirebaseService.products.doc(product.id).update({
            'isAvailable': v,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }
}
