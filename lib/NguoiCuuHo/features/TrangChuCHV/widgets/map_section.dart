import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatefulWidget {
  final LatLng? currentPosition;
  final bool isLoadingLocation;
  final bool isOnline;
  final List<Map<String, dynamic>> nearbyUsers;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback RefreshLocation;
  final Function(Map<String, dynamic> user, List<dynamic> danhSachNguoiThan)
  onCallAllRelatives;

  const MapSection({
    super.key,
    required this.currentPosition,
    required this.isLoadingLocation,
    required this.onMapCreated,
    required this.RefreshLocation,
    required this.isOnline,
    required this.onCallAllRelatives,
    this.nearbyUsers = const [],
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  Set<Marker> _userMarkers = {};
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _generateCustomMarkers();
  }

  @override
  void didUpdateWidget(covariant MapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nearbyUsers != widget.nearbyUsers) {
      _generateCustomMarkers();
    }
  }

  // 🟢 1. TẠO MARKER & TÔ MÀU (ĐỎ CHO NGƯỜI CHÍNH, CAM CHO DANH SÁCH NGƯỜI THÂN)
  Future<void> _generateCustomMarkers() async {
    Set<Marker> newMarkers = {};

    // 🟢 Nếu đang Offline -> Xóa toàn bộ marker người dùng xung quanh
    if (!widget.isOnline) {
      if (mounted) {
        setState(() {
          _userMarkers = {};
          _selectedUserId = null;
        });
      }
      return;
    }

    // 1. Tìm object người dùng chính đang được chọn
    Map<String, dynamic>? selectedUser;
    if (_selectedUserId != null) {
      try {
        selectedUser = widget.nearbyUsers.firstWhere(
          (u) => u['userId'] == _selectedUserId,
        );
      } catch (_) {
        selectedUser = null;
      }
    }

    // 2. Trích xuất danh sách ID người thân của người dùng chính
    Map<String, String> relativeRelationMap =
        {}; // Key: maNguoiThan, Value: moiQuanHe
    if (selectedUser != null) {
      List<dynamic> listNT = selectedUser['danhSachNguoiThan'] ?? [];
      for (var nt in listNT) {
        if (nt is Map) {
          String ntId = (nt['maNguoiThan'] ?? '').toString();
          if (ntId.isNotEmpty) {
            relativeRelationMap[ntId] = (nt['moiQuanHe'] ?? 'Thân').toString();
          }
        }
      }
    }

    // 3. Duyệt toàn bộ danh sách người dùng xung quanh để gán màu Marker
    for (var user in widget.nearbyUsers) {
      String userId = (user['userId'] ?? '').toString();
      Uint8List? avatarBytes = user['avatarBytes'];

      Color markerColor = Colors.white; // Mặc định màu trắng
      String? relationBadge;

      if (_selectedUserId != null && selectedUser != null) {
        if (userId == _selectedUserId) {
          // 🔴 NGƯỜI DÙNG CHÍNH ĐANG CHỌN -> HIỂN THỊ MÀU ĐỎ
          markerColor = const ui.Color.fromARGB(255, 214, 39, 39);
          relationBadge = 'Chính';
        } else if (relativeRelationMap.containsKey(userId)) {
          // 🟠 TẤT CẢ NGƯỜI THÂN TRONG DANH SÁCH -> HIỂN THỊ CÙNG 1 MÀU CAM CHUNGS
          markerColor = const ui.Color.fromARGB(255, 202, 23, 178);
          relationBadge = relativeRelationMap[userId];
        }
      }

      BitmapDescriptor customIcon = await createCustomUserMarker(
        distance: (user['distance'] as num?)?.toDouble() ?? 0.0,
        avatarBytes: avatarBytes,
        primaryColor: markerColor,
        relationBadge: relationBadge,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(userId),
          position: user['location'],
          icon: customIcon,
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: true,
          onTap: () async {
            await _handleMarkerTap(userId, user);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _userMarkers = newMarkers;
      });
    }
  }

  // 🟢 2. XỬ LÝ SỰ KIỆN TAP BẤM MARKER BẤT ĐỒNG BỘ
  Future<void> _handleMarkerTap(
    String userId,
    Map<String, dynamic> user,
  ) async {
    if (_selectedUserId == userId) {
      // Nếu bấm lần 2 vào chính người dùng đang chọn -> Mở Modal thông tin
      _showUserInfoModal(context, user);
    } else {
      // Bấm chọn người dùng mới -> Đổi ID và re-render Marker ngay lập tức
      _selectedUserId = userId;
      await _generateCustomMarkers();
    }
  }

  void _drawDefaultIcon(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    TextPainter iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontSize: radius * 1.1,
          fontFamily: Icons.person.fontFamily,
          color: color == Colors.white ? const Color(0xFF0284C7) : color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        center.dx - (iconPainter.width / 2),
        center.dy - (iconPainter.height / 2),
      ),
    );
  }

  // 🟢 VẼ CANVAS MARKER VỚI BADGE MỐI QUAN HỆ ĐẶT ĐÈ LÊN VIỀN ĐÁY (BOTTOM-CENTER BORDER)
  Future<BitmapDescriptor> createCustomUserMarker({
    required double distance,
    Uint8List? avatarBytes,
    Color primaryColor = Colors.white,
    String? relationBadge,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double avatarRadius = 20.0;
    const double padding = 6.0;
    String distanceText = '${distance.toStringAsFixed(1)}m';

    bool isWhite = primaryColor == Colors.white;
    Color textColor = isWhite ? const Color(0xFF1F2937) : primaryColor;
    Color borderColor = isWhite ? const Color(0xFFCBD5E1) : primaryColor;

    // 1. Chuẩn bị Text Khoảng cách
    TextPainter distancePainter = TextPainter(
      text: TextSpan(
        text: distanceText,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 2. Chuẩn bị Text Nhãn Mối quan hệ
    TextPainter? badgeTextPainter;
    double badgeHeight = 0;
    double badgeWidth = 0;

    if (relationBadge != null && relationBadge.isNotEmpty) {
      badgeTextPainter = TextPainter(
        text: TextSpan(
          text: relationBadge,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      badgeHeight = 15.0;
      badgeWidth = badgeTextPainter.width + 10;
      if (badgeWidth < 22.0) badgeWidth = 22.0;
    }

    double avatarDiameter = avatarRadius * 2;

    // Tính bề rộng Card
    double maxContentWidth = distancePainter.width;
    if (badgeWidth > maxContentWidth) maxContentWidth = badgeWidth;

    double cardWidth =
        (maxContentWidth + padding * 2) < (avatarDiameter + padding * 2)
        ? (avatarDiameter + padding * 2)
        : (maxContentWidth + padding * 2);

    // Tính chiều cao chuẩn của Card
    double cardHeight =
        avatarDiameter + distancePainter.height + (padding * 2.2);

    // 🟢 Tổng chiều cao Canvas tính thêm một nửa chiều cao Badge lấn ra ngoài viền đáy
    double totalCanvasHeight =
        cardHeight + (badgeHeight > 0 ? (badgeHeight / 2) : 0);

    // 3. Vẽ bóng Card
    Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    RRect bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cardWidth, cardHeight),
      const Radius.circular(14),
    );
    canvas.drawRRect(bgRRect.shift(const Offset(2, 2)), shadowPaint);

    // 4. Vẽ nền Card
    Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(bgRRect, bgPaint);

    // 5. Vẽ viền Card
    Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isWhite ? 1.5 : 2.5;
    canvas.drawRRect(bgRRect, borderPaint);

    // 6. Vẽ Avatar
    Offset avatarCenter = Offset(cardWidth / 2, padding + avatarRadius);
    Paint avatarBgPaint = Paint()
      ..color = isWhite
          ? const Color(0xFFF1F5F9)
          : primaryColor.withOpacity(0.15);
    canvas.drawCircle(avatarCenter, avatarRadius, avatarBgPaint);

    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      try {
        ui.Codec codec = await ui.instantiateImageCodec(avatarBytes);
        ui.FrameInfo fi = await codec.getNextFrame();
        ui.Image image = fi.image;

        canvas.save();
        Path clipPath = Path()
          ..addOval(
            Rect.fromCircle(center: avatarCenter, radius: avatarRadius - 1.5),
          );
        canvas.clipPath(clipPath);

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCircle(center: avatarCenter, radius: avatarRadius - 1.5),
          Paint(),
        );
        canvas.restore();
      } catch (_) {
        _drawDefaultIcon(canvas, avatarCenter, avatarRadius, primaryColor);
      }
    } else {
      _drawDefaultIcon(canvas, avatarCenter, avatarRadius, primaryColor);
    }

    // 7. VẼ ICON (i) THÔNG TIN Ở GÓC TRÊN-PHẢI BORDER AVATAR
    double iconOffset = avatarRadius * 0.707;
    Offset infoBtnCenter = Offset(
      avatarCenter.dx + iconOffset,
      avatarCenter.dy - iconOffset,
    );

    const double infoRadius = 7.0;

    Paint infoBgPaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawCircle(infoBtnCenter, infoRadius, infoBgPaint);

    Paint infoBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(infoBtnCenter, infoRadius, infoBorderPaint);

    TextPainter infoTextPainter = TextPainter(
      text: const TextSpan(
        text: 'i',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    infoTextPainter.paint(
      canvas,
      Offset(
        infoBtnCenter.dx - (infoTextPainter.width / 2),
        infoBtnCenter.dy - (infoTextPainter.height / 2),
      ),
    );

    // 8. Vẽ Khoảng cách
    double distanceY = padding + avatarDiameter + 2;
    distancePainter.paint(
      canvas,
      Offset((cardWidth - distancePainter.width) / 2, distanceY),
    );

    // 🟢 9. VẼ BADGE MỐI QUAN HỆ ĐẶT ĐÈ CHÍNH GIỮA ĐƯỜNG VIỀN ĐÁY (BOTTOM-CENTER BORDER)
    if (badgeTextPainter != null) {
      // Đặt tâm Y của Badge trùng với đường viền đáy (cardHeight)
      double badgeY = cardHeight - (badgeHeight / 2);
      double badgeX = (cardWidth - badgeWidth) / 2;

      Rect badgeRect = Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight);
      RRect badgeRRect = RRect.fromRectAndRadius(
        badgeRect,
        const Radius.circular(6),
      );

      // Nền Badge
      Paint badgeBg = Paint()..color = primaryColor;
      canvas.drawRRect(badgeRRect, badgeBg);

      // Viền trắng bao quanh Badge để phân tách đẹp mắt với đường viền Marker
      Paint badgeBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(badgeRRect, badgeBorder);

      badgeTextPainter.paint(
        canvas,
        Offset(
          badgeX + (badgeWidth - badgeTextPainter.width) / 2,
          badgeY + (badgeHeight - badgeTextPainter.height) / 2,
        ),
      );
    }

    final ui.Image renderedImage = await pictureRecorder.endRecording().toImage(
      cardWidth.toInt() + 10,
      totalCanvasHeight.toInt() + 10,
    );
    final ByteData? byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // 🟢 4. MODAL HIỂN THỊ THÔNG TIN CHI TIẾT NGƯỜI DÙNG
  // 🟢 4. MODAL HIỂN THỊ THÔNG TIN CHI TIẾT NGƯỜI DÙNG
  void _showUserInfoModal(BuildContext context, Map<String, dynamic> user) {
    List<dynamic> danhSachNguoiThan = user['danhSachNguoiThan'] ?? [];
    bool coNguoiThan = danhSachNguoiThan.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    radius: 26,
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF0284C7),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['hoTen'] ?? 'Người dùng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Trong phạm vi: ${user['distance']?.toStringAsFixed(1)}m',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SĐT nạn nhân: ${user['soDienThoai'] ?? 'Chưa cập nhật'}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Địa chỉ: ${user['diaChi'] ?? 'Chưa cập nhật'}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Danh sách người thân liên hệ khẩn cấp:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (coNguoiThan)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: danhSachNguoiThan.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      var nt = danhSachNguoiThan[index];
                      // 🟢 ĐÃ XÓA NÚT GỌI RIÊNG LẺ Ở TỪNG DÒNG NGƯỜI THÂN
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.family_restroom,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${nt['hoTen']} (${nt['moiQuanHe']})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'SĐT: ${nt['soDienThoai']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Người dùng chưa liên kết người thân',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // 🟢 NÚT LIÊN HỆ GỌI CHO TOÀN BỘ NGƯỜI THÂN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorCHV.tiep_nhan_yeu_cau,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    debugPrint(
                      '🟢 ĐÃ BẤM VÀO NÚT LIÊN HỆ TRÊN MODAL!',
                    ); // Thêm dòng này để test
                    debugPrint(
                      '🟢 Số lượng người thân hiện tại: ${danhSachNguoiThan.length}',
                    );
                    if (!coNguoiThan) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Người dùng này không có người thân để liên hệ!',
                          ),
                        ),
                      );
                      return; // 🔴 Nó bị dừng ở đây nếu không có người thân!
                    }
                    // Đóng modal chi tiết
                    Navigator.pop(context);
                    // Gọi callback truyền ra màn hình chính / controller xử lý
                    widget.onCallAllRelatives(user, danhSachNguoiThan);
                  },
                  icon: const Icon(Icons.phone_forwarded, color: Colors.white),
                  label: const Text(
                    'Liên hệ với toàn bộ người thân',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFC80815)),
            const SizedBox(height: 12),
            Text(
              widget.isLoadingLocation
                  ? 'Đang định vị vị trí thực tế...'
                  : 'Chưa thể lấy vị trí. Vui lòng bật GPS và thử lại.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          key: ValueKey(
            '${widget.currentPosition!.latitude}_${widget.currentPosition!.longitude}',
          ),
          initialCameraPosition: CameraPosition(
            target: widget.currentPosition!,
            zoom: 18.2,
          ),
          onMapCreated: widget.onMapCreated,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _userMarkers,

          // 🟢 Bấm ra ngoài bản đồ -> Hủy chọn & Đưa marker về màu trắng ngay lập tức
          onTap: (_) async {
            if (_selectedUserId != null) {
              _selectedUserId = null;
              await _generateCustomMarkers();
            }
          },

          circles: {
            Circle(
              circleId: const CircleId('circle_100m_boundary'),
              center: widget.currentPosition!,
              radius: 100.0,
              fillColor:
                  (widget.isOnline
                          ? ColorCHV.tiep_nhan_yeu_cau
                          : ColorCHV.ngung_tiep_nhan_yeu_cau)
                      .withOpacity(0.18),
              strokeColor:
                  (widget.isOnline
                          ? ColorCHV.tiep_nhan_yeu_cau
                          : ColorCHV.ngung_tiep_nhan_yeu_cau)
                      .withOpacity(0.6),
              strokeWidth: 2,
              zIndex: 1,
            ),
            Circle(
              circleId: const CircleId('center_dot_white_border'),
              center: widget.currentPosition!,
              radius: 1.2,
              fillColor: Colors.white,
              strokeColor: const Color(0xFFD1D5DB),
              strokeWidth: 1,
              zIndex: 2,
            ),
            Circle(
              circleId: const CircleId('center_dot_my_location'),
              center: widget.currentPosition!,
              radius: 0.8,
              fillColor: widget.isOnline
                  ? ColorCHV.tiep_nhan_yeu_cau
                  : ColorCHV.ngung_tiep_nhan_yeu_cau,
              strokeColor: Colors.transparent,
              strokeWidth: 0,
              zIndex: 3,
            ),
          },
        ),

        // Nút cập nhật vị trí
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.my_location,
                color: widget.isOnline
                    ? ColorCHV.tiep_nhan_yeu_cau
                    : ColorCHV.ngung_tiep_nhan_yeu_cau,
              ),
              onPressed: widget.RefreshLocation,
            ),
          ),
        ),
      ],
    );
  }
}
