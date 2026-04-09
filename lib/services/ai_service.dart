import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bill_item.dart';
import 'claude_service.dart';
import 'gemini_service.dart';

class AIService {
  final _claude = ClaudeService();
  final _gemini = GeminiService();

  Future<List<BillItem>> scanBill(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('PREFERRED_AI') ?? 'claude';
    
    // Call the respective service directly (removing Vercel proxy)
    if (provider == 'claude') {
      return await _claude.scanBill(imageFile);
    } else {
      return await _gemini.scanBill(imageFile);
    }
  }
}
