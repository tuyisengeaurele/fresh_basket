import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _addressesProvider =
    StreamProvider.family<List<DeliveryAddress>, String>((ref, uid) {
  return FirebaseService.users
      .doc(uid)
      .collection('addresses')
      .orderBy('isDefault', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DeliveryAddress.fromMap({...d.data(), 'id': d.id})).toList());
});

class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final addressesAsync = ref.watch(_addressesProvider(user.uid));

        return Scaffold(
          appBar: AppBar(title: const Text('Saved Addresses')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddressSheet(context, user.uid),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Add Address',
            child: const Icon(Icons.add_location_rounded, size: 26),
          ),
          body: addressesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => QueryErrorView(error: e),
            data: (addresses) {
              if (addresses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off_outlined, size: 72, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('No addresses saved',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('Add an address for faster checkout.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: addresses.length,
                itemBuilder: (_, i) => _AddressTile(
                  address: addresses[i],
                  uid: user.uid,
                  onEdit: () => _showAddressSheet(context, user.uid, address: addresses[i]),
                  onDelete: () => _delete(user.uid, addresses[i].id),
                  onSetDefault: () => _setDefault(user.uid, addresses[i].id, addresses),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddressSheet(BuildContext context, String uid,
      {DeliveryAddress? address}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSheet(uid: uid, existing: address),
    );
  }

  Future<void> _delete(String uid, String addressId) async {
    await FirebaseService.users.doc(uid).collection('addresses').doc(addressId).delete();
  }

  Future<void> _setDefault(
      String uid, String addressId, List<DeliveryAddress> all) async {
    final batch = FirebaseService.firestore.batch();
    for (final a in all) {
      batch.update(
        FirebaseService.users.doc(uid).collection('addresses').doc(a.id),
        {'isDefault': a.id == addressId},
      );
    }
    await batch.commit();
  }
}

class _AddressTile extends StatelessWidget {
  final DeliveryAddress address;
  final String uid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressTile({
    required this.address,
    required this.uid,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: address.isDefault
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    address.label.toLowerCase().contains('home')
                        ? Icons.home_outlined
                        : address.label.toLowerCase().contains('work')
                            ? Icons.work_outline_rounded
                            : Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(address.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Default',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(address.fullAddress,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          maxLines: 2),
                      if (address.instructions != null) ...[
                        const SizedBox(height: 2),
                        Text(address.instructions!,
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.green50.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                if (!address.isDefault)
                  TextButton(
                    onPressed: onSetDefault,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Set as default',
                        style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSheet extends ConsumerStatefulWidget {
  final String uid;
  final DeliveryAddress? existing;
  const _AddressSheet({required this.uid, this.existing});

  @override
  ConsumerState<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends ConsumerState<_AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _fullAddressCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  double _lat = 0;
  double _lng = 0;
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _labelCtrl.text = widget.existing!.label;
      _fullAddressCtrl.text = widget.existing!.fullAddress;
      _instructionsCtrl.text = widget.existing!.instructions ?? '';
      _lat = widget.existing!.latitude;
      _lng = widget.existing!.longitude;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _fullAddressCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'Add Address' : 'Edit Address',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: 'Label (e.g. Home, Work)'),
              validator: Validators.required,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fullAddressCtrl,
                    decoration: const InputDecoration(labelText: 'Full Address'),
                    validator: Validators.required,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _locating ? null : _detectLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _instructionsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Delivery Instructions (optional)',
                  hintText: 'E.g. Leave at gate, call on arrival'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.existing == null ? 'Add Address' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _fullAddressCtrl.text =
            '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}'.trim();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final col = FirebaseService.users.doc(widget.uid).collection('addresses');
      final data = {
        'label': _labelCtrl.text.trim(),
        'fullAddress': _fullAddressCtrl.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'instructions': _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        'isDefault': widget.existing?.isDefault ?? false,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.existing != null) {
        await col.doc(widget.existing!.id).update(data);
      } else {
        await col.doc(const Uuid().v4()).set({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
