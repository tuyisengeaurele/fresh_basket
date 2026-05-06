import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminCreateDriverPage extends ConsumerStatefulWidget {
  const AdminCreateDriverPage({super.key});

  @override
  ConsumerState<AdminCreateDriverPage> createState() => _AdminCreateDriverPageState();
}

class _AdminCreateDriverPageState extends ConsumerState<AdminCreateDriverPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String _vehicleType = 'motorcycle';
  bool _saving = false;

  static const _vehicleTypes = ['motorcycle', 'bicycle', 'car', 'van'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Driver Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A temporary password will be emailed to the driver. They must change it on first login.',
                      style: TextStyle(fontSize: 13, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section(title: 'Personal Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: Validators.fullName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                  labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+250 7XX XXX XXX'),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 24),
            _Section(title: 'Vehicle Information'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _vehicleType,
              decoration: const InputDecoration(
                  labelText: 'Vehicle Type', prefixIcon: Icon(Icons.two_wheeler_rounded)),
              items: _vehicleTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _vehicleType = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _plateCtrl,
              decoration: const InputDecoration(
                  labelText: 'License Plate (optional)', prefixIcon: Icon(Icons.pin_outlined)),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _createDriver,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Driver Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDriver() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    FirebaseApp? secondaryApp;
    try {
      final adminUser = ref.read(authNotifierProvider).value;

      // Generate a temp password
      final tempPassword =
          'Driver${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}!';

      // ─────────────────────────────────────────────────────────────────────
      // IMPORTANT: We create the user using a *secondary* Firebase App so the
      // admin's current auth session is never touched.  Without this, calling
      // createUserWithEmailAndPassword on the primary app signs the admin out
      // and signs in as the new driver — causing permission-denied everywhere.
      // ─────────────────────────────────────────────────────────────────────
      secondaryApp = await Firebase.initializeApp(
        name: 'driverCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: tempPassword,
      );
      final uid = credential.user!.uid;
      // Sign out from the secondary instance immediately
      await secondaryAuth.signOut();

      // Write Firestore docs as the admin (primary session intact)
      await FirebaseService.users.doc(uid).set({
        'email': _emailCtrl.text.trim(),
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': UserRole.driver.name,
        'emailVerified': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseService.driverProfiles.doc(uid).set({
        'uid': uid,
        'vehicleType': _vehicleType,
        'vehiclePlate': _plateCtrl.text.trim().isEmpty ? null : _plateCtrl.text.trim(),
        'isAvailable': false,
        'createdBySellerId': adminUser?.uid ?? 'admin',
        'rating': 0.0,
        'totalDeliveries': 0,
        'totalEarnings': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send welcome email with credentials
      try {
        await EmailService.sendDriverAccountCreated(
          to: _emailCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          tempPassword: tempPassword,
        );
      } catch (_) {}

      // Log audit
      await FirebaseService.logAudit(
        action: 'driver_created',
        actorId: adminUser?.uid ?? '',
        actorName: adminUser?.fullName ?? 'Admin',
        targetId: uid,
        targetType: 'driver',
        details: {
          'email': _emailCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver account created. Credentials sent by email.'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authErrorMessage(e.code)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      // Always clean up the secondary app
      await secondaryApp?.delete();
      if (mounted) setState(() => _saving = false);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Use a different email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Try again.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Contact support.';
      default:
        return 'Account creation failed ($code). Please try again.';
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
