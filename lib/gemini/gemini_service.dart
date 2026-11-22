// lib/gemini/gemini_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cuhokhancap/user/Models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/Models/luuanhmodel.dart';
import 'package:cuhokhancap/user/Models/videohuongdanmodel.dart'
    show boDauTiengViet;

class GeminiService {
  // ⚠️ KHÔNG ghi API key thẳng vào code. Truyền khi chạy / build:
  //   flutter run --dart-define=GEMINI_API_KEY=xxxx
  // (Về lâu dài nên chuyển lời gọi Gemini sang Cloud Function / Firebase AI Logic
  //  để key không nằm trong app.)
  static const String _apiKey =
      "AQ.Ab8RN6LncuJURjcB0ABiGKJTWkJc24Z--0eybY_ib0HTwKrGUw";

  // Model nhẹ đặt trước, các bản khác làm dự phòng.
  // Tên model không tồn tại sẽ báo lỗi và tự chuyển sang model kế tiếp.
  static const List<String> candidateModelNames = [
    'gemini-2.5-flash',
    'gemini-3.7-flash',
    'gemini-3.8-flash',
  ];

  // Giới hạn để mạng yếu vẫn nhanh
  static const int _maxImages = 2;
  static const int _maxImageBytes = 1500000; // bỏ qua ảnh > ~1.5MB
  static const Duration _perModelTimeout = Duration(seconds: 6);
  static const Duration _totalBudget = Duration(seconds: 18);

  late final List<GenerativeModel> _models;

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  GeminiService._internal() {
    final config = GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.2,
      maxOutputTokens: 400, // JSON ngắn -> nhanh hơn
    );

