import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../widgets/item_row.dart';
import '../widgets/total_card.dart';
import '../widgets/step_indicator.dart';
import 'pay_screen.dart';

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});
  static const routeName = '/assign';

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  Future<void> _addManualItem(BillProvider provider) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'What is it?'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price', prefixText: '₹'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim());
              if (name.isEmpty || price == null) return;
              provider.addItem(
                BillItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name,
                  unitPrice: price,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        final hasTax = provider.items.any((i) => i.isTax);

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
                    title: Text('Assign Items', style: Theme.of(context).textTheme.displayMedium),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 700),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const StepIndicator(current: 3),
                            const SizedBox(height: 32),
                            _buildTopControls(provider, hasTax),
                            const SizedBox(height: 16),
                            ...provider.items.map((item) => ItemRow(
                                  item: item,
                                  people: provider.people,
                                  assigned: provider.assignments[item.id] ?? [],
                                  provider: provider,
                                )),
                            const TotalCard(),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addManualItem(provider),
            icon: const Icon(Icons.add),
            label: const Text('Manual Add'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildTopControls(BillProvider provider, bool hasTax) {
    return Column(
      children: [
        if (hasTax)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Tax Allocation Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Prop.', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: false, label: Text('Equal', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {provider.taxProportional},
                    onSelectionChanged: (s) => provider.setTaxMode(s.first),
                    showSelectedIcon: false,
                  ),
                ],
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Split', style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                TextButton.icon(
                  onPressed: provider.splitAllEqually,
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text('All Equally'),
                ),
                TextButton.icon(
                  onPressed: provider.clearAllAssignments,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
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
            onPressed: () => Navigator.pushNamed(context, PayScreen.routeName),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Finalize & Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.check_circle_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
