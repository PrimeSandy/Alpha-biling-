import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/bill_provider.dart';
import '../services/upi_service.dart';
import '../widgets/person_chip.dart';
import '../widgets/step_indicator.dart';
import 'scan_screen.dart';

enum PaymentMode { restaurant, friend }

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});
  static const routeName = '/pay';

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  PaymentMode _mode = PaymentMode.restaurant;
  final _upiService = UpiService();
  final _friendPayerUpiController = TextEditingController();

  @override
  void dispose() {
    _friendPayerUpiController.dispose();
    super.dispose();
  }

  Future<void> _pay({
    required String upiId,
    required String payeeName,
    required double amount,
    required String note,
  }) async {
    if (upiId.trim().isEmpty) return;
    final link = _upiService.buildUPILink(
      upiId: upiId.trim(),
      payeeName: payeeName,
      amount: amount,
      note: note,
    );
    await _upiService.launchUPI(link, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, provider, _) {
        final totals = provider.calculateTotals();
        final people = provider.people;
        final selectedPayer = provider.payerId;
        final noPayer = _mode == PaymentMode.friend && selectedPayer == null;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                title: Text('Settlement', style: Theme.of(context).textTheme.displayMedium),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StepIndicator(current: 4),
                        const SizedBox(height: 32),
                        _buildPaymentSwitcher(),
                        const SizedBox(height: 24),
                        if (_mode == PaymentMode.friend) _buildPayerSelection(provider),
                        const SizedBox(height: 16),
                        ...people.map((p) => _buildPersonPaymentCard(p, provider, totals, noPayer)),
                        const SizedBox(height: 24),
                        _buildSummarySection(provider),
                        const SizedBox(height: 48),
                        _buildFinalActions(provider),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentSwitcher() {
    return SegmentedButton<PaymentMode>(
      segments: const [
        ButtonSegment(value: PaymentMode.restaurant, icon: Icon(Icons.restaurant), label: Text('Restaurant')),
        ButtonSegment(value: PaymentMode.friend, icon: Icon(Icons.person_pin), label: Text('Split with Friend')),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() => _mode = s.first),
    );
  }

  Widget _buildPayerSelection(BillProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Who paid the bill?', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.people
                .map((p) => PersonChip(
                      person: p,
                      selected: provider.payerId == p.id,
                      onTap: () {
                        provider.setPayer(p.id);
                        if (p.upiId.isNotEmpty) _friendPayerUpiController.text = p.upiId;
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _friendPayerUpiController,
            decoration: InputDecoration(
              hintText: 'Payer UPI ID (e.g. name@bank)',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonPaymentCard(dynamic p, BillProvider provider, Map<String, double> totals, bool disabled) {
    if (_mode == PaymentMode.friend && p.id == provider.payerId) return const SizedBox.shrink();

    final amount = totals[p.id] ?? 0.0;
    if (amount <= 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: p.avatarColor,
              child: Text(p.initials, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Total Share: ₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            if (_mode == PaymentMode.restaurant)
              SizedBox(
                width: 100,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'UPI ID', isDense: true),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (v) => provider.updatePersonUpi(p.id, v),
                ),
              ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: disabled
                  ? null
                  : () => _pay(
                        upiId: _mode == PaymentMode.friend ? _friendPayerUpiController.text : p.upiId,
                        payeeName: _mode == PaymentMode.friend
                            ? provider.people.firstWhere((per) => per.id == provider.payerId).name
                            : p.name,
                        amount: amount,
                        note: 'BillSplit Settlement',
                      ),
              icon: const Icon(Icons.payment, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BillProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text('₹${provider.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          _summaryRow('Subtotal', provider.subtotal),
          if (provider.totalTax > 0) _summaryRow('Taxes', provider.totalTax),
          if (provider.tip > 0) _summaryRow('Tips', provider.tip),
          if (provider.totalDiscounts < 0) _summaryRow('Discounts', provider.totalDiscounts),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text('₹${val.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFinalActions(BillProvider provider) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => Share.share(provider.buildWhatsappSummary()),
          icon: const Icon(Icons.share),
          label: const Text('Share Summary with Friends'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: const Color(0xFF25D366),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            provider.resetAll();
            Navigator.pushNamedAndRemoveUntil(context, ScanScreen.routeName, (r) => false);
          },
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          child: const Text('Start New Bill'),
        ),
      ],
    );
  }
}
