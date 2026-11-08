import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final icon = await createCustomUserMarker(
      primaryColor: Colors.white,
      mucDo: controller.mucDoKhanCap,
    );

    if (mounted) {
      setState(() {
        _customVictimIcon = icon;
      });
    }
  }

  Future<BitmapDescriptor> createCustomUserMarker({
    Color primaryColor = Colors.white,
    required int mucDo,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double size = 96.0;
    const double radius = size / 2;

    final Path shadowPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: const Offset(radius, radius),
          radius: radius - 4,
        ),
      );
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.22), 5.0, true);

    final Paint bgPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(radius, radius), radius - 4, bgPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(radius, radius), radius - 4, borderPaint);

    Color iconColor = mucDo == 1
        ? const Color(0xFFDC2626)
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
    userIconPainter.paint(canvas, const Offset(radius - 21, radius - 21));

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
        ? const Color(0xFFDC2626)
        : Colors.amber.shade800;

    final Set<Polyline> polylines = {
      if (controller.polylineCoordinates.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('real_world_route'),
          points: controller.polylineCoordinates,
          color: themeColor,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Nút chọn phương tiện + Khoảng cách
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.navigation_outlined,
                        size: 14,
                        color: themeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.distanceText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildVehicleOption(
                  controller: controller,
                  modeValue: 'cycling',
                  icon: Icons.two_wheeler_rounded,
                  label: controller.motoTime,
                ),
                const SizedBox(width: 6),
                _buildVehicleOption(
                  controller: controller,
                  modeValue: 'driving',
                  icon: Icons.local_hospital_outlined,
                  label: controller.carTime,
                ),
                const SizedBox(width: 6),
                _buildVehicleOption(
                  controller: controller,
                  modeValue: 'foot',
                  icon: Icons.directions_walk_rounded,
                  label: controller.walkTime,
                ),
              ],
            ),
          ),

          // Google Maps
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ClipRRect(
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
                    myLocationButtonEnabled: false,
                    onMapCreated: (mapCtrl) {
                      controller.setMapController(mapCtrl);
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Column(
                      children: [
                        _buildMapIconButton(Icons.my_location_rounded, () {
                          if (controller.mapController != null &&
                              controller.myLocation.latitude != 0.0) {
                            controller.mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                controller.myLocation,
                                16.0,
                              ),
                            );
                          }
                        }),
                        const SizedBox(height: 6),
                        _buildMapIconButton(Icons.explore_outlined, () {}),
                        const SizedBox(height: 6),
                        _buildMapIconButton(Icons.layers_outlined, () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Địa chỉ nạn nhân thực tế
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLevel1
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: themeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ĐỊA CHỈ NẠN NHÂN (VỊ TRÍ SỰ CỐ THỰC TẾ)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            controller.address,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${controller.victimLocation.latitude}, ${controller.victimLocation.longitude}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép tọa độ!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Sao chép toạ độ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          size: 15,
                          color: Color(0xFFD97706),
                        ),
                        label: const Text(
                          'Báo chướng ngại vật',
                          style: TextStyle(color: Color(0xFFD97706)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFDE68A)),
                          backgroundColor: const Color(0xFFFFFBEB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption({
    required EmergencyAlertController controller,
    required String modeValue,
    required IconData icon,
    required String label,
  }) {
    bool isSelected = controller.selectedTravelMode == modeValue;

    return GestureDetector(
      onTap: () {
        controller.changeTravelMode(modeValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDC2626)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF475569)),
      ),
    );
  }
}
