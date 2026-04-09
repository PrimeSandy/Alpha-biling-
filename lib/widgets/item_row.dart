import 'package:flutter/material.dart';

import '../models/bill_item.dart';
import '../models/person.dart';
import '../providers/bill_provider.dart';
import 'person_chip.dart';

class ItemRow extends StatefulWidget {
  const ItemRow({
    super.key,
    required this.item,
    required this.people,
    required this.assigned,
    required this.provider,
  });

  final BillItem item;
  final List<Person> people;
  final List<String> assigned;
  final BillProvider provider;

  @override
  State<ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<ItemRow> {
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.item.unitPrice.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant ItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_priceController.selection.isValid) {
      _priceController.text = widget.item.unitPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submitPrice() {
    final old = widget.item.unitPrice;
    final next = double.tryParse(_priceController.text.trim()) ?? old;
    widget.provider.updateItemPrice(widget.item.id, next);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (item.isTax) _tag('TAX', Colors.orange),
                          if (item.isDiscount) _tag('DISCOUNT', Colors.green),
                        ],
                      ),
                      if (!item.isTax && !item.isDiscount)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => widget.provider
                                  .updateItemQuantity(item.id, item.quantity - 1),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => widget.provider
                                  .updateItemQuantity(item.id, item.quantity + 1),
                            ),
                            const Text(' × ', style: TextStyle(color: Colors.grey)),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _priceController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                    isDense: true, prefixText: '₹'),
                                style: const TextStyle(fontSize: 14),
                                onSubmitted: (_) => _submitPrice(),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            decoration: const InputDecoration(
                                isDense: true, prefixText: '₹'),
                            onSubmitted: (_) => _submitPrice(),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => widget.provider.removeItem(item.id),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.people
                  .map(
                    (person) => PersonChip(
                      person: person,
                      selected: widget.assigned.contains(person.id),
                      onTap: () =>
                          widget.provider.toggleAssign(item.id, person.id),
                    ),
                  )
                  .toList(),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => widget.provider.assignAllToItem(item.id),
                  child: const Text('All'),
                ),
                TextButton(
                  onPressed: () =>
                      widget.provider.clearItemAssignments(item.id),
                  child: const Text('None'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 10, color: color.shade900),
      ),
    );
  }
}
