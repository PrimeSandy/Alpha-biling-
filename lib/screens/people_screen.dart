import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/bill_provider.dart';
import '../widgets/step_indicator.dart';
import 'assign_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});
  static const routeName = '/people';

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _nameController = TextEditingController();
  final _avatarColors = const [
    Color(0xFFFDE68A),
    Color(0xFFBFDBFE),
    Color(0xFFBBF7D0),
    Color(0xFFFECACA),
    Color(0xFFE9D5FF),
    Color(0xFFFED7AA),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPerson(BillProvider provider) {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) return;
    var uniqueName = rawName;
    var suffix = 2;
    while (provider.people.any((p) => p.name == uniqueName)) {
      uniqueName = '$rawName $suffix';
      suffix++;
    }
    final index = provider.people.length % _avatarColors.length;
    final color = _avatarColors[index];
    provider.addPerson(
      Person(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: uniqueName,
        avatarColor: color,
        textColor: Colors.black87,
      ),
    );
    _nameController.clear();
  }

  Future<void> _editPerson(Person person, BillProvider provider) async {
    final controller = TextEditingController(text: person.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updatePersonName(person.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    title: Text('Add Friends', style: Theme.of(context).textTheme.displayMedium),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const StepIndicator(current: 2),
                            const SizedBox(height: 32),
                            _buildInputArea(provider),
                            const SizedBox(height: 24),
                            _buildPeopleGrid(provider),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildBottomAction(provider),
            ],
          ),
        );
      },
    );
  }
  Widget _buildInputArea(BillProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Friend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter name...',
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                  ),
                  onSubmitted: (_) => _addPerson(provider),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _addPerson(provider),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleGrid(BillProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${provider.people.length} Friends added', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: provider.people.map((person) => _personCard(person, provider)).toList(),
        ),
      ],
    );
  }

  Widget _personCard(Person person, BillProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: person.avatarColor,
            child: Text(person.initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Text(person.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey),
            onPressed: () => _editPerson(person, provider),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
            onPressed: () => provider.removePerson(person.id),
          ),
        ],
      ),
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
          child: Row(
            children: [
              IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.people.length >= 2
                      ? () => Navigator.pushNamed(context, AssignScreen.routeName)
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
