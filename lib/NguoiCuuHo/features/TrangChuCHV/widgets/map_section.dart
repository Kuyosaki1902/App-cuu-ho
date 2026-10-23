import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapSection extends StatefulWidget {
  final LatLng? currentPosition;
  final bool isLoadingLocation;
  final bool isOnline;
  final List<Map<String, dynamic>> nearbyUsers;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback RefreshLocation;

  const MapSection({
    super.key,
    required this.currentPosition,
    required this.isLoadingLocation,
    required this.onMapCreated,
    required this.RefreshLocation,
    required this.isOnline,
    this.nearbyUsers = const [],
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  Set<Marker> _userMarkers = {};
  Set<Polyline> _familyPolylines = {};

  // Bảng màu phân biệt các nhóm người thân khác nhau
  final List<Color> _familyColorPalette = [
    const Color(0xFFF97316), // Cam
    const Color(0xFFA855F7), // Tím
    const Color(0xFF0D9488), // Teal
    const Color(0xFFEC4899), // Hồng
    const Color(0xFF6366F1), // Chàm
  ];

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

  // 🟢 1. THUẬT TOÁN PHÂN NHÓM NGƯỜI THÂN TRONG BÁN KÍNH 10M
  Map<String, dynamic> _processFamilyGroups(List<Map<String, dynamic>> users) {
    int groupCounter = 1;
    Map<String, int> userGroupMap = {};
    Set<Polyline> polylines = {};

    for (int i = 0; i < users.length; i++) {
      String u1Id = users[i]['userId'] ?? '';
      List<dynamic> listNT1 = users[i]['danhSachNguoiThan'] ?? [];

      for (int j = i + 1; j < users.length; j++) {
        String u2Id = users[j]['userId'] ?? '';

        // Kiểm tra xem user 2 có nằm trong danh sách người thân của user 1 không
        bool isRelative = listNT1.any((nt) => nt['maNguoiThan'] == u2Id);

        if (isRelative) {
          int assignedGroup;

          if (userGroupMap.containsKey(u1Id)) {
            assignedGroup = userGroupMap[u1Id]!;
          } else if (userGroupMap.containsKey(u2Id)) {
            assignedGroup = userGroupMap[u2Id]!;
          } else {
            assignedGroup = groupCounter++;
          }

          userGroupMap[u1Id] = assignedGroup;
          userGroupMap[u2Id] = assignedGroup;

          Color groupColor =
              _familyColorPalette[(assignedGroup - 1) %
                  _familyColorPalette.length];

          // Tạo đường nối nét đứt giữa 2 người thân
          if (users[i]['location'] != null && users[j]['location'] != null) {
            polylines.add(
              Polyline(
                polylineId: PolylineId('poly_${u1Id}_$u2Id'),
                points: [users[i]['location'], users[j]['location']],
                color: groupColor.withOpacity(0.8),
                width: 3,
                patterns: [PatternItem.dash(12), PatternItem.gap(6)],
              ),
            );
          }
        }
      }
    }

    return {'userGroupMap': userGroupMap, 'polylines': polylines};
  }

  // 🟢 2. TẠO TẤT CẢ MARKERS VÀ POLYLINES
  Future<void> _generateCustomMarkers() async {
    Set<Marker> newMarkers = {};

    var groupResult = _processFamilyGroups(widget.nearbyUsers);
    Map<String, int> userGroupMap = groupResult['userGroupMap'];
    Set<Polyline> newPolylines = groupResult['polylines'];

    for (var user in widget.nearbyUsers) {
      String userId = user['userId'] ?? '';
      Uint8List? avatarBytes = user['avatarBytes'];

      int? groupId = userGroupMap[userId];
      Color groupColor = groupId != null
          ? _familyColorPalette[(groupId - 1) % _familyColorPalette.length]
          : const Color(0xFF0284C7); // Màu xanh lam mặc định cho user lẻ

      BitmapDescriptor customIcon = await createCustomUserMarker(
        distance: (user['distance'] as num).toDouble(),
        avatarBytes: avatarBytes,
        primaryColor: groupColor,
        groupId: groupId,
      );

      // Lưu lại màu và groupId vào user map để BottomSheet dùng
      user['groupColor'] = groupColor;
      user['groupId'] = groupId;

      newMarkers.add(
        Marker(
          markerId: MarkerId(userId),
          position: user['location'],
          icon: customIcon,
          anchor: const Offset(0.5, 0.5),
          onTap: () {
            _showUserInfoModal(context, user);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _userMarkers = newMarkers;
        _familyPolylines = newPolylines;
      });
    }
  }

  // 🟢 3. HÀM VẼ ICON MẶC ĐỊNH
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
          color: color,
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

  // 🟢 4. HÀM VẼ CUSTOM MARKER CANVAS (CÓ HIỂN THỊ BADGE G1, G2 NẾU CÓ NHÓM)
  Future<BitmapDescriptor> createCustomUserMarker({
    required double distance,
    Uint8List? avatarBytes,
    Color primaryColor = const Color(0xFF0284C7),
    int? groupId,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double avatarRadius = 20.0;
    const double padding = 5.0;
    String distanceText = '${distance.toStringAsFixed(1)}m';

    TextPainter distancePainter = TextPainter(
      text: TextSpan(
        text: distanceText,
        style: TextStyle(
          color: primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double avatarDiameter = avatarRadius * 2;
    double cardWidth =
        (distancePainter.width + padding * 2) < (avatarDiameter + padding * 2)
        ? (avatarDiameter + padding * 2)
        : (distancePainter.width + padding * 2);

    double cardHeight =
        avatarDiameter + distancePainter.height + (padding * 2.5);

    // 1. Vẽ bóng
    Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    RRect bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cardWidth, cardHeight),
      const Radius.circular(14),
    );
    canvas.drawRRect(bgRRect.shift(const Offset(2, 2)), shadowPaint);

    // 2. Vẽ nền trắng
    Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(bgRRect, bgPaint);

    // 3. Vẽ viền NỔI THEO MÀU NHÓM
    Paint borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bgRRect, borderPaint);

    // 4. Vẽ Avatar
    Offset avatarCenter = Offset(cardWidth / 2, padding + avatarRadius);
    Paint avatarBgPaint = Paint()..color = primaryColor.withOpacity(0.15);
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

    // 5. VẼ BADGE NHÓM NGƯỜI THÂN (Ví dụ: G1, G2) NẾU CÓ
    if (groupId != null) {
      Offset badgeCenter = Offset(cardWidth - 2, 2);
      Paint badgeBg = Paint()..color = primaryColor;
      canvas.drawCircle(badgeCenter, 9, badgeBg);

      Paint badgeBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(badgeCenter, 9, badgeBorder);

      TextPainter badgeText = TextPainter(
        text: TextSpan(
          text: 'G$groupId',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      badgeText.paint(
        canvas,
        Offset(
          badgeCenter.dx - badgeText.width / 2,
          badgeCenter.dy - badgeText.height / 2,
        ),
      );
    }

    // 6. Vẽ Khoảng cách
    double distanceY = padding + avatarDiameter + 2;
    distancePainter.paint(
      canvas,
      Offset((cardWidth - distancePainter.width) / 2, distanceY),
    );

    final ui.Image renderedImage = await pictureRecorder.endRecording().toImage(
      cardWidth.toInt() + 6,
      cardHeight.toInt() + 6,
    );
    final ByteData? byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // 🟢 5. BOTTOM SHEET HIỂN THỊ THÔNG TIN USER VÀ NGƯỜI THÂN
  void _showUserInfoModal(BuildContext context, Map<String, dynamic> user) {
    List<dynamic> danhSachNguoiThan = user['danhSachNguoiThan'] ?? [];
    bool coNguoiThan = danhSachNguoiThan.isNotEmpty;
    int? groupId = user['groupId'];
    Color groupColor = user['groupColor'] ?? const Color(0xFF0284C7);

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
              // --- HEADER ---
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: groupColor.withOpacity(0.15),
                    radius: 26,
                    child: Icon(Icons.person, color: groupColor, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user['hoTen'] ?? 'Người dùng',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (groupId != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: groupColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Nhóm G$groupId',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
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

              // --- THÔNG TIN CƠ BẢN NẠN NHÂN ---
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

              // --- THÔNG BÁO NẾU CÓ NGƯỜI THÂN Ở CÙNG TRONG PHẠM VI 10M ---
              if (groupId != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: groupColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_alt, color: groupColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Phát hiện người thân thuộc Nhóm G$groupId cũng đang ở gần trong bán kính 10m!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: groupColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // --- HIỂN THỊ DANH SÁCH NGƯỜI THÂN ---
              const Text(
                'Người thân liên hệ khẩn cấp:',
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
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.phone_forwarded,
                                color: Colors.orange,
                                size: 22,
                              ),
                              onPressed: () async {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: nt['soDienThoai'],
                                );
                                if (await canLaunchUrl(launchUri)) {
                                  await launchUrl(launchUri);
                                }
                              },
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

              // NÚT CHỦ ĐỘNG HỖ TRỢ
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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.support_agent, color: Colors.white),
                  label: const Text(
                    'Chủ động hỗ trợ',
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
            zoom: 20.0,
          ),
          onMapCreated: widget.onMapCreated,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,

          // MARKER VÀ POLYLINES PHÂN NHÓM NGƯỜI THÂN
          markers: _userMarkers,
          polylines: _familyPolylines,

          circles: {
            Circle(
              circleId: const CircleId('circle_10m_boundary'),
              center: widget.currentPosition!,
              radius: 10.0,
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
