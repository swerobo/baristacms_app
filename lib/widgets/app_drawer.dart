import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/module_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final moduleProvider = context.watch<ModuleProvider>();

    return Drawer(
      child: Column(
        children: [
          // User Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (authService.userName ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountName: Text(authService.userName ?? 'User'),
            accountEmail: Text(authService.userEmail ?? ''),
          ),

          // Home
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),

          const Divider(),

          // Modules Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'MODULES',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Module List
          Expanded(
            child: moduleProvider.modules.isEmpty
                ? Center(
                    child: Text(
                      'No modules available',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    itemCount: moduleProvider.modules.length,
                    itemBuilder: (context, index) {
                      final module = moduleProvider.modules[index];
                      return ListTile(
                        leading: Icon(
                          Icons.folder_outlined,
                          color: Colors.blue.shade700,
                        ),
                        title: Text(module.displayName),
                        subtitle: module.description != null
                            ? Text(
                                module.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          moduleProvider.setCurrentModule(module);
                          Navigator.pushNamed(
                            context,
                            '/records',
                            arguments: module.name,
                          );
                        },
                      );
                    },
                  ),
          ),

          const Divider(),

          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
