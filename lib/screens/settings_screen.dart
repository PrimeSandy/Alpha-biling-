import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _claudeController = TextEditingController();
  final _geminiController = TextEditingController();
  bool _isLoading = true;
  String _selectedProvider = 'claude';


  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _claudeController.text = prefs.getString('ANTHROPIC_API_KEY') ?? '';
      _geminiController.text = prefs.getString('GEMINI_API_KEY') ?? '';
      _selectedProvider = prefs.getString('PREFERRED_AI') ?? 'claude';
      _isLoading = false;
    });

  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ANTHROPIC_API_KEY', _claudeController.text.trim());
    await prefs.setString('GEMINI_API_KEY', _geminiController.text.trim());
    await prefs.setString('PREFERRED_AI', _selectedProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'API Configuration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keys are stored locally on your device.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  const Text('Preferred AI Engine', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'claude', label: Text('Claude')),
                      ButtonSegment(value: 'gemini', label: Text('Gemini')),
                    ],
                    selected: {_selectedProvider},
                    onSelectionChanged: (s) => setState(() => _selectedProvider = s.first),
                  ),
                  const SizedBox(height: 32),

                  TextField(
                    controller: _claudeController,
                    decoration: const InputDecoration(
                      labelText: 'Claude (Anthropic) API Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _geminiController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini (Google) API Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _claudeController.dispose();
    _geminiController.dispose();
    super.dispose();
  }
}
