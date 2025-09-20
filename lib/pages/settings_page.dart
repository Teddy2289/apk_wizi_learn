import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _interfaceChoice = 'classic';
  bool _showTutorials = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _interfaceChoice = prefs.getString('interfaceChoice') ?? 'classic';
      _showTutorials = prefs.getBool('showTutorials') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('interfaceChoice', _interfaceChoice);
    await prefs.setBool('showTutorials', _showTutorials);
    // Optional: call API to sync settings
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Interface', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Classique'),
                    value: 'classic',
                    groupValue: _interfaceChoice,
                    onChanged: (v) => setState(() => _interfaceChoice = v ?? 'classic'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Moderne'),
                    value: 'modern',
                    groupValue: _interfaceChoice,
                    onChanged: (v) => setState(() => _interfaceChoice = v ?? 'modern'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Compact'),
                    value: 'compact',
                    groupValue: _interfaceChoice,
                    onChanged: (v) => setState(() => _interfaceChoice = v ?? 'compact'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Afficher les didacticiels'),
              value: _showTutorials,
              onChanged: (v) => setState(() => _showTutorials = v),
            ),
            const Spacer(),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('interfaceChoice');
                    await prefs.remove('showTutorials');
                    await _loadSettings();
                  },
                  child: const Text('Réinitialiser'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await _saveSettings();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres enregistrés')));
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
