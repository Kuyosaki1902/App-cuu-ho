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
  Map<String, dynamic>?
  _selectedUserData; // 🟢 Lưu dữ liệu user đang được chọn để hiển thị Card đáy

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
      // Cập nhật lại dữ liệu user đang chọn nếu danh sách thay đổi
      if (_selectedUserId != null) {
        try {
          _selectedUserData = widget.nearbyUsers.firstWhere(
            (u) => u['userId'] == _selectedUserId,
          );
        } catch (_) {
          _selectedUserId = null;
          _selectedUserData = null;
        }
      }
    }
  }

  String _getFirstName(String fullName) {
    fullName = fullName.trim();
    if (fullName.isEmpty) return 'Người dùng';
    List<String> parts = fullName.split(RegExp(r'\s+'));
    return parts.last;
  }

  Future<void> _generateCustomMarkers() async {
    Set<Marker> newMarkers = {};

    if (!widget.isOnline) {
      if (mounted) {
        setState(() {
          _userMarkers = {};
          _selectedUserId = null;
          _selectedUserData = null;
        });
      }
      return;
    }

    Map<String, dynamic>? selectedUser = _selectedUserData;

    Map<String, String> relativeRelationMap = {};
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

    for (var user in widget.nearbyUsers) {
      String userId = (user['userId'] ?? '').toString();
      Uint8List? avatarBytes = user['avatarBytes'];

      Color markerColor = Colors.white;
      String? relationBadge;
      bool isSelectedUser = false;

      if (_selectedUserId != null && selectedUser != null) {
        if (userId == _selectedUserId) {
          markerColor = const ui.Color.fromARGB(255, 214, 39, 39);
          String full = user['hoTen'] ?? 'Người dùng';
          relationBadge = _getFirstName(full);
          isSelectedUser = true;
        } else if (relativeRelationMap.containsKey(userId)) {
          markerColor = const ui.Color.fromARGB(255, 202, 23, 178);
          relationBadge = relativeRelationMap[userId];
        }
      }

      BitmapDescriptor customIcon = await createCustomUserMarker(
        distance: (user['distance'] as num?)?.toDouble() ?? 0.0,
        avatarBytes: avatarBytes,
        primaryColor: markerColor,
        relationBadge: relationBadge,
        isSelectedUser: isSelectedUser,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(userId),
          position: user['location'],
          icon: customIcon,
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: true,
          onTap: () async {
            // 🟢 Bấm lần 1: Chọn ngay lập tức và hiển thị Card thông tin ở đáy
            setState(() {
              _selectedUserId = userId;
              _selectedUserData = user;
            });
            await _generateCustomMarkers();
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

  Future<BitmapDescriptor> createCustomUserMarker({
    required double distance,
    Uint8List? avatarBytes,
    Color primaryColor = Colors.white,
    String? relationBadge,
    bool isSelectedUser = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double avatarRadius = 20.0;
    const double padding = 6.0;
    String distanceText = '${distance.toStringAsFixed(1)}m';

    bool isWhite = primaryColor == Colors.white;
    Color textColor = isWhite ? const Color(0xFF1F2937) : primaryColor;
    Color borderColor = isWhite ? const Color(0xFFCBD5E1) : primaryColor;

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

    TextPainter? badgeTextPainter;
    TextPainter? subBadgeTextPainter;
    double badgeHeight = 15.0;
    double badgeWidth = 0;
    double subBadgeHeight = 15.0;
    double subBadgeWidth = 0;

    double avatarDiameter = avatarRadius * 2;
    double baseContentWidth = distancePainter.width;
    double cardWidth =
        (baseContentWidth + padding * 2) < (avatarDiameter + padding * 2)
        ? (avatarDiameter + padding * 2)
        : (baseContentWidth + padding * 2);

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

      badgeWidth = badgeTextPainter.width + 10;
      if (badgeWidth < 22.0) badgeWidth = 22.0;

      if (isSelectedUser) {
        subBadgeTextPainter = TextPainter(
          text: const TextSpan(
            text: 'Nạn nhân',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        subBadgeWidth = subBadgeTextPainter.width + 10;
        if (subBadgeWidth < 22.0) subBadgeWidth = 22.0;
      }
    }

    double cardHeight =
        avatarDiameter + distancePainter.height + (padding * 2.2);

    double topExtraHeight = subBadgeTextPainter != null
        ? (subBadgeHeight / 2 + 6)
        : 0;
    double bottomExtraHeight = badgeTextPainter != null ? (badgeHeight / 2) : 0;
    double totalCanvasHeight = cardHeight + topExtraHeight + bottomExtraHeight;

    canvas.save();
    canvas.translate(0, topExtraHeight);

    Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    RRect bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cardWidth, cardHeight),
      const Radius.circular(14),
    );
    canvas.drawRRect(bgRRect.shift(const Offset(2, 2)), shadowPaint);

    Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(bgRRect, bgPaint);

    Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isWhite ? 1.5 : 2.5;
    canvas.drawRRect(bgRRect, borderPaint);

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

    double distanceY = padding + avatarDiameter + 2;
    distancePainter.paint(
      canvas,
      Offset((cardWidth - distancePainter.width) / 2, distanceY),
    );

    if (badgeTextPainter != null) {
      double badgeY = cardHeight - (badgeHeight / 2);
      double badgeX = (cardWidth - badgeWidth) / 2;

      Rect badgeRect = Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight);
      RRect badgeRRect = RRect.fromRectAndRadius(
        badgeRect,
        const Radius.circular(6),
      );

      Paint badgeBg = Paint()..color = primaryColor;
      canvas.drawRRect(badgeRRect, badgeBg);

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

    if (subBadgeTextPainter != null) {
      double subBadgeY = -(subBadgeHeight / 2);
      double subBadgeX = (cardWidth - subBadgeWidth) / 2;

      Rect subBadgeRect = Rect.fromLTWH(
        subBadgeX,
        subBadgeY,
        subBadgeWidth,
        subBadgeHeight,
      );
      RRect subBadgeRRect = RRect.fromRectAndRadius(
        subBadgeRect,
        const Radius.circular(6),
      );

      Paint subBadgeBg = Paint()..color = primaryColor;
      canvas.drawRRect(subBadgeRRect, subBadgeBg);

      Paint subBadgeBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(subBadgeRRect, subBadgeBorder);

      subBadgeTextPainter.paint(
        canvas,
        Offset(
          subBadgeX + (subBadgeWidth - subBadgeTextPainter.width) / 2,
          subBadgeY + (subBadgeHeight - subBadgeTextPainter.height) / 2,
        ),
      );
    }

    canvas.restore();

    final ui.Image renderedImage = await pictureRecorder.endRecording().toImage(
      cardWidth.toInt() + 20,
      totalCanvasHeight.toInt() + 20,
    );
    final ByteData? byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // 🟢 Hàm gọi mở modal chi tiết đầy đủ (dùng khi bấm nút "Xem chi tiết" trên Card ở đáy)
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
                                    '${nt['hoTen']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Mối quan hệ: ${nt['moiQuanHe'] ?? 'Chưa cập nhật'}',
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
                    if (!coNguoiThan) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Người dùng này không có người thân để liên hệ!',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
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

          // 🟢 Bấm ra ngoài bản đồ -> Hủy chọn, ẩn Card đáy và đưa marker về màu trắng
          onTap: (_) async {
            if (_selectedUserId != null) {
              setState(() {
                _selectedUserId = null;
                _selectedUserData = null;
              });
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

        // 🟢 2. THẺ TÓM TẮT (BOTTOM CARD) NỔI LÊN NGAY KHI BẤM CHỌN MỤC TIÊU LẦN 1
        if (_selectedUserId != null && _selectedUserData != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedUserData!['hoTen'] ?? 'Nạn nhân',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Nút đóng card
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () async {
                          setState(() {
                            _selectedUserId = null;
                            _selectedUserData = null;
                          });
                          await _generateCustomMarkers();
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.social_distance,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Khoảng cách: ${_selectedUserData!['distance']?.toStringAsFixed(1) ?? '0'}m',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Địa chỉ: ${_selectedUserData!['diaChi'] ?? 'Chưa cập nhật'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Nút thao tác nhanh
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            _showUserInfoModal(context, _selectedUserData!);
                          },
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Xem thông tin người thân'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorCHV.tiep_nhan_yeu_cau,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            List<dynamic> listNT =
                                _selectedUserData!['danhSachNguoiThan'] ?? [];
                            if (listNT.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Người dùng này không có người thân để liên hệ!',
                                  ),
                                ),
                              );
                              return;
                            }
                            widget.onCallAllRelatives(
                              _selectedUserData!,
                              listNT,
                            );
                          },
                          icon: const Icon(
                            Icons.phone_forwarded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Thông báo khẩn cấp người thân',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