    _models = candidateModelNames
        .map(
          (name) => GenerativeModel(
            model: name,
            apiKey: _apiKey,
            generationConfig: config,
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Chuyển mô tả hiện trường (Map hoặc String) thành văn bản gọn cho prompt
  // ---------------------------------------------------------------------------
  String _describeScene(ChiTietMoTaHienTruongModel moTa) {
    final g = moTa.ghiChuText;
    if (g is Map) {
      final tc = g['trieuChung'];
      final trieuChung = tc is List ? tc.join(', ') : (tc?.toString() ?? '');
      final chiTiet = (g['moTaChiTiet'] ?? '').toString();
      return 'Triệu chứng: ${trieuChung.isEmpty ? 'không rõ' : trieuChung}\n'
          'Mô tả chi tiết: ${chiTiet.isEmpty ? 'không có' : chiTiet}';
    }
    final text = g?.toString() ?? '';
    return 'Mô tả: ${text.isEmpty ? 'không có' : text}';
  }

  // "data:image/png;base64,...." -> image/png ; mặc định image/jpeg
  String _mimeOf(String raw) {
    final m = RegExp(r'^data:(image/[a-zA-Z0-9.+-]+);base64,').firstMatch(raw);
    return m?.group(1) ?? 'image/jpeg';
  }

  List<Part> _buildParts({
    required ChiTietMoTaHienTruongModel moTa,
    required List<LuuAnhModel> danhSachAnhBase64,
    Map<String, String>? kyNangHopLe,
    List<String>? chuyenNganhHopLe,
  }) {
    final bool coDanhMucKyNang = kyNangHopLe != null && kyNangHopLe.isNotEmpty;
    final bool coDanhMucCN =
        chuyenNganhHopLe != null && chuyenNganhHopLe.isNotEmpty;

    final kyNangRule = coDanhMucKyNang
        ? 'CHỈ được chọn mã trong danh sách (mã - tên):\n'
              '${kyNangHopLe.entries.map((e) => '${e.key} - ${e.value}').join('\n')}'
        : 'Dùng mã dạng kn_cpr, kn_bang_bo, kn_co_dinh.';
    final chuyenNganhRule = coDanhMucCN
        ? 'CHỈ được chọn tên trong danh sách:\n${chuyenNganhHopLe.join('\n')}'
        : 'Ví dụ: tim mạch, ngoại khoa, hồi sức.';

    final String textContext =
        '''
Bạn là chuyên gia cấp cứu y tế khẩn cấp. Dựa vào thông tin hiện trường (và ảnh đính kèm nếu có):
${_describeScene(moTa)}

Hãy chọn các chuyên ngành và kỹ năng cứu hộ CẦN THIẾT NHẤT cho ca này (tối đa 3 mục mỗi loại).

Chuyên ngành. $chuyenNganhRule

Kỹ năng. $kyNangRule

Trả về JSON đúng dạng:
{
  "trieuChung": "mô tả ngắn triệu chứng",
  "chuyenNganhYeuCau": ["..."],
  "kyNangYeuCau": ["..."]
}
Nếu không có mục nào phù hợp thì trả về mảng rỗng.
''';

    final List<Part> parts = [TextPart(textContext)];

    int added = 0;
    for (final anh in danhSachAnhBase64) {
      if (added >= _maxImages) break;
      final raw = anh.anhURL;
      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final cleaned = raw.trim();
        final String base64Str = cleaned.contains(',')
            ? cleaned.split(',').last.trim()
            : cleaned;
        final Uint8List bytes = base64Decode(base64Str);
        if (bytes.isEmpty) continue;
        if (bytes.length > _maxImageBytes) {
          debugPrint('Bỏ qua ảnh ${anh.maAnh}: ${bytes.length} bytes quá lớn');
          continue;
        }
        parts.add(DataPart(_mimeOf(cleaned), bytes));
        added++;
      } catch (e) {
        debugPrint('Lỗi decode Base64 image (${anh.maAnh}): $e');
      }
    }
    return parts;
  }

  // Làm sạch kết quả: ép về List<String>, và nếu có danh mục thì chỉ giữ giá trị hợp lệ
  List<String> _cleanList(dynamic raw, {Iterable<String>? allowed}) {
    if (raw is! List) return <String>[];
    final values = raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (allowed == null || allowed.isEmpty) return values;

    final byKey = {for (final a in allowed) boDauTiengViet(a).trim(): a};
    final out = <String>[];
    for (final v in values) {
      final match = byKey[boDauTiengViet(v).trim()];
      if (match != null && !out.contains(match)) out.add(match);
    }
    return out;
  }

  Future<Map<String, dynamic>> analyzeSceneAndSuggestSkills({
    required ChiTietMoTaHienTruongModel moTa,
    required List<LuuAnhModel> danhSachAnhBase64,
    Map<String, String>? kyNangHopLe, // mã -> tên
    List<String>? chuyenNganhHopLe,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint(
        '⚠️ Chưa có GEMINI_API_KEY (chạy với --dart-define=GEMINI_API_KEY=...). '
        'Bỏ qua Gemini, dùng kết quả cục bộ.',
      );
    } else {
      final parts = _buildParts(
        moTa: moTa,
        danhSachAnhBase64: danhSachAnhBase64,
        kyNangHopLe: kyNangHopLe,
        chuyenNganhHopLe: chuyenNganhHopLe,
      );
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < _models.length; i++) {
        if (stopwatch.elapsed >= _totalBudget) break;
        final modelName = candidateModelNames[i];

        try {
          final response = await _models[i]
              .generateContent([Content.multi(parts)])
              .timeout(_perModelTimeout);

          final rawText = response.text;
          if (rawText == null || rawText.trim().isEmpty) continue;

          final decoded = jsonDecode(rawText);
          if (decoded is Map) {
            return {
              'trieuChung': (decoded['trieuChung'] ?? '').toString(),
              'chuyenNganhYeuCau': _cleanList(
                decoded['chuyenNganhYeuCau'],
                allowed: chuyenNganhHopLe,
              ),
              'kyNangYeuCau': _cleanList(
                decoded['kyNangYeuCau'],
                allowed: kyNangHopLe?.keys,
              ),
            };
          }
        } on TimeoutException {
          debugPrint(
            '⏱️ Quá ${_perModelTimeout.inSeconds}s với $modelName, đổi model...',
          );
        } catch (e) {
          debugPrint('⚠️ Lỗi $modelName: $e');
        }
      }
    }

    return {
      'trieuChung': _describeScene(moTa),
      'chuyenNganhYeuCau': <String>[],
      'kyNangYeuCau': <String>[],
    };
  }
}
