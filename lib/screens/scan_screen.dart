import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../services/ai_service.dart';
import '../widgets/step_indicator.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'people_screen.dart';
import 'settings_screen.dart';


class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  static const routeName = '/';

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();
  final _aiService = AIService();
  File? _pickedImage;

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedImage = File(x.path));
  }

  void _manualAdd(BillProvider provider) {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null) return;
    provider.addItem(
      BillItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        unitPrice: price,
      ),
    );
    _nameController.clear();
    _priceController.clear();
  }

  Future<void> _scan(BillProvider provider) async {
    if (_pickedImage == null) return;
    setState(() => _loading = true);
    try {
      final items = await _aiService.scanBill(_pickedImage!);
          
      for (final item in items) {
        provider.addItem(item);
      }
    } catch (e) {


      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: Text('BillSplit', style: Theme.of(context).textTheme.displayMedium),
                    actions: [
                      if (provider.items.isNotEmpty)
                        IconButton(
                          onPressed: provider.resetAll,
                          icon: const Icon(Icons.refresh),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
                        icon: const Icon(Icons.settings),
                      ),

                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const StepIndicator(current: 1),
                            const SizedBox(height: 32),
                            _buildHeroCard(),
                            const SizedBox(height: 24),
                            if (_pickedImage != null) _buildImagePreview(provider),
                            if (provider.items.isNotEmpty) _buildItemsList(provider),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (provider.items.isNotEmpty) _buildBottomAction(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text(
            'Smart Scan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan your bill with AI or add items manually',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Camera',
                  Icons.camera_alt_outlined,
                  () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  'Gallery',
                  Icons.photo_library_outlined,
                  () => _pick(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  'Manual',
                  Icons.edit_note,
                  () => _showManualEntryDialog(provider),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BillProvider provider) {
    return Card(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.file(_pickedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading)
                  const LinearProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: () => _scan(provider),
                    icon: const Icon(Icons.bolt),
                    label: const Text('AI Analytics Engine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                TextButton(
                  onPressed: () => setState(() => _pickedImage = null),
                  child: const Text('Remove Image'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BillProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Detected Items', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...provider.items.asMap().entries.map((entry) {
          final item = entry.value;
          return Dismissible(
            key: ValueKey(item.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red.shade100,
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            onDismissed: (_) => provider.removeItem(item.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomAction(BillProvider provider) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, PeopleScreen.routeName),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Proceed to People', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualEntryDialog(BillProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Chicken Biriyani',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: 'e.g. 180',
                prefixText: '₹ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _manualAdd(provider);
              Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}

