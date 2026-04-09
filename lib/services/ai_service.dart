import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bill_item.dart';

class AIService {
  // Update this to your Vercel deployment URL
  static const _vercelUrl = 'https://alpha-biling-qt-main-sandys-projects-eb748d0b.vercel.app/api/scan';

  Future<List<BillItem>> scanBill(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('PREFERRED_AI') ?? 'claude';
    
    String? apiKey;
    if (provider == 'claude') {
      apiKey = prefs.getString('ANTHROPIC_API_KEY') ?? dotenv.env['ANTHROPIC_API_KEY'];
    } else {
      apiKey = prefs.getString('GEMINI_API_KEY') ?? dotenv.env['GEMINI_API_KEY'];
    }

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse(_vercelUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image': base64Image,
        'provider': provider,
        'apiKey': apiKey,
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final List parsed = jsonDecode(response.body) as List;
      return parsed
          .map(
            (item) => BillItem(
              id: item['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
              name: item['name'] as String,
              unitPrice: (item['unitPrice'] as num).toDouble(),
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            ),
          )
          .toList();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('API routing failed: $error');
    }
  }
}
