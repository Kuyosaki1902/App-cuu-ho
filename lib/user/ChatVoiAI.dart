import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatVoiAIScreen extends StatefulWidget {
  const ChatVoiAIScreen({super.key});

  @override
  State<ChatVoiAIScreen> createState() => _ChatVoiAIScreenState();
}

class _ChatVoiAIScreenState extends State<ChatVoiAIScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Danh sách lưu trữ tin nhắn kèm theo vai trò ('user' hoặc 'ai')
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cấu hình AI chuyên gia sơ cứu
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: 'AQ.Ab8RN6KM8LO9XJcd9PwHO56grjDmhB4dWyWQP_4KsVBlchhkiw',
      systemInstruction: Content.system(
        'Bạn là chuyên gia y tế sơ cứu khẩn cấp. Chỉ trả lời các câu hỏi về sơ cứu, '
        'xử lý vết thương. Từ chối mọi câu hỏi ngoài lề. '
        //'Trả lời ngắn gọn, từng bước rõ ràng, trình bày theo gạch đầu dòng.',
        'Phân tích trọng điểm vấn đề người cần được hỗ trợ, đưa ra các bước hướng dẫn đúng trọng tâm và ngắn gọn để người sơ cứu dễ dàng thực hiện về vấn đề người cần được hỗ trợ',
      ),
    );
    _chat = _model.startChat();

    // Thêm câu chào mở đầu từ AI
    _messages.add({
      'role': 'ai',
      'text': 'Xin chào, tôi là trợ lý sơ cứu AI 115. Vui lòng mô tả nhanh tình trạng nạn nhân để tôi hướng dẫn xử lý khẩn cấp trong lúc chờ xe cứu thương.'
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMsg = text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userMsg});
      _textController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(userMsg));
      setState(() {
        _messages.add({
          'role': 'ai', 
          'text': response.text ?? 'Xin lỗi, tôi không thể phản hồi lúc này.'
        });
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('👉 CHI TIẾT LỖI GEMINI: $e');
      setState(() {
        _messages.add({
          'role': 'ai', 
          'text': 'Hệ thống: Không thể kết nối tới máy chủ AI lúc này. Vui lòng kiểm tra lại mạng.'
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
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
                  child: Icon(Icons.medical_services, color: Color(0xFF004D40), size: 20),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trợ lý Sơ cứu AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Sẵn sàng hỗ trợ 24/7', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner cảnh báo y tế tối ưu giao diện
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
                    style: TextStyle(color: Color(0xFFC62828), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách tin nhắn chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF004D40),
                          child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF00695C) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
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

          // Hiệu ứng đang tải (Typing indicator)
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF004D40)),
                        ),
                        SizedBox(width: 8),
                        Text('AI đang phân tích và soạn phác đồ...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Khung nhập liệu hiện đại ở dưới cùng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập triệu chứng, vết thương...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: const Color(0xFF004D40),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_textController.text),
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