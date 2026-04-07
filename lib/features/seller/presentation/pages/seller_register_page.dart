import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';

class SellerRegisterPage extends ConsumerStatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  ConsumerState<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends ConsumerState<SellerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _storeAddressCtrl = TextEditingController();
  final _tinCtrl = TextEditingController();
  File? _idDoc;
  bool _loading = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _storeAddressCtrl.dispose();
    _tinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _idDoc = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your National ID or business document'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(authNotifierProvider).value;
      if (user == null) throw Exception('Not logged in. Please sign in again.');

      // Upload ID doc to Cloudinary
      final docUrl = await CloudinaryService.uploadImage(
        _idDoc!,
        folder: 'seller_docs/${user.uid}',
      );

      final profile = SellerProfile(
        uid: user.uid,
        businessName: _businessNameCtrl.text.trim(),
        tinNumber: _tinCtrl.text.trim().isEmpty ? null : _tinCtrl.text.trim(),
        storeAddress: _storeAddressCtrl.text.trim(),
        nationalIdDocUrl: docUrl,
        createdAt: DateTime.now(),
      );

      await FirebaseService.sellerProfiles.doc(user.uid).set(profile.toMap());

      if (!mounted) return;
      context.go(RouteNames.sellerPendingVerification);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Become a Seller',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Complete your store profile to get started',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),

              // Business Name
              TextFormField(
                controller: _businessNameCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.businessName,
                  hintText: 'Your store / business name',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (v) => Validators.required(v, 'Business Name'),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 16),

              // Store Address
              TextFormField(
                controller: _storeAddressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: AppStrings.storeAddress,
                  hintText: 'Physical store address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => Validators.required(v, 'Store Address'),
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 16),

              // TIN (optional)
              TextFormField(
                controller: _tinCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.tinNumber,
                  hintText: 'Tax Identification Number (optional)',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 24),

              // Upload ID doc
              Text(
                AppStrings.nationalId,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Required for seller verification (National ID or business permit)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _loading ? null : _pickDocument,
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: _idDoc != null
                          ? AppColors.primary
                          : AppColors.dividerLight,
                      width: _idDoc != null ? 2 : 1,
                    ),
                  ),
                  child: _idDoc != null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_idDoc!, fit: BoxFit.cover),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => setState(() => _idDoc = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                size: 40, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload document',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'JPG, PNG supported',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading…',
                                style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : const Text(
                          'Submit for Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              const Text(
                'Your account will be reviewed within 24 hours. You will receive an email once approved.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
