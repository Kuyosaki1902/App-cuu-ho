import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum _LoaiLoi { modelKhongKhaDung, quota, cauHinh, mang }

class _LoiApi implements Exception {
  final int status;
  final String noiDung;
  _LoiApi(this.status, this.noiDung);
  @override
  String toString() => 'HTTP $status: $noiDung';
}

class ChatVoiAIScreen extends StatefulWidget {
  const ChatVoiAIScreen({super.key});

  @override
  State<ChatVoiAIScreen> createState() => _ChatVoiAIScreenState();
}

class _ChatVoiAIScreenState extends State<ChatVoiAIScreen> {
  
  // (Hoặc dán tạm vào đây để thử, nhưng KHÔNG commit lên GitHub)
  static const String _apiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'AQ.Ab8RN6KDtJ5_KnZJ0FpVq9JsfJ0RChSwxVpIz7rDpzHmyuIuAQ',
);

  // Danh sách model theo thứ tự ưu tiên. Model đầu lỗi/quá tải sẽ tự chuyển
  // sang model kế tiếp.
  static const List<String> _danhSachModel = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-3.5-flash',
  ];

  static const String _heThong =
      'Bạn là chuyên gia y tế sơ cứu khẩn cấp. Chỉ trả lời các câu hỏi về sơ cứu, '
      'xử lý vết thương. Từ chối mọi câu hỏi ngoài lề. '
      'Phân tích trọng điểm vấn đề người cần được hỗ trợ, đưa ra các bước hướng dẫn '
      'đúng trọng tâm và ngắn gọn để người sơ cứu dễ dàng thực hiện. '
      'Nếu tình huống nguy hiểm tính mạng (ngừng thở, mất ý thức, chảy máu không cầm, '
      'đau ngực, nghi đột quỵ...), luôn nhắc gọi cấp cứu 115 ngay ở dòng đầu tiên.';

  int _modelIndex = 0;

  // Lịch sử hội thoại gửi lên API (định dạng Gemini REST)
  final List<Map<String, dynamic>> _lichSu = [];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // role: 'user' | 'ai' | 'error' (error có thêm khóa 'retry' = câu hỏi gốc)
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text':
          'Xin chào, tôi là trợ lý sơ cứu AI cứu hộ. Vui lòng mô tả nhanh tình trạng nạn nhân để tôi hướng dẫn xử lý khẩn cấp trong lúc chờ xe cứu thương.',
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Gọi 1 lần API generateContent (không streaming) với model chỉ định.
  Future<String> _goiApi(String model, String userMsg) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _heThong},
        ],
      },
      'contents': [
        ..._lichSu,
        {
          'role': 'user',
          'parts': [
            {'text': userMsg},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.3},
    });

    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 40));

    if (res.statusCode != 200) {
      throw _LoiApi(res.statusCode, utf8.decode(res.bodyBytes));
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw _LoiApi(0, 'Phản hồi rỗng hoặc bị chặn: ${data['promptFeedback']}');
    }
    final parts = (candidates[0]['content']?['parts'] as List?) ?? [];
    final text = parts
        .where((p) => p['thought'] != true && p['text'] != null)
        .map((p) => p['text'] as String)
        .join();
    if (text.trim().isEmpty) throw _LoiApi(0, 'Phản hồi rỗng');
    return text;
  }

  _LoaiLoi _phanLoai(Object e) {
    if (e is TimeoutException) return _LoaiLoi.mang;
    if (e is _LoiApi) {
      final s = e.noiDung.toLowerCase();
      if (e.status == 401 || e.status == 403) return _LoaiLoi.cauHinh;
      if (e.status == 400 &&
          (s.contains('api key') || s.contains('api_key'))) {
        return _LoaiLoi.cauHinh;
      }
      if (e.status == 404 || e.status == 400) return _LoaiLoi.modelKhongKhaDung;
      if (e.status == 429 || e.status == 503) return _LoaiLoi.quota;
      if (e.status == 0) return _LoaiLoi.modelKhongKhaDung;
    }
    return _LoaiLoi.mang;
  }

  String _thongBaoLoi(_LoaiLoi loai) {
    switch (loai) {
      case _LoaiLoi.cauHinh:
        return 'API key AI chưa đúng, thiếu hoặc bị chặn. Vui lòng kiểm tra lại cấu hình.';
      case _LoaiLoi.quota:
      case _LoaiLoi.modelKhongKhaDung:
        return 'Máy chủ AI đang quá tải hoặc tạm thời không khả dụng. Vui lòng thử lại sau ít phút.';
      case _LoaiLoi.mang:
        return 'Không thể kết nối tới máy chủ AI. Vui lòng kiểm tra lại mạng rồi bấm "Thử lại".';
    }
  }

  /// Loại bỏ ký hiệu markdown thô để hiển thị gọn trong bong bóng chat.
  String _lamSach(String s) {
    return s
        .replaceAll('**', '')
        .replaceAllMapped(
          RegExp(r'^\s*[\*\-]\s+', multiLine: true),
          (_) => '• ',
        )
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .trim();
  }

  Future<void> _sendMessage(String text, {bool laThuLai = false}) async {
    final userMsg = text.trim();
    if (userMsg.isEmpty || _isLoading) return;

    setState(() {
      _messages.removeWhere((m) => m['role'] == 'error');
      if (!laThuLai) _messages.add({'role': 'user', 'text': userMsg});
      _textController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final loi = await _hoiAI(userMsg);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (loi != null) {
        _messages.add({
          'role': 'error',
          'text': _thongBaoLoi(loi),
          'retry': userMsg,
        });
      }
    });
    _scrollToBottom();
  }

  /// Hỏi AI. Trả về null nếu thành công, hoặc loại lỗi cuối cùng.
  Future<_LoaiLoi?> _hoiAI(String userMsg) async {
    if (_apiKey.isEmpty) {
      debugPrint('👉 THIẾU GEMINI_API_KEY (chạy với --dart-define=GEMINI_API_KEY=...)');
      return _LoaiLoi.cauHinh;
    }

    _LoaiLoi? loiCuoi;

    for (int m = _modelIndex; m < _danhSachModel.length; m++) {
      for (int lan = 0; lan < 2; lan++) {
        try {
          final text = await _goiApi(_danhSachModel[m], userMsg);
          _modelIndex = m;
          _lichSu.add({
            'role': 'user',
            'parts': [
              {'text': userMsg},
            ],
          });
          _lichSu.add({
            'role': 'model',
            'parts': [
              {'text': text},
            ],
          });
          if (mounted) {
            setState(() => _messages.add({'role': 'ai', 'text': _lamSach(text)}));
          }
          return null;
        } catch (e) {
          debugPrint('👉 LỖI GEMINI (${_danhSachModel[m]}, lần ${lan + 1}): $e');
          loiCuoi = _phanLoai(e);

          if (loiCuoi == _LoaiLoi.cauHinh) return loiCuoi;
          if (loiCuoi == _LoaiLoi.modelKhongKhaDung ||
              loiCuoi == _LoaiLoi.quota) {
            break; // sang model kế tiếp
          }
          await Future.delayed(Duration(seconds: 1 + lan)); // lỗi mạng: thử lại
        }
      }
      if (loiCuoi == _LoaiLoi.mang) return loiCuoi;
    }
    return loiCuoi ?? _LoaiLoi.mang;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildErrorBubble(Map<String, String> msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text']!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC62828),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nếu khẩn cấp, hãy gọi 115 ngay.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC62828),
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _sendMessage(msg['retry']!, laThuLai: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.medical_services,
                    color: Color(0xFF004D40),
                    size: 20,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý Sơ cứu AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sẵn sàng hỗ trợ 24/7',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFFEBEE),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lưu ý: Hướng dẫn chỉ mang tính sơ cứu tạm thời trong lúc chờ xe cứu thương.',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['role'] == 'error') return _buildErrorBubble(msg);

                final isUser = msg['role'] == 'user';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF004D40),
                          child: Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF00695C)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SelectableText(
                            msg['text']!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 8),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF004D40),
                    child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF004D40),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI đang phân tích và soạn phác đồ...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập triệu chứng, vết thương...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _isLoading
                        ? Colors.grey.shade400
                        : const Color(0xFF004D40),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}