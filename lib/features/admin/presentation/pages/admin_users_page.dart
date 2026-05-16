import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _allUsersProvider =
    StreamProvider.family<List<UserModel>, UserRole?>((ref, role) {
  Query<Map<String, dynamic>> q = FirebaseService.users;
  if (role != null) q = q.where('role', isEqualTo: role.name);
  return q
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
});

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _search = '';

  static const _roles = [null, UserRole.customer, UserRole.seller, UserRole.driver];
  static const _tabLabels = ['All', 'Customers', 'Sellers', 'Drivers'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
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
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateUserSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create User',
        child: const Icon(Icons.person_add_rounded, size: 26),
      ),
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
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
                tabs: _tabLabels.map((t) => Tab(text: t)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _roles.map((role) {
          final usersAsync = ref.watch(_allUsersProvider(role));
          return usersAsync.when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8,
              itemBuilder: (_, __) => const ListItemSkeleton(),
            ),
            error: (e, _) => QueryErrorView(error: e),
            data: (users) {
              final filtered = _search.isEmpty
                  ? users
                  : users
                      .where((u) =>
                          u.fullName
                              .toLowerCase()
                              .contains(_search.toLowerCase()) ||
                          u.email
                              .toLowerCase()
                              .contains(_search.toLowerCase()))
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No users found',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _UserTile(
                  user: filtered[i],
                  onTap: () => _openEditSheet(context, filtered[i]),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _openEditSheet(BuildContext context, UserModel user) {
    final currentAdmin = ref.read(authNotifierProvider).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserEditSheet(
        user: user,
        currentAdminId: currentAdmin?.uid ?? '',
        currentAdminName: currentAdmin?.fullName ?? 'Admin',
      ),
    );
  }

  void _openCreateUserSheet(BuildContext context) {
    final currentAdmin = ref.read(authNotifierProvider).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateUserSheet(
        adminId: currentAdmin?.uid ?? '',
        adminName: currentAdmin?.fullName ?? 'Admin',
      ),
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final roleColor = {
      UserRole.customer: AppColors.primary,
      UserRole.seller: AppColors.accent,
      UserRole.driver: AppColors.info,
      UserRole.admin: Colors.purple,
    }[user.role]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: roleColor.withOpacity(0.15),
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: roleColor, fontWeight: FontWeight.bold))
                : null,
          ),
          title: Text(user.fullName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email,
                  style: const TextStyle(fontSize: 12)),
              Text(
                'Joined ${Formatters.relativeTime(user.createdAt)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(user.role.name,
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.isActive ? 'Active' : 'Banned',
                  style: TextStyle(
                    color: user.isActive
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Bottom Sheet ─────────────────────────────────────────────────────────

class _UserEditSheet extends StatefulWidget {
  final UserModel user;
  final String currentAdminId;
  final String currentAdminName;

  const _UserEditSheet({
    required this.user,
    required this.currentAdminId,
    required this.currentAdminName,
  });

  @override
  State<_UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends State<_UserEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late UserRole _role;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _role = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = widget.currentAdminId == widget.user.uid;
    final roleColor = {
      UserRole.customer: AppColors.primary,
      UserRole.seller: AppColors.accent,
      UserRole.driver: AppColors.info,
      UserRole.admin: Colors.purple,
    }[widget.user.role]!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 20),

            // User identity header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: roleColor.withOpacity(0.15),
                  backgroundImage: widget.user.photoUrl != null
                      ? NetworkImage(widget.user.photoUrl!)
                      : null,
                  child: widget.user.photoUrl == null
                      ? Text(
                          widget.user.fullName.isNotEmpty
                              ? widget.user.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: roleColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(widget.user.email,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      Text('UID: ${widget.user.uid.substring(0, 12)}...',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Edit Details',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 14),

            // Full Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            // Role
            DropdownButtonFormField<UserRole>(
              value: _role,
              decoration: InputDecoration(
                labelText: 'Role',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: UserRole.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r.name[0].toUpperCase() + r.name.substring(1),
                        ),
                      ))
                  .toList(),
              onChanged: isSelf
                  ? null // admins can't change their own role
                  : (v) => setState(() => _role = v!),
            ),
            if (isSelf)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('You cannot change your own role.',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ),
            const SizedBox(height: 16),

            // Active / Banned toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Account Active',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text(
                  _isActive
                      ? 'User can log in and use the app'
                      : 'User is banned — cannot log in',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: CupertinoSwitch(
                  value: _isActive,
                  activeColor: AppColors.primary,
                  onChanged: isSelf
                      ? null
                      : (v) => setState(() => _isActive = v),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),

            // Delete button (not for self)
            if (!isSelf) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  label: const Text('Delete User',
                      style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : () => _confirmDelete(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await FirebaseService.users.doc(widget.user.uid).update({
        'fullName': name,
        'phone': phone.isEmpty ? null : phone,
        'role': _role.name,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseService.logAudit(
        action: 'user_updated',
        actorId: widget.currentAdminId,
        actorName: widget.currentAdminName,
        targetId: widget.user.uid,
        targetType: 'user',
        details: {
          'changedName': name != widget.user.fullName,
          'changedRole': _role != widget.user.role,
          'changedActive': _isActive != widget.user.isActive,
        },
      );

      nav.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('User updated'),
        backgroundColor: AppColors.primary,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${widget.user.fullName}"?'),
            const SizedBox(height: 8),
            const Text(
              'This removes their Firestore profile and data. '
              'Their login account is deactivated. '
              'This cannot be undone.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteUser();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      // Delete Firestore document
      await FirebaseService.users.doc(widget.user.uid).delete();

      // Log audit
      await FirebaseService.logAudit(
        action: 'user_deleted',
        actorId: widget.currentAdminId,
        actorName: widget.currentAdminName,
        targetId: widget.user.uid,
        targetType: 'user',
        details: {
          'email': widget.user.email,
          'role': widget.user.role.name,
        },
      );

      nav.pop(); // close sheet
      messenger.showSnackBar(const SnackBar(
        content: Text('User deleted'),
        backgroundColor: AppColors.error,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Create User Sheet ─────────────────────────────────────────────────────────

class _CreateUserSheet extends StatefulWidget {
  final String adminId;
  final String adminName;

  const _CreateUserSheet({required this.adminId, required this.adminName});

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _saving = false;

  static const _creatableRoles = [UserRole.customer, UserRole.seller];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
          24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create User Account',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('Customer or Seller',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info banner
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A temporary password will be emailed to the user. '
                        'To create a Driver account, use the Manage Drivers page.',
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),

              // Role selector
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _creatableRoles
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.name[0].toUpperCase() +
                              r.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: Validators.fullName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone Number (optional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hintText: '+250 7XX XXX XXX',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _createUser,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Account',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    FirebaseApp? secondaryApp;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final tempPassword =
          'Fresh${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}!';

      // Use secondary Firebase App so the admin stays signed in
      secondaryApp = await Firebase.initializeApp(
        name: 'userCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: tempPassword,
      );
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();

      // Write Firestore user doc as admin (primary session intact)
      await FirebaseService.users.doc(uid).set({
        'email': _emailCtrl.text.trim(),
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'role': _role.name,
        'emailVerified': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send welcome email
      try {
        await EmailService.sendUserAccountCreated(
          to: _emailCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          role: _role.name,
          tempPassword: tempPassword,
        );
      } catch (_) {}

      // Audit log
      await FirebaseService.logAudit(
        action: 'user_created',
        actorId: widget.adminId,
        actorName: widget.adminName,
        targetId: uid,
        targetType: 'user',
        details: {
          'email': _emailCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'role': _role.name,
        },
      );

      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '${_role.name[0].toUpperCase()}${_role.name.substring(1)} account created. Credentials sent by email.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(_authErrorMessage(e.code)),
        backgroundColor: AppColors.error,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
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
      default:
        return 'Account creation failed ($code). Please try again.';
    }
  }
}
