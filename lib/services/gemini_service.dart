import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bill_item.dart';

class GeminiService {
  Future<List<BillItem>> scanBill(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('GEMINI_API_KEY') ?? dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('Gemini API Key is missing. Please add it in Settings.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    final imageBytes = await imageFile.readAsBytes();
    final content = [
      Content.multi([
        TextPart(
            "Extract all line items from this bill. Return ONLY a valid JSON array. Format: [{\"id\":\"1\",\"name\":\"Item name\",\"unitPrice\":120,\"quantity\":1}]. Keep tax/GST/Service Charge as separate items. If an item is a discount, use a negative unitPrice."),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await model.generateContent(content);
    final text = response.text;

    if (text == null) {
      throw Exception('No response from Gemini');
    }

    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      final List parsed = jsonDecode(cleaned) as List;
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
    } catch (_) {
      throw const FormatException('Malformed JSON from Gemini');
    }
  }
}
