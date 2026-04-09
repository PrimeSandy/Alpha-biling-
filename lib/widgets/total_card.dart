import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';

class TotalCard extends StatelessWidget {
  const TotalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        final totals = provider.calculateTotals();
        final assignedTotal = totals.values.fold(0.0, (a, b) => a + b);

        return Card(
          elevation: 2,
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Subtotal', provider.subtotal),
                if (provider.totalDiscounts != 0)
                  _row('Discounts', provider.totalDiscounts, color: Colors.green),
                if (provider.totalTax != 0)
                  _row('Tax', provider.totalTax, color: Colors.orange.shade800),
                if (provider.tip != 0) _row('Tip', provider.tip),
                const Divider(),
                _row('Bill Total', provider.grandTotal, isBold: true),
                _row('Assigned', assignedTotal,
                    color: (assignedTotal - provider.grandTotal).abs() < 0.01
                        ? Colors.green
                        : Colors.red,
                    isBold: true),
                if (provider.hasUnassignedItems)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Some items are unassigned',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, double amount, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
