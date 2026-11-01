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
  int? _lastMucDo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.watch<EmergencyAlertController>();
    if (_lastMucDo != controller.mucDoKhanCap) {
      _lastMucDo = controller.mucDoKhanCap;
      _loadCustomVictimMarker();
    }
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
      mucDo: controller.mucDoKhanCap,
    );

    if (mounted) {
      setState(() {
        _customVictimIcon = icon;
      });
    }
  }

  // 🟢 VẼ CANVAS NỀN TRẮNG VỚI ICON ĐỔI MÀU THEO MỨC ĐỘ KHẨN CẤP
  Future<BitmapDescriptor> createCustomUserMarker({
    required double distance,
    Uint8List? avatarBytes,
    Color primaryColor = Colors.white,
    required int mucDo,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double size = 96.0;
    const double radius = size / 2;

    final Path shadowPath = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - 4),
      );
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.22), 5.0, true);

    final Paint bgPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(radius, radius), radius - 4, bgPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(radius, radius), radius - 4, borderPaint);

    // 🟢 Đổi màu icon theo mức độ (1: Đỏ, 2: Vàng/Cam)
    Color iconColor = mucDo == 1
        ? const Color(0xFFE52525)
        : Colors.amber.shade800;

    TextPainter userIconPainter = TextPainter(textDirection: TextDirection.ltr);
    userIconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.person.codePoint),
      style: TextStyle(
        fontSize: 42.0,
        fontFamily: Icons.person.fontFamily,
        color: iconColor,
      ),
    );
    userIconPainter.layout();
    userIconPainter.paint(canvas, Offset(radius - 21, radius - 21));

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

    bool isLevel1 = controller.mucDoKhanCap == 1;
    Color themeColor = isLevel1
        ? const Color(0xFFE52525)
        : Colors.amber.shade800;

    final Set<Polyline> polylines = {
      if (controller.polylineCoordinates.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('real_world_route'),
          points: controller.polylineCoordinates,
          color: themeColor, // 🟢 Đổi màu đường đi theo mức độ
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
            BitmapDescriptor.defaultMarkerWithHue(
              isLevel1 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
            ),
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
                          Icon(
                            Icons.near_me_outlined,
                            size: 16,
                            color: themeColor, // 🟢 Đổi màu icon khoảng cách
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller.distanceText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: themeColor, // 🟢 Đổi màu chữ khoảng cách
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                          themeColor,
                        ),
                        const SizedBox(width: 6),
                        _buildModeButton(
                          controller,
                          Icons.motorcycle_outlined,
                          controller.motoTime,
                          'cycling',
                          themeColor,
                        ),
                        const SizedBox(width: 6),
                        _buildModeButton(
                          controller,
                          Icons.directions_walk,
                          controller.walkTime,
                          'foot',
                          themeColor,
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
                    color: isLevel1
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: themeColor, // 🟢 Đổi màu icon địa chỉ
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

  Widget _buildModeButton(
    EmergencyAlertController controller,
    IconData icon,
    String text,
    String modeValue,
    Color themeColor,
  ) {
    bool isSelected = controller.selectedTravelMode == modeValue;

    return GestureDetector(
      onTap: () {
        controller.changeTravelMode(modeValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : themeColor),
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
