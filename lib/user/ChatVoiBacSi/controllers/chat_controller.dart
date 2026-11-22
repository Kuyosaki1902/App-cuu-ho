// lib/user/ChatVoiBacSi/controllers/chat_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/chitiettinnhanmodel.dart';

class ChatController {
  final String maPhongChat; // maYeuCau
  final String maNguoiCuuHo; // không còn dùng (chat nhóm)
  String currentUserId;
  final double victimLat;
  final double victimLng;

  final TextEditingController msgController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FirebaseService _fbService = FirebaseService();

  bool _disposed = false;

  final ValueNotifier<String> addressNotifier = ValueNotifier(
    'Đang tải địa điểm hẹn...',
  );

  /// Có giá trị = màn hình hiện thông báo lỗi ngắn (gửi tin nhắn thất bại...)
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  /// Tăng lên mỗi khi tải xong thông tin người gửi -> giao diện vẽ lại tên/avatar
  final ValueNotifier<int> senderInfoVersion = ValueNotifier(0);

  final Map<String, Map<String, String>> userCache = {};
  final Set<String> _senderLoading = {};
  static const Map<String, String> _defaultSender = {
    'name': 'Thành viên',
    'avatar': '',
  };

  /// Hoàn tất khi đã biết currentUserId (màn hình chờ trước khi vẽ tin nhắn,
  /// tránh vẽ tin của mình thành tin của người khác)
  late final Future<void> ready;

  /// Tạo MỘT lần (không tạo lại mỗi lần build)
  late final Stream<List<ChiTietTinNhanModel>> messagesStream;

  ChatController({
    required this.maPhongChat,
    required this.maNguoiCuuHo,
    required this.victimLat,
    required this.victimLng,
    String? currentUserId, // nếu màn hình gọi đã biết thì truyền vào
  }) : currentUserId = currentUserId ?? '' {
    ready = _initCurrentUserId();
    messagesStream = _fbService.streamDanhSachTinNhan(maPhongChat);
    _loadAddress();
  }

  Future<void> _initCurrentUserId() async {
    if (currentUserId.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString('maNguoiDung_daLuu') ?? '';
    } catch (e) {
      debugPrint('Lỗi đọc mã người dùng: $e');
    }
  }

  Future<void> _loadAddress() async {
    try {
      final addr = await _fbService
          .getAddressFromLatLng(victimLat, victimLng)
          .timeout(const Duration(seconds: 10));
      if (!_disposed) addressNotifier.value = addr;
    } catch (_) {
      if (!_disposed) {
        addressNotifier.value =
            'Tọa độ: ${victimLat.toStringAsFixed(5)}, ${victimLng.toStringAsFixed(5)}';
      }
    }
  }

  // ===========================================================================
  // THÔNG TIN NGƯỜI GỬI (đọc đồng bộ từ cache, tải nền, không nhấp nháy)
  // ===========================================================================
  Map<String, String> senderInfoOf(String userId) =>
      userCache[userId] ?? _defaultSender;

  void prefetchSenders(Iterable<String> userIds) {
    for (final id in userIds.toSet()) {
      if (id.isEmpty || userCache.containsKey(id) || _senderLoading.contains(id)) {
        continue;
      }
      _senderLoading.add(id);
      _fbService
          .getUserInfoForChat(id)
          .then((info) {
            userCache[id] = info;
            _senderLoading.remove(id);
            if (!_disposed) senderInfoVersion.value++;
          })
          .catchError((e) {
            _senderLoading.remove(id); // lỗi tạm thời -> cho phép thử lại lần sau
            debugPrint('Lỗi tải thông tin người gửi $id: $e');
          });
    }
  }

  // Giữ lại để tương thích nơi khác (nếu có)
  Future<Map<String, String>> getSenderInfo(String userId) async {
    final cached = userCache[userId];
    if (cached != null) return cached;
    final info = await _fbService.getUserInfoForChat(userId);
    userCache[userId] = info;
    return info;
  }

  // ===========================================================================
  // TIN NHẮN
  // ===========================================================================
  int _lastMessageCount = -1;
  bool _forceScroll = false;

  /// Màn hình gọi mỗi khi có danh sách tin nhắn mới
  void onMessagesChanged(List<ChiTietTinNhanModel> messages) {
    prefetchSenders(messages.map((m) => m.maNguoiGui));

    if (messages.length == _lastMessageCount) return; // không có tin mới -> không cuộn
    final bool isFirstLoad = _lastMessageCount == -1;
    _lastMessageCount = messages.length;

    final bool force = _forceScroll || isFirstLoad;
    _forceScroll = false;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scrollToBottom(animate: !isFirstLoad, onlyIfNearBottom: !force),
    );
  }

  /// [onlyIfNearBottom] = true: chỉ cuộn khi người dùng đang ở gần cuối,
  /// để không giật màn hình khi họ đang đọc tin cũ.
  void scrollToBottom({bool animate = true, bool onlyIfNearBottom = false}) {
    if (_disposed || !scrollController.hasClients) return;
    final pos = scrollController.position;
    if (onlyIfNearBottom && pos.maxScrollExtent - pos.pixels > 250) return;

    if (animate) {
      scrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(pos.maxScrollExtent);
    }
  }

  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;

    if (currentUserId.isEmpty) await _initCurrentUserId();
    if (currentUserId.isEmpty) {
      // Trước đây vẫn gửi tin với người gửi rỗng
      errorNotifier.value = 'Không xác định được tài khoản. Vui lòng đăng nhập lại.';
      return;
    }

    msgController.clear(); // xóa ngay -> bấm gửi 2 lần cũng chỉ gửi 1 tin
    _forceScroll = true; // tin của mình thì luôn cuộn xuống cuối

    final tinNhan = ChiTietTinNhanModel(
      maTinNhan: '',
      maPhongChat: maPhongChat,
      maNguoiGui: currentUserId,
      noiDung: text,
      loaiTinNhan: 'text',
      thoiGianGui: DateTime.now(),
    );

    // Không await: khi mất mạng Firestore giữ lệnh ghi cho tới khi có mạng;
    // tin nhắn vẫn hiện ngay nhờ dữ liệu cục bộ.
    _fbService.guiTinNhanMoi(maPhongChat, tinNhan).catchError((e) {
      debugPrint('Lỗi gửi tin nhắn: $e');
      if (!_disposed) errorNotifier.value = 'Gửi tin nhắn thất bại. Vui lòng thử lại.';
    });
  }

  String formatTime(DateTime time) {
    String formatted = DateFormat('hh:mm a').format(time);
    return formatted.replaceAll('AM', 'SA').replaceAll('PM', 'CH');
  }

  void dispose() {
    _disposed = true;
    msgController.dispose();
    scrollController.dispose();
    addressNotifier.dispose();
    errorNotifier.dispose();
    senderInfoVersion.dispose();
  }
}
