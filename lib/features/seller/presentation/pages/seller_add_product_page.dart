import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/product_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';

class SellerAddProductPage extends ConsumerStatefulWidget {
  final String? productId;
  const SellerAddProductPage({super.key, this.productId});

  @override
  ConsumerState<SellerAddProductPage> createState() =>
      _SellerAddProductPageState();
}

class _SellerAddProductPageState extends ConsumerState<SellerAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _promoTagCtrl = TextEditingController();

  ProductCategory _category = ProductCategory.fruits;
  String _unit = 'kg';
  bool _isFeatured = false;
  bool _isSeasonal = false;
  bool _isAvailable = true;
  int _freshnessScore = 95;

  /// Already-uploaded image URLs (existing product being edited)
  List<String> _existingImageUrls = [];

  /// New images picked from gallery — not yet uploaded
  final List<XFile> _newImages = [];

  bool _saving = false;

  static const _units = ['kg', 'g', 'piece', 'bunch', 'crate', 'box'];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final product =
        await ref.read(productRepositoryProvider).getById(widget.productId!);
    if (product != null && mounted) {
      setState(() {
        _nameCtrl.text = product.name;
        _descCtrl.text = product.description;
        _priceCtrl.text = product.price.toStringAsFixed(0);
        _stockCtrl.text = product.stock.toString();
        _category = product.category;
        _unit = product.unit;
        _isFeatured = product.isFeatured;
        _isSeasonal = product.isSeasonal;
        _isAvailable = product.isAvailable;
        _freshnessScore = product.freshnessScore;
        _existingImageUrls = List.from(product.imageUrls);
        if (product.originalPrice != null) {
          _originalPriceCtrl.text = product.originalPrice!.toStringAsFixed(0);
        }
        _promoTagCtrl.text = product.promoTag ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _originalPriceCtrl.dispose();
    _promoTagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    // Compress to 72% quality and cap dimensions at 1200×1200 px
    // This reduces typical phone photos from 5–8 MB down to ~200–400 KB
    final picked = await picker.pickMultiImage(
      imageQuality: 72,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked.isNotEmpty) setState(() => _newImages.addAll(picked));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;
    final totalImages = _existingImageUrls.length + _newImages.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Images ──────────────────────────────────────────────
            const Text(
              'Product Images',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing (already uploaded) thumbnails
                  ...List.generate(_existingImageUrls.length, (i) {
                    return _ImageThumb(
                      child: Image.network(
                        _existingImageUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                        ),
                      ),
                      onRemove: () => setState(
                          () => _existingImageUrls.removeAt(i)),
                    );
                  }),
                  // New picks (local files)
                  ...List.generate(_newImages.length, (i) {
                    return _ImageThumb(
                      child: Image.file(
                        File(_newImages[i].path),
                        fit: BoxFit.cover,
                      ),
                      onRemove: () =>
                          setState(() => _newImages.removeAt(i)),
                    );
                  }),
                  // Add button
                  GestureDetector(
                    onTap: _saving ? null : _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.green50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.primary, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            totalImages == 0 ? 'Add' : 'More',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Basic Info ───────────────────────────────────────────
            _SectionTitle(title: 'Basic Info'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: Validators.required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: Validators.required,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ProductCategory>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ProductCategory.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name[0].toUpperCase() +
                                  c.name.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Pricing & Stock ──────────────────────────────────────
            _SectionTitle(title: 'Pricing & Stock'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Price (RWF)',
                      prefixText: 'RWF ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.price,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Original Price (optional)',
                      prefixText: 'RWF ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Stock Quantity'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.stock,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _promoTagCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Promo Tag (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Freshness Score ──────────────────────────────────────
            _SectionTitle(title: 'Freshness Score'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _freshnessScore.toDouble(),
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '$_freshnessScore%',
                    activeColor: _freshnessColor(_freshnessScore),
                    onChanged: (v) =>
                        setState(() => _freshnessScore = v.round()),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _freshnessColor(_freshnessScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_freshnessScore%',
                    style: TextStyle(
                      color: _freshnessColor(_freshnessScore),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Options ──────────────────────────────────────────────
            _SectionTitle(title: 'Options'),
            const SizedBox(height: 8),
            _SwitchRow(
              label: 'Available for sale',
              subtitle: 'Customers can order this product',
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            _SwitchRow(
              label: 'Feature on homepage',
              subtitle: 'Show in featured section',
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            _SwitchRow(
              label: 'Seasonal product',
              subtitle: 'Mark as seasonal',
              value: _isSeasonal,
              onChanged: (v) => setState(() => _isSeasonal = v),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text('Uploading images…',
                              style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(isEditing ? 'Save Changes' : 'Add Product'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _freshnessColor(int score) {
    if (score >= 90) return AppColors.primary;
    if (score >= 75) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one product image.')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final user = ref.read(authNotifierProvider).value;
      if (user == null) return;

      // Upload new images to Cloudinary
      final uploadedUrls = <String>[];
      for (final img in _newImages) {
        final url = await CloudinaryService.uploadImage(
          File(img.path),
          folder: 'product_images/${user.uid}',
        );
        uploadedUrls.add(url);
      }

      final allImages = [..._existingImageUrls, ...uploadedUrls];
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      final originalPrice = _originalPriceCtrl.text.isEmpty
          ? null
          : double.tryParse(_originalPriceCtrl.text);
      final stock = int.tryParse(_stockCtrl.text) ?? 0;

      // Resolve the seller's registered business name from their SellerProfile.
      // Falls back to the user's display name if no profile exists yet.
      String businessName = user.fullName;
      try {
        final profileDoc =
            await FirebaseService.sellerProfiles.doc(user.uid).get();
        if (profileDoc.exists) {
          businessName =
              (profileDoc.data()?['businessName'] as String?)?.trim().isNotEmpty == true
                  ? profileDoc.data()!['businessName'] as String
                  : user.fullName;
        }
      } catch (_) {}

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category.name,
        'price': price,
        'originalPrice': originalPrice,
        'unit': _unit,
        'stock': stock,
        'freshnessScore': _freshnessScore,
        'imageUrls': allImages,
        'isAvailable': _isAvailable,
        'isFeatured': _isFeatured,
        'isSeasonal': _isSeasonal,
        'promoTag': _promoTagCtrl.text.trim().isEmpty
            ? null
            : _promoTagCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.productId != null) {
        await FirebaseService.products.doc(widget.productId).update(data);
      } else {
        await FirebaseService.products.add({
          ...data,
          'sellerId': user.uid,
          'sellerName': user.fullName,
          'sellerBusinessName': businessName, // registered business name
          'rating': 0.0,
          'reviewCount': 0,
          'deliveryZones': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.productId != null ? 'Product updated!' : 'Product added!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Shared sub-widgets ──────────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImageThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
