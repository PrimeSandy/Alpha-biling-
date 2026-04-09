import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../models/bill_item.dart';

class ClaudeService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  Future<List<BillItem>> scanBill(File imageFile) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      minWidth: 1080,
      minHeight: 1920,
      quality: 75,
    );
    if (compressedBytes == null) {
      throw Exception('Could not read image.');
    }

    final safeBytes = _clampToOneMb(compressedBytes);
    final base64Image = base64Encode(safeBytes);

    final body = jsonEncode({
      "model": "claude-sonnet-4-20250514",
      "max_tokens": 1000,
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "type": "image",
              "source": {
                "type": "base64",
                "media_type": "image/jpeg",
                "data": base64Image
              }
            },
            {
              "type": "text",
              "text":
                  "Extract all line items from this bill. Return ONLY a valid JSON array. Format: [{\"id\":\"1\",\"name\":\"Item name\",\"unitPrice\":120,\"quantity\":1}]. Keep tax/GST/Service Charge as separate items. If an item is a discount, use a negative unitPrice."
            }
          ]
        }
      ]
    });

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>;
      final text = (content.first as Map<String, dynamic>)['text'] as String;
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
        throw const FormatException('Malformed JSON from Claude');
      }
    } else {
      throw Exception('Scan failed: ${response.statusCode}');
    }
  }

  List<int> _clampToOneMb(List<int> bytes) {
    const max = 1024 * 1024;
    if (bytes.length <= max) return bytes;
    return bytes.sublist(0, max);
  }
}
