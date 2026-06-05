import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Services/UserService.dart';
import 'package:pharmacy_wms/widgets/empty_state.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await UserService.getAllUsers();
      setState(() {
        _users = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showCreateUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'User'; // Default to User (Supervisor)
    bool loading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tr = context.tr;
          return AlertDialog(
            title: Text(tr.registerNewUser),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: tr.fullName,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: tr.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: tr.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: tr.roleLabel,
                        prefixIcon: const Icon(Icons.security),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Admin', child: Text('Warehouse Manager (Admin)')),
                        DropdownMenuItem(value: 'User', child: Text('Supervisor (User)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(dialogError!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: Text(tr.cancel),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final password = passwordCtrl.text;

                        if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
                          setDialogState(() => dialogError = 'All fields are required.');
                          return;
                        }
                        if (password.length < 6) {
                          setDialogState(() => dialogError = tr.atLeast6Chars);
                          return;
                        }

                        setDialogState(() {
                          loading = true;
                          dialogError = null;
                        });

                        try {
                          String? err;
                          if (selectedRole == 'Admin') {
                            err = await AuthService.registerAdmin(
                              email: email,
                              password: password,
                              fullName: name,
                              phoneNumber: phone,
                            );
                          } else {
                            err = await AuthService.registerUser(
                              email: email,
                              password: password,
                              fullName: name,
                              phoneNumber: phone,
                            );
                          }

                          if (err != null) {
                            setDialogState(() => dialogError = err);
                          } else {
                            Navigator.pop(context);
                            _loadUsers();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(tr.success)),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => dialogError = e.toString());
                        } finally {
                          setDialogState(() => loading = false);
                        }
                      },
                child: Text(loading ? tr.loading : tr.createAccount),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] == 'Admin' ? 'Admin' : 'User';
    bool loading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tr = context.tr;
          return AlertDialog(
            title: Text('${tr.changeRole}: ${user['fullName']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: tr.roleLabel),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Warehouse Manager (Admin)')),
                    DropdownMenuItem(value: 'User', child: Text('Supervisor (User)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: Text(tr.cancel),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        setDialogState(() {
                          loading = true;
                          dialogError = null;
                        });
                        try {
                          await UserService.changeRole(user['id'].toString(), selectedRole);
                          Navigator.pop(context);
                          _loadUsers();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(tr.success)),
                          );
                        } catch (e) {
                          setDialogState(() => dialogError = e.toString().replaceFirst('Exception: ', ''));
                        } finally {
                          setDialogState(() => loading = false);
                        }
                      },
                child: Text(loading ? tr.loading : tr.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final passwordCtrl = TextEditingController();
    bool loading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tr = context.tr;
          return AlertDialog(
            title: Text('${tr.resetPassword}: ${user['fullName']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: Text(tr.cancel),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final pw = passwordCtrl.text;
                        if (pw.length < 6) {
                          setDialogState(() => dialogError = tr.atLeast6Chars);
                          return;
                        }
                        setDialogState(() {
                          loading = true;
                          dialogError = null;
                        });
                        try {
                          await UserService.resetPassword(user['id'].toString(), pw);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(tr.success)),
                          );
                        } catch (e) {
                          setDialogState(() => dialogError = e.toString().replaceFirst('Exception: ', ''));
                        } finally {
                          setDialogState(() => loading = false);
                        }
                      },
                child: Text(loading ? tr.loading : tr.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final newState = await UserService.toggleStatus(user['id'].toString());
      setState(() {
        user['isActive'] = newState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.success)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.confirmDelete),
        content: Text('Are you sure you want to delete user: ${user['fullName']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.deleteUser(user['id'].toString());
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.success)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A1A1F) : const Color(0xFFF5F9FA);
    final cardColor = isDark ? const Color(0xFF1A2F35) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt_outlined, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 10),
                Text(
                  tr.userManagement,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: tr.refresh,
                  onPressed: _loadUsers,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.add),
                  label: Text(tr.registerNewUser),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CA0A5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildContent(cardColor, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color cardColor, bool isDark) {
    final tr = context.tr;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text(tr.retry),
            ),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No Users Found',
        subtitle: 'Add new staff members to manage inventory access.',
      );
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          itemCount: _users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final u = _users[index];
            final role = u['role'] == 'Admin' ? 'Warehouse Manager' : 'Supervisor';
            final roleColor = u['role'] == 'Admin' ? Colors.blue : Colors.green;
            final isActive = u['isActive'] as bool? ?? true;
            final dateStr = u['createdAt'] != null
                ? u['createdAt'].toString().substring(0, 10)
                : '-';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: roleColor.withOpacity(0.12),
                    child: Icon(
                      u['role'] == 'Admin' ? Icons.admin_panel_settings : Icons.person,
                      color: roleColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u['fullName'] ?? tr.unknownUser,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u['email'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.createdAt,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      Text(
                        isActive ? tr.userStatusActive : tr.userStatusInactive,
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (val) => _toggleUserStatus(u),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'role') {
                        _showChangeRoleDialog(u);
                      } else if (action == 'password') {
                        _showResetPasswordDialog(u);
                      } else if (action == 'delete') {
                        _deleteUser(u);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'role',
                        child: Row(
                          children: [
                            const Icon(Icons.security, size: 18),
                            const SizedBox(width: 8),
                            Text(tr.changeRole),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'password',
                        child: Row(
                          children: [
                            const Icon(Icons.lock_reset, size: 18),
                            const SizedBox(width: 8),
                            Text(tr.resetPassword),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(tr.delete, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
