import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  XFile? _newPhoto;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _init(user) {
    if (!_loaded && user != null) {
      _nameCtrl.text = user.fullName;
      _phoneCtrl.text = user.phone ?? '';
      _loaded = true;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (photo != null) setState(() => _newPhoto = photo);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        _init(user);
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.green100,
                        backgroundImage: _newPhoto != null
                            ? FileImage(File(_newPhoto!.path))
                            : (user?.photoUrl != null
                                ? NetworkImage(user!.photoUrl!)
                                    as ImageProvider
                                : null),
                        child: (_newPhoto == null && user?.photoUrl == null)
                            ? Text(
                                (user?.fullName.isNotEmpty == true)
                                    ? user!.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 36,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _saving ? null : _pickPhoto,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_newPhoto != null) ...[
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Photo selected — will upload on save',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+250 7XX XXX XXX',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user?.email ?? '',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                      const Text(
                        'Cannot change',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(user?.uid),
                    child: _saving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 10),
                              Text('Saving…',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save(String? uid) async {
    if (!_formKey.currentState!.validate() || uid == null) return;
    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_newPhoto != null) {
        photoUrl = await CloudinaryService.uploadImage(
          File(_newPhoto!.path),
          folder: 'user_photos/$uid',
        );
      }

      await ref.read(authNotifierProvider.notifier).updateProfile(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            photoUrl: photoUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
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
