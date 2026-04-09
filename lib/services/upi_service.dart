import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiService {
  String buildUPILink({
    required String upiId,
    required String payeeName,
    required double amount,
    required String note,
  }) {
    final params = {
      'pa': upiId,
      'pn': payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': note,
    };
    final query = params.entries
        .map(
          (e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    return 'upi://pay?$query';
  }

  Future<void> launchUPI(String link, {BuildContext? context}) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No UPI app found on device')),
      );
    }
  }
}
