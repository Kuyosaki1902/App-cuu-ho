import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/emergency_alert_controller.dart';

class MapNavigationCard extends StatefulWidget {
  const MapNavigationCard({super.key});

  @override
  State<MapNavigationCard> createState() => _MapNavigationCardState();
}

class _MapNavigationCardState extends State<MapNavigationCard> {
  BitmapDescriptor? _customVictimIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomVictimMarker();
    });
  }

  Future<void> _loadCustomVictimMarker() async {
    final controller = context.read<EmergencyAlertController>();

    double distanceInMeters = controller.victimLocation.latitude == 0.0
        ? 0.0
        : double.tryParse(
                controller.distanceText
                    .replaceAll('m', '')
                    .replaceAll('km', ''),
              ) ??
              0.0;

    final icon = await createCustomUserMarker(
      distance: distanceInMeters,
      avatarBytes: null,
      primaryColor: Colors.white,
      relationBadge: null,
    );

    if (mounted) {
      setState(() {
        _customVictimIcon = icon;
      });
    }
  }

  // 🟢 VẼ CANVAS NỀN TRẮNG HÌNH TRÒN TUYỆT ĐỐI GIỐNG AVATAR
  Future<BitmapDescriptor> createCustomUserMarker({
    required double distance,
    Uint8List? avatarBytes,
    Color primaryColor = Colors.white,
    String? relationBadge,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double size = 96.0; // Kích thước tổng thể canvas hình vuông
    const double radius = size / 2;

    // 1. Đổ bóng mượt quanh hình tròn
    final Path shadowPath = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - 4),
      );
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.22), 5.0, true);

    // 2. Nền trắng hình tròn hoàn toàn
    final Paint bgPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(radius, radius), radius - 4, bgPaint);

    // Thêm viền nhẹ sắc nét quanh vòng tròn trắng
    final Paint borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(radius, radius), radius - 4, borderPaint);

    // 3. Icon Người dùng màu xanh dương ở chính giữa
    TextPainter userIconPainter = TextPainter(textDirection: TextDirection.ltr);
    userIconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.person.codePoint),
      style: TextStyle(
        fontSize: 42.0, // Kích thước icon cân đối bên trong hình tròn
        fontFamily: Icons.person.fontFamily,
        color: const Color(0xFF0088CC),
      ),
    );
    userIconPainter.layout();
    userIconPainter.paint(
      canvas,
      Offset(radius - 21, radius - 21), // Căn giữa tuyệt đối icon
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyAlertController>();

    final Set<Polyline> polylines = {
      if (controller.polylineCoordinates.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('real_world_route'),
          points: controller.polylineCoordinates,
          color: const ui.Color.fromARGB(255, 11, 59, 230),
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
    };

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('victim_sos_custom'),
        position: controller.victimLocation,
        icon:
            _customVictimIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: controller.victimName,
          snippet: 'SĐT: ${controller.victimPhone}',
        ),
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: controller.victimLocation,
                      zoom: 16.0,
                    ),
                    markers: markers,
                    polylines: polylines,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    padding: const EdgeInsets.only(top: 30, right: 6),
                    onMapCreated: (mapCtrl) {
                      controller.setMapController(mapCtrl);
                    },
                  ),

                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me_outlined,
                            size: 16,
                            color: Color(0xFFE52525),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller.distanceText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE52525),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🟢 THAY THẾ ROW THÀNH 3 NÚT TƯƠNG TÁC ĐƯỢC
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        _buildModeButton(
                          controller,
                          Icons.car_crash_outlined,
                          controller.carTime,
                          'driving',
                        ),
                        const SizedBox(width: 6),
                        _buildModeButton(
                          controller,
                          Icons.motorcycle_outlined,
                          controller.motoTime,
                          'cycling',
                        ),
                        const SizedBox(width: 6),
                        _buildModeButton(
                          controller,
                          Icons.directions_walk,
                          controller.walkTime,
                          'foot',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFE52525),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐỊA CHỈ NẠN NHÂN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.address,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 HÀM BUILD NÚT CHỌN PHƯƠNG TIỆN CÓ HIỆU ỨNG ĐỔI MÀU
  Widget _buildModeButton(
    EmergencyAlertController controller,
    IconData icon,
    String text,
    String modeValue,
  ) {
    bool isSelected = controller.selectedTravelMode == modeValue;

    return GestureDetector(
      onTap: () {
        controller.changeTravelMode(modeValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE52525) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFFE52525),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
