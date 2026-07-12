import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = ref.read(databaseProvider);
    final users = await db.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  void _showUserDialog([User? user]) {
    final isEdit = user != null;
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final passwordCtrl = TextEditingController();
    String selectedRole = user?.role ?? 'operator';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Username'),
                      enabled: !isEdit || user.username != 'admin', // Prevent changing admin username easily
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordCtrl,
                      decoration: InputDecoration(
                        labelText: isEdit ? 'Password Baru (Kosongi jika tidak diubah)' : 'Password',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'operator', child: Text('Operator')),
                      ],
                      onChanged: (val) {
                        setStateDialog(() => selectedRole = val!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (usernameCtrl.text.isEmpty || fullNameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Username dan Nama harus diisi')),
                      );
                      return;
                    }
                    if (!isEdit && passwordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password harus diisi untuk pengguna baru')),
                      );
                      return;
                    }

                    final db = ref.read(databaseProvider);
                    if (isEdit) {
                      final updatedUser = user.copyWith(
                        username: usernameCtrl.text,
                        fullName: fullNameCtrl.text,
                        role: selectedRole,
                        passwordHash: passwordCtrl.text.isNotEmpty ? _hashPassword(passwordCtrl.text) : user.passwordHash,
                      );
                      await db.updateUser(updatedUser);
                    } else {
                      await db.insertUser(UsersCompanion.insert(
                        username: usernameCtrl.text,
                        passwordHash: _hashPassword(passwordCtrl.text),
                        fullName: fullNameCtrl.text,
                        role: drift.Value(selectedRole),
                      ));
                    }
                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadUsers();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUser(User user) async {
    if (user.username == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User admin default tidak dapat dihapus')),
      );
      return;
    }
    
    final currentUserId = ref.read(authProvider).currentUser?.id;
    if (currentUserId == user.id) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak dapat menghapus akun Anda sendiri')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    await db.deleteUser(user.id);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (ctx, i) {
          final u = _users[i];
          return ListTile(
            leading: CircleAvatar(child: Text(u.username[0].toUpperCase())),
            title: Text('${u.fullName} (${u.username})'),
            subtitle: Text('Role: ${u.role}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showUserDialog(u),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(u),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
