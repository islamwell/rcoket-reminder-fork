import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedTheme = 'System';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildProfileSection(),
          SizedBox(height: 24),
          _buildNotificationSettings(),
          SizedBox(height: 24),
          _buildAppSettings(),
          SizedBox(height: 24),
          _buildAccountSection(),
          SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  AuthService.instance.isGuestMode ? Icons.person : Icons.person_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AuthService.instance.userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      AuthService.instance.userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (AuthService.instance.isGuestMode)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Guest Mode',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!AuthService.instance.isGuestMode)
                IconButton(
                  onPressed: _editProfile,
                  icon: Icon(Icons.edit, color: Color(0xFF667EEA)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          _buildSettingsTile(
            'Notification Settings',
            'Manage permissions and troubleshooting',
            Icons.notifications_active,
            () => Navigator.pushNamed(context, '/notification-settings'),
          ),
          _buildSwitchTile(
            'Enable Notifications',
            'Receive reminder notifications',
            _notificationsEnabled,
            (value) async {
              if (value && !_notificationsEnabled) {
                // Show permission request flow
                final result = await Navigator.pushNamed(context, '/notification-settings');
                // Refresh notification status after returning
                setState(() {
                  // This will be updated by the notification settings screen
                });
              } else {
                setState(() => _notificationsEnabled = value);
              }
            },
            Icons.notifications,
          ),
          _buildSwitchTile(
            'Sound',
            'Play sound with notifications',
            _soundEnabled,
            (value) => setState(() => _soundEnabled = value),
            Icons.volume_up,
          ),
          _buildSwitchTile(
            'Vibration',
            'Vibrate on notifications',
            _vibrationEnabled,
            (value) => setState(() => _vibrationEnabled = value),
            Icons.vibration,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          _buildSettingsTile(
            'Theme',
            _selectedTheme,
            Icons.palette,
            () => _showThemeDialog(),
          ),
          _buildSettingsTile(
            'Language',
            'English',
            Icons.language,
            () => _showLanguageDialog(),
          ),
          _buildSettingsTile(
            'Data & Storage',
            'Manage app data',
            Icons.storage,
            () => _showDataDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          if (AuthService.instance.isGuestMode) ...[
            _buildSettingsTile(
              'Create Account',
              'Save your data permanently',
              Icons.person_add,
              () => _createAccount(),
              color: Color(0xFF10B981),
            ),
          ] else ...[
            _buildSettingsTile(
              'Change Password',
              'Update your password',
              Icons.lock,
              () => _changePassword(),
            ),
            _buildSettingsTile(
              'Privacy Settings',
              'Manage your privacy',
              Icons.privacy_tip,
              () => _showPrivacySettings(),
            ),
          ],
          _buildSettingsTile(
            'Export Data',
            'Share your backup file',
            Icons.download,
            () => _exportData(),
          ),
          _buildSettingsTile(
            'Import Data',
            'Restore from backup file',
            Icons.upload,
            () => _importData(),
          ),
          _buildSettingsTile(
            'Auto Export Settings',
            'Configure daily backups',
            Icons.schedule,
            () => _showExportSettings(),
          ),
          SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          _buildSettingsTile(
            'Help & Support',
            'Get help with the app',
            Icons.help,
            () => _showHelp(),
          ),
          _buildSettingsTile(
            'Terms of Service',
            'Read our terms',
            Icons.description,
            () => _showTerms(),
          ),
          _buildSettingsTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.policy,
            () => _showPrivacyPolicy(),
          ),
          _buildSettingsTile(
            'App Version',
            '1.0.0',
            Icons.info,
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF667EEA), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF667EEA),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? Color(0xFF667EEA)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color ?? Color(0xFF667EEA), size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              AuthService.instance.isGuestMode ? 'Exit Guest Mode' : 'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    // TODO: Implement profile editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile editing coming soon!')),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Light'),
              value: 'Light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('System'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language selection coming soon!')),
    );
  }

  void _showDataDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data management coming soon!')),
    );
  }

  void _createAccount() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password change coming soon!')),
    );
  }

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Privacy settings coming soon!')),
    );
  }

  void _exportData() async {
    try {
      await DataExportService.instance.shareExportedData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importData() async {
    try {
      final success = await DataExportService.instance.importFromFile();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data imported successfully! Please restart the app.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import cancelled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExportSettings() async {
    final stats = await DataExportService.instance.getExportStats();
    final isAutoEnabled = await AutoExportScheduler.instance.isAutoExportEnabled();
    final timeUntilNext = AutoExportScheduler.instance.getTimeUntilNextExport();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auto Export: ${isAutoEnabled ? 'Enabled' : 'Disabled'}'),
            if (timeUntilNext != null)
              Text('Next export in: ${timeUntilNext.inHours}h ${timeUntilNext.inMinutes % 60}m'),
            SizedBox(height: 8),
            Text('Last export: ${stats['lastExportDate'] ?? 'Never'}'),
            Text('Backup files: ${stats['backupFilesCount'] ?? 0}'),
            Text('Data size: ${stats['totalDataSize'] ?? 'Unknown'}'),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Daily Auto Export'),
              subtitle: Text('Automatically backup data daily at 2 AM'),
              value: isAutoEnabled,
              onChanged: (value) async {
                if (value) {
                  await AutoExportScheduler.instance.enableAutoExport();
                } else {
                  await AutoExportScheduler.instance.disableAutoExport();
                }
                Navigator.pop(context);
                _showExportSettings(); // Refresh dialog
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AutoExportScheduler.instance.triggerManualExport();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Manual export completed!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            },
            child: Text('Export Now'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Help & support coming soon!')),
    );
  }

  void _showTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terms of service coming soon!')),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Privacy policy coming soon!')),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text(
          AuthService.instance.isGuestMode
              ? 'Are you sure you want to exit guest mode? Your data will be lost.'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                print('SettingsScreen: Starting logout process...');
                await AuthService.instance.logout();
                print('SettingsScreen: Logout completed, navigating to login...');
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                  print('SettingsScreen: Navigation to login completed');
                }
              } catch (e) {
                print('SettingsScreen: Error during logout: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed. Please try again.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}