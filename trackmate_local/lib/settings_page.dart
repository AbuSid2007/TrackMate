import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- State Variables ---
  String _userRole = 'User'; // Default
  String _username = 'Krishna Agrawal';

  // Toggles
  bool _isDarkMode = false;
  bool _useMetric = true; // true = kg/km, false = lbs/miles
  bool _isProfileVisible = true;
  bool _acceptingClients = true; // For Trainers only

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('saved_role') ?? 'User';
      // In a real app, you would load the other saved preferences here too
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          // 1. Profile Section (Universal)
          _buildSectionHeader('Profile'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(radius: 40, backgroundColor: Color(0xFF427AFA), child: Icon(Icons.person, size: 40, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                  controller: TextEditingController(text: _username),
                  onChanged: (val) => _username = val,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF427AFA), minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Preferences Section (Universal)
          _buildSectionHeader('App Preferences'),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: _isDarkMode,
                  activeColor: const Color(0xFF427AFA),
                  onChanged: (bool value) => setState(() => _isDarkMode = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Use Metric System'),
                  subtitle: Text(_useMetric ? 'Kilograms (kg), Kilometers (km)' : 'Pounds (lbs), Miles (mi)'),
                  secondary: const Icon(Icons.straighten),
                  value: _useMetric,
                  activeColor: const Color(0xFF427AFA),
                  onChanged: (bool value) => setState(() => _useMetric = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Privacy & Visibility (Universal, but phrasing changes)
          _buildSectionHeader('Privacy'),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: SwitchListTile(
              title: const Text('Public Profile'),
              subtitle: Text(_userRole == 'Trainer'
                  ? 'Allow users to find you in the Trainer directory'
                  : 'Allow friends to see your workout streaks'),
              secondary: const Icon(Icons.visibility_outlined),
              value: _isProfileVisible,
              activeColor: const Color(0xFF427AFA),
              onChanged: (bool value) => setState(() => _isProfileVisible = value),
            ),
          ),
          const SizedBox(height: 24),

          // 4. ROLE SPECIFIC SECTIONS
          if (_userRole == 'Trainer') ...[
            _buildSectionHeader('Trainer Options'),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: SwitchListTile(
                title: const Text('Accepting New Clients'),
                subtitle: const Text('Show your profile as "Available"'),
                secondary: const Icon(Icons.work_outline),
                value: _acceptingClients,
                activeColor: Colors.green,
                onChanged: (bool value) => setState(() => _acceptingClients = value),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (_userRole == 'Admin') ...[
            _buildSectionHeader('Admin Controls'),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text('Manage Platform Users', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Admin Dashboard...")));
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}