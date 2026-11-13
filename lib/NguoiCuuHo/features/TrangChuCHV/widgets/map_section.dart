import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatefulWidget {
  final LatLng? currentPosition;
  final bool isLoadingLocation;
  final bool isOnline;
  final List<Map<String, dynamic>> nearbyUsers;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onRefreshLocation; // đổi tên từ RefreshLocation
  final Function(Map<String, dynamic> user, List<dynamic> danhSachNguoiThan)
  onCallAllRelatives;

  const MapSection({
    super.key,
    required this.currentPosition,
    required this.isLoadingLocation,
    required this.onMapCreated,
    required this.onRefreshLocation,
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
  Map<String, dynamic>? _selectedUserData;

  // Chống chạy chồng: lần vẽ cũ hoàn thành sau không được ghi đè lần mới
  int _markerSeq = 0;
  // Cache icon marker: tránh vẽ lại toàn bộ marker mỗi lần tap / cập nhật
  final Map<String, BitmapDescriptor> _iconCache = {};

  @override
  void initState() {
    super.initState();
    // Cần context (devicePixelRatio) nên chờ khung hình đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generateCustomMarkers();
    });
  }

  double _num(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  @override
  void didUpdateWidget(covariant MapSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool changed =
        oldWidget.isOnline != widget.isOnline ||
        oldWidget.nearbyUsers.length != widget.nearbyUsers.length;

    if (!changed) {
      for (int i = 0; i < widget.nearbyUsers.length; i++) {
        final o = oldWidget.nearbyUsers[i];
        final n = widget.nearbyUsers[i];
        if (o['userId'] != n['userId'] ||
            (_num(o['distance']) - _num(n['distance'])).abs() > 2.0 ||
            o['location'] != n['location']) {
          changed = true;
          break;
        }
      }
    }

    if (changed) {
      // Cập nhật dữ liệu người đang chọn TRƯỚC khi vẽ marker
      if (_selectedUserId != null) {
        final idx = widget.nearbyUsers.indexWhere(
          (u) => u['userId'] == _selectedUserId,
        );
        if (idx >= 0) {
          _selectedUserData = widget.nearbyUsers[idx];
        } else {
          _selectedUserId = null;
          _selectedUserData = null;
        }
      }
      _generateCustomMarkers();
    }
  }

  String _getFirstName(String fullName) {
    fullName = fullName.trim();
    if (fullName.isEmpty) return 'Người dùng';
    final parts = fullName.split(RegExp(r'\s+'));
    return parts.last;
  }

  void _clearSelection() {
    setState(() {
      _selectedUserId = null;
      _selectedUserData = null;
    });
    _generateCustomMarkers();
  }

  Future<void> _generateCustomMarkers() async {
    final int seq = ++_markerSeq;

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
    if (!mounted) return;

    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final Set<Marker> newMarkers = {};
    final Map<String, dynamic>? selectedUser = _selectedUserData;

    final Map<String, String> relativeRelationMap = {};
    if (selectedUser != null) {
      final List<dynamic> listNT = selectedUser['danhSachNguoiThan'] ?? [];
      for (var nt in listNT) {
        if (nt is Map) {
          final ntId = (nt['maNguoiThan'] ?? '').toString();
          if (ntId.isNotEmpty) {
            relativeRelationMap[ntId] = (nt['moiQuanHe'] ?? 'Thân').toString();
          }
        }
      }
    }

    final users = List<Map<String, dynamic>>.from(widget.nearbyUsers);
    for (final user in users) {
      final String userId = (user['userId'] ?? '').toString();
      final Uint8List? avatarBytes = user['avatarBytes'];

      Color markerColor = Colors.white;
      String? relationBadge;
      bool isSelectedUser = false;

      if (_selectedUserId != null && selectedUser != null) {
        if (userId == _selectedUserId) {
          markerColor = const Color.fromARGB(255, 214, 39, 39);
          relationBadge = _getFirstName(
            (user['hoTen'] ?? 'Người dùng').toString(),
          );
          isSelectedUser = true;
        } else if (relativeRelationMap.containsKey(userId)) {
          markerColor = const Color.fromARGB(255, 202, 23, 178);
          relationBadge = relativeRelationMap[userId];
        }
      }

      final icon = await _getMarkerIcon(
        distance: _num(user['distance']),
        avatarBytes: avatarBytes,
        color: markerColor,
        badge: relationBadge,
        isSelected: isSelectedUser,
        dpr: dpr,
      );

      // Đã có lần vẽ mới hơn (hoặc widget đã dispose) -> bỏ kết quả này
      if (seq != _markerSeq || !mounted) return;

      newMarkers.add(
        Marker(
          markerId: MarkerId(userId),
          position: user['location'],
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: true,
          onTap: () {
            setState(() {
              _selectedUserId = userId;
              _selectedUserData = user;
            });
            _generateCustomMarkers();
          },
        ),
      );
    }

    if (seq != _markerSeq || !mounted) return;
    setState(() => _userMarkers = newMarkers);
  }

  Future<BitmapDescriptor> _getMarkerIcon({
    required double distance,
    Uint8List? avatarBytes,
    required Color color,
    String? badge,
    required bool isSelected,
    required double dpr,
  }) async {
    final key =
        '${distance.toStringAsFixed(1)}|${avatarBytes?.length ?? 0}|${color.value}|${badge ?? ''}|$isSelected|$dpr';
    final cached = _iconCache[key];
    if (cached != null) return cached;

    final icon = await createCustomUserMarker(
      distance: distance,
      avatarBytes: avatarBytes,
      primaryColor: color,
      relationBadge: badge,
      isSelectedUser: isSelected,
      dpr: dpr,
    );
    if (_iconCache.length > 150) _iconCache.clear();
    _iconCache[key] = icon;
    return icon;
  }

  void _drawDefaultIcon(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final TextPainter iconPainter = TextPainter(
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
    double dpr = 1.0,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    canvas.scale(dpr, dpr); // 🟢 vẽ theo độ phân giải màn hình -> không bị mờ

    const double avatarRadius = 20.0;
    const double padding = 6.0;
    final String distanceText = '${distance.toStringAsFixed(1)}m';

    final bool isWhite = primaryColor == Colors.white;
    final Color textColor = isWhite ? const Color(0xFF1F2937) : primaryColor;
    final Color borderColor = isWhite ? const Color(0xFFCBD5E1) : primaryColor;

    final TextPainter distancePainter = TextPainter(
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
    const double badgeHeight = 15.0;
    double badgeWidth = 0;
    const double subBadgeHeight = 15.0;
    double subBadgeWidth = 0;

    const double avatarDiameter = avatarRadius * 2;
    final double baseContentWidth = distancePainter.width;
    final double cardWidth =
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

    final double cardHeight =
        avatarDiameter + distancePainter.height + (padding * 2.2);
    final double topExtraHeight = subBadgeTextPainter != null
        ? (subBadgeHeight / 2 + 6)
        : 0;
    final double bottomExtraHeight = badgeTextPainter != null
        ? (badgeHeight / 2)
        : 0;
    final double totalCanvasHeight =
        cardHeight + topExtraHeight + bottomExtraHeight;

    canvas.save();
    canvas.translate(2, topExtraHeight + 1);

    final Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final RRect bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cardWidth, cardHeight),
      const Radius.circular(14),
    );
    canvas.drawRRect(bgRRect.shift(const Offset(2, 2)), shadowPaint);
    canvas.drawRRect(bgRRect, Paint()..color = Colors.white);

    canvas.drawRRect(
      bgRRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isWhite ? 1.5 : 2.5,
    );

    final Offset avatarCenter = Offset(cardWidth / 2, padding + avatarRadius);
    canvas.drawCircle(
      avatarCenter,
      avatarRadius,
      Paint()
        ..color = isWhite
            ? const Color(0xFFF1F5F9)
            : primaryColor.withOpacity(0.15),
    );

    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      ui.Codec? codec;
      ui.Image? image;
      try {
        codec = await ui.instantiateImageCodec(avatarBytes);
        final ui.FrameInfo fi = await codec.getNextFrame();
        image = fi.image;

        canvas.save();
        canvas.clipPath(
          Path()..addOval(
            Rect.fromCircle(center: avatarCenter, radius: avatarRadius - 1.5),
          ),
        );
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCircle(center: avatarCenter, radius: avatarRadius - 1.5),
          Paint(),
        );
        canvas.restore();
      } catch (_) {
        _drawDefaultIcon(canvas, avatarCenter, avatarRadius, primaryColor);
      } finally {
        image?.dispose(); // 🟢 giải phóng bộ nhớ native
        codec?.dispose();
      }
    } else {
      _drawDefaultIcon(canvas, avatarCenter, avatarRadius, primaryColor);
    }

    distancePainter.paint(
      canvas,
      Offset(
        (cardWidth - distancePainter.width) / 2,
        padding + avatarDiameter + 2,
      ),
    );

    void drawBadge(
      TextPainter painter,
      double w,
      double h,
      double x,
      double y,
    ) {
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(r, Paint()..color = primaryColor);
      canvas.drawRRect(
        r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      painter.paint(
        canvas,
        Offset(x + (w - painter.width) / 2, y + (h - painter.height) / 2),
      );
    }

    if (badgeTextPainter != null) {
      drawBadge(
        badgeTextPainter,
        badgeWidth,
        badgeHeight,
        (cardWidth - badgeWidth) / 2,
        cardHeight - (badgeHeight / 2),
      );
    }
    if (subBadgeTextPainter != null) {
      drawBadge(
        subBadgeTextPainter,
        subBadgeWidth,
        subBadgeHeight,
        (cardWidth - subBadgeWidth) / 2,
        -(subBadgeHeight / 2),
      );
    }

    canvas.restore();

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image renderedImage = await picture.toImage(
      ((cardWidth + 10) * dpr).ceil(),
      ((totalCanvasHeight + 10) * dpr).ceil(),
    );
    picture.dispose();
    final ByteData? byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    renderedImage.dispose();

    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(
      byteData.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  void _showUserInfoModal(BuildContext context, Map<String, dynamic> user) {
    final List<dynamic> danhSachNguoiThan = user['danhSachNguoiThan'] ?? [];
    final bool coNguoiThan = danhSachNguoiThan.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
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
                          'Trong phạm vi: ${_num(user['distance']).toStringAsFixed(1)}m',
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
                      final nt = danhSachNguoiThan[index];
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
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Người dùng này không có người thân để liên hệ!',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext);
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
            if (widget.isLoadingLocation)
              const CircularProgressIndicator(color: Color(0xFFC80815))
            else
              const Icon(
                Icons.location_off_rounded,
                size: 40,
                color: Colors.grey,
              ),
            const SizedBox(height: 12),
            Text(
              widget.isLoadingLocation
                  ? 'Đang định vị vị trí thực tế...'
                  : 'Chưa thể lấy vị trí. Vui lòng bật GPS và thử lại.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            // 🟢 Nút thử lại (trước đây có callback nhưng không có nút)
            if (!widget.isLoadingLocation) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: widget.isLoadingLocation
                    ? null
                    : widget.onRefreshLocation,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      );
    }

    final Color statusColor = widget.isOnline
        ? ColorCHV.tiep_nhan_yeu_cau
        : ColorCHV.ngung_tiep_nhan_yeu_cau;

    return Stack(
      children: [
        GoogleMap(
          // 🟢 ĐÃ BỎ key theo tọa độ: map không bị dựng lại mỗi lần GPS nhích.
          // Camera được controller điều khiển bằng animateCamera.
          initialCameraPosition: CameraPosition(
            target: widget.currentPosition!,
            zoom: 24,
          ),
          onMapCreated: widget.onMapCreated,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _userMarkers,
          onTap: (_) {
            if (_selectedUserId != null) _clearSelection();
          },
          circles: {
            Circle(
              circleId: const CircleId('circle_nearby_boundary'),
              center: widget.currentPosition!,
              radius: TrangChuController.kNearbyRadiusMeters,
              fillColor: statusColor.withOpacity(0.18),
              strokeColor: statusColor.withOpacity(0.6),
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
              fillColor: statusColor,
              strokeColor: Colors.transparent,
              strokeWidth: 0,
              zIndex: 3,
            ),
          },
        ),

        // Thẻ tóm tắt khi chọn mục tiêu
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
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: _clearSelection,
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
                        'Khoảng cách: ${_num(_selectedUserData!['distance']).toStringAsFixed(1)}m',
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
                          onPressed: () =>
                              _showUserInfoModal(context, _selectedUserData!),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Ds người thân'),
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
                            final List<dynamic> listNT =
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
                            'Gọi người thân',
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
