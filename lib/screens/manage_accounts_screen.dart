import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

// Simple model representing a user account
class UserAccount {
  final String id;
  final String name;
  final String handle;
  final String avatarUrl;
  bool isCurrent;

  UserAccount({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    this.isCurrent = false,
  });
}

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  // Mock list of multi-accounts stored on the device
  final List<UserAccount> _accounts = [
    UserAccount(
      id: '1',
      name: 'Suraj Meena',
      handle: '@suraj_meena_mp',
      avatarUrl: '',
      isCurrent: true,
    ),
    UserAccount(
      id: '2',
      name: 'Vidisha Security Tech',
      handle: '@vidisha_cctv',
      avatarUrl: '',
      isCurrent: false,
    ),
  ];

  void _switchAccount(UserAccount selectedAccount) {
    setState(() {
      for (var acc in _accounts) {
        acc.isCurrent = (acc.id == selectedAccount.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to ${selectedAccount.name} (${selectedAccount.handle}) 🔄')),
    );
  }

  void _addNewAccount() {
    TextEditingController nameController = TextEditingController();
    TextEditingController handleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = AppThemeNotifier.instance.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF242424) : Colors.white,
          title: const Text('Add Existing or New Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Profile Name (e.g., John Doe)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: handleController,
                decoration: const InputDecoration(labelText: 'Username Handle (e.g., @johndoe)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppThemeNotifier.instance.primaryColor),
              onPressed: () {
                if (nameController.text.isNotEmpty && handleController.text.isNotEmpty) {
                  setState(() {
                    _accounts.add(
                      UserAccount(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        handle: handleController.text.startsWith('@') ? handleController.text : '@${handleController.text}',
                        avatarUrl: '',
                        isCurrent: false,
                      ),
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New account added successfully! ✨')),
                  );
                }
              },
              child: const Text('Add Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _removeAccount(UserAccount account) {
    if (_accounts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must keep at least one account logged in.')),
      );
      return;
    }

    setState(() {
      _accounts.removeWhere((acc) => acc.id == account.id);
      // If removed account was current, make the first remaining account current
      if (account.isCurrent && _accounts.isNotEmpty) {
        _accounts.first.isCurrent = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed account ${account.handle} from this device.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Manage Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Switch between your connected accounts or add an alternative profile securely to this device.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // List of Accounts
              Container(
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: _accounts.map((acc) {
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: acc.isCurrent ? themeNotifier.primaryColor : Colors.grey.shade400,
                            child: Text(
                              acc.name.isNotEmpty ? acc.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(acc.handle, style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white70 : Colors.grey[600])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (acc.isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              else
                                TextButton(
                                  onPressed: () => _switchAccount(acc),
                                  child: const Text('Switch'),
                                ),
                              if (!acc.isCurrent)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () => _removeAccount(acc),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Add Account Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: themeNotifier.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addNewAccount,
                icon: Icon(Icons.person_add, color: themeNotifier.primaryColor),
                label: Text('Add Another Account', style: TextStyle(color: themeNotifier.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}