import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../providers/module_provider.dart';

// Map heroicon names to Flutter Icons
IconData getIconForModule(String? iconName) {
  if (iconName == null || iconName.isEmpty) {
    return Icons.folder_outlined;
  }

  final iconMap = {
    'HomeIcon': Icons.home_outlined,
    'CubeIcon': Icons.view_in_ar_outlined,
    'UsersIcon': Icons.people_outlined,
    'UserGroupIcon': Icons.groups_outlined,
    'BuildingOffice2Icon': Icons.business_outlined,
    'TruckIcon': Icons.local_shipping_outlined,
    'BeakerIcon': Icons.science_outlined,
    'WrenchIcon': Icons.build_outlined,
    'WrenchScrewdriverIcon': Icons.construction_outlined,
    'ComputerDesktopIcon': Icons.computer_outlined,
    'PhoneIcon': Icons.phone_outlined,
    'DocumentTextIcon': Icons.description_outlined,
    'ClipboardDocumentListIcon': Icons.assignment_outlined,
    'FolderIcon': Icons.folder_outlined,
    'ArchiveBoxIcon': Icons.archive_outlined,
    'InboxIcon': Icons.inbox_outlined,
    'CalendarIcon': Icons.calendar_today_outlined,
    'ClockIcon': Icons.access_time_outlined,
    'ChartBarIcon': Icons.bar_chart_outlined,
    'TagIcon': Icons.label_outlined,
    'MapPinIcon': Icons.location_on_outlined,
    'Cog6ToothIcon': Icons.settings_outlined,
    'ShieldCheckIcon': Icons.shield_outlined,
    'KeyIcon': Icons.key_outlined,
    'Squares2X2Icon': Icons.grid_view_outlined,
    'StarIcon': Icons.star_outline,
    'HeartIcon': Icons.favorite_outline,
    'BellIcon': Icons.notifications_outlined,
    'BookOpenIcon': Icons.menu_book_outlined,
    'BriefcaseIcon': Icons.work_outline,
    'CameraIcon': Icons.camera_alt_outlined,
    'ChatBubbleLeftIcon': Icons.chat_bubble_outline,
    'CloudIcon': Icons.cloud_outlined,
    'CurrencyDollarIcon': Icons.attach_money_outlined,
    'GlobeAltIcon': Icons.public_outlined,
    'LightBulbIcon': Icons.lightbulb_outline,
    'MusicalNoteIcon': Icons.music_note_outlined,
    'PaperClipIcon': Icons.attach_file_outlined,
    'ShoppingCartIcon': Icons.shopping_cart_outlined,
    'TicketIcon': Icons.confirmation_number_outlined,
    'VideoCameraIcon': Icons.videocam_outlined,
  };

  return iconMap[iconName] ?? Icons.folder_outlined;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Get initial for avatar, handling null/empty names
  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final moduleProvider = context.watch<ModuleProvider>();
    final settingsService = context.watch<SettingsService>();
    final isDarkMode = settingsService.darkMode;
    final primaryColor = isDarkMode ? Colors.grey.shade800 : Theme.of(context).colorScheme.primary;

    return Drawer(
      child: Column(
        children: [
          // User Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _getInitial(authService.userName),
                style: TextStyle(
                  fontSize: 24,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountName: Text(authService.userName?.isNotEmpty == true ? authService.userName! : 'User'),
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
                          getIconForModule(module.icon),
                          color: primaryColor,
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

          // Settings
          ListTile(
            leading: Icon(Icons.settings, color: primaryColor),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),

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
