// lib/gemini/gemini_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cuhokhancap/user/models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/models/luuanhmodel.dart';

class GeminiService {
  // API Key Gemini từ Google AI Studio
  static const String _apiKey =
      'AQ.Ab8RN6LXiOhr6C2QL4RugZ9GVXpbleI6CNKOCtkFHmkFbUdz3Q'; // Thay API Key của Bảo tại đây

  late final GenerativeModel _model;

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  GeminiService._internal() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json', // Ép Gemini trả JSON chuẩn
      ),
    );
  }

  /// 🌟 Phân tích đa phương thức (Text + base64 Images) để AI đề xuất chuyên ngành/kỹ năng
  Future<Map<String, dynamic>> analyzeSceneAndSuggestSkills({
    required ChiTietMoTaHienTruongModel moTa,
    required List<LuuAnhModel> danhSachAnhBase64,
  }) async {
    try {
      List<Part> parts = [];

      String textContext =
          '''
      Bạn là Chuyên gia Cấp cứu Y tế Khẩn cấp AI.
      Dựa vào thông tin hiện trường sau:
      - Mô tả chi tiết: ${moTa.ghiChuText ?? 'Không có'}
      - Video: ${moTa.videoUrl ?? 'Không có'}
      - Ghi âm: ${moTa.ghiAmUrl ?? 'Không có'}

      Hãy trích xuất các từ khóa chuyên ngành y tế (vd: tim mạch, gãy xương, ngoại khoa, hồi sức) và kỹ năng cứu hộ (vd: cpr, kn_bang_bo, cố định) cần thiết.
      Trả về kết quả dưới dạng JSON chuẩn:
      {
        "trieuChung": "Mô tả ngắn triệu chứng",
        "mucDoKhanCap": 1 đến 5,
        "chuyenNganhYeuCau": ["tên chuyên ngành 1", "chuyên khoa 2"],
        "kyNangYeuCau": ["kn_bang_bo", "kn_cpr", "cố định"]
      }
      ''';

      parts.add(TextPart(textContext));

      // Đưa ảnh mã hóa Base64 vào Gemini Part
      for (var anh in danhSachAnhBase64) {
        if (anh.anhURL != null && anh.anhURL!.isNotEmpty) {
          try {
            String base64Str = anh.anhURL!.contains(',')
                ? anh.anhURL!.split(',').last
                : anh.anhURL!;
            Uint8List imageBytes = base64Decode(base64Str);
            parts.add(DataPart('image/jpeg', imageBytes));
          } catch (e) {
            debugPrint('Lỗi decode Base64 image (${anh.maAnh}): $e');
          }
        }
      }

      final response = await _model.generateContent([Content.multi(parts)]);

      if (response.text != null && response.text!.isNotEmpty) {
        return jsonDecode(response.text!);
      }
    } catch (e) {
      debugPrint('Lỗi Gemini Multimodal: $e');
    }

    // Fallback nếu có lỗi mạng/API
    return {
      "trieuChung": moTa.ghiChuText.toString(),
      "mucDoKhanCap": 3,
      "chuyenNganhYeuCau": [],
      "kyNangYeuCau": [],
    };
  }
}
