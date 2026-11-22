// lib/user/TongQuanBacSiTiepNhan/TongQuanBacSiTiepNhan.dart
import 'package:cuhokhancap/user/ChatVoiAI.dart';
import 'package:cuhokhancap/user/ChiTietDuongDiBacSi.dart/ChiTietDuongDi.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/controllers/tongquancontroller.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/Models/tracking_rescuer_model.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/views/rescuer_overview_components.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TongQuanBacSiTiepNhan extends StatefulWidget {
  final String maYeuCau;
  final String currentUserId;
  final double victimLat;
  final double victimLng;
  final Map<String, LatLng>? initialLocations;

  const TongQuanBacSiTiepNhan({
    super.key,
    required this.maYeuCau,
    required this.currentUserId,
    required this.victimLat,
    required this.victimLng,
    this.initialLocations,
  });

  @override
  State<TongQuanBacSiTiepNhan> createState() => _TongQuanBacSiTiepNhanState();
}

class _TongQuanBacSiTiepNhanState extends State<TongQuanBacSiTiepNhan> {
  late RescuerOverviewController _controller;
  GoogleMapController? _mapController;

  bool _isAutoFitEnabled = false;
  bool _isCollapsed = false;
  int _previousRescuerCount = 0;
  BitmapDescriptor? _victimMarkerIcon;

  @override
  void initState() {
    super.initState();
    _initVictimMarkerIcon();
    _controller = RescuerOverviewController(
      maYeuCau: widget.maYeuCau,
      victimLat: widget.victimLat,
      victimLng: widget.victimLng,
      onNoRescuerLeft: _onNoRescuerLeft,
    );
    _controller.initController();

    _controller.trackingListNotifier.addListener(() {
      int currentCount = _controller.trackingListNotifier.value.length;
      if (currentCount > _previousRescuerCount) {
        if (mounted) {
          setState(() {
            _isCollapsed = false;
          });
        }
      }
      _previousRescuerCount = currentCount;
    });
  }

  Future<void> _onNoRescuerLeft() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Đơn Không Còn Người Tiếp Nhận'),
        content: const Text(
          'Đơn cứu hộ hiện không còn ai tiếp nhận. '
          'Các lời mời đã phát sẽ được thu hồi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _initVictimMarkerIcon() async {
    Widget victimMarkerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC81E1E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -1),
              child: ClipPath(
                clipper: _ArrowClipper(),
                child: Container(
                  width: 14,
                  height: 8,
                  color: const Color(0xFFC81E1E),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC81E1E),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Vị trí của bạn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFC81E1E),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final icon = await victimMarkerWidget.toBitmapDescriptor(
      waitToRender: const Duration(milliseconds: 100),
    );
    if (mounted) {
      setState(() {
        _victimMarkerIcon = icon;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _openRescuerRouteDetail(TrackingRescuerModel res) {
    if (res.phanCong.maTrangThaiTiepNhan ==
        'cuuho_trangthai_phancong_hoanthanh') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${res.nguoiDung.hoTen} đã hoàn thành nhiệm vụ cứu hộ.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final rescuerId = res.nguoiDung.maNguoiDung;
    if (rescuerId == null) return;

    double sLat =
        widget.initialLocations?[rescuerId]?.latitude ??
        res.nguoiDung.viDo ??
        widget.victimLat;
    double sLng =
        widget.initialLocations?[rescuerId]?.longitude ??
        res.nguoiDung.kinhDo ??
        widget.victimLng;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChiTietDuongDiScreen(
          maNguoiCuuHo: rescuerId,
          startLat: sLat,
          startLng: sLng,
          victimLat: widget.victimLat,
          victimLng: widget.victimLng,
          tenBacSi: res.nguoiDung.hoTen,
          maYeuCau: widget.maYeuCau,
          soDienThoai: res.nguoiDung.soDienThoai,
        ),
      ),
    );
  }

  void _fitAllMarkers(List<TrackingRescuerModel> rescuers) {
    if (_mapController == null || rescuers.isEmpty) return;
    double maxDeltaLat = 0.0;
    double maxDeltaLng = 0.0;
    for (var res in rescuers) {
      double lat = res.nguoiDung.viDo ?? widget.victimLat;
      double lng = res.nguoiDung.kinhDo ?? widget.victimLng;
      double deltaLat = (lat - widget.victimLat).abs();
      double deltaLng = (lng - widget.victimLng).abs();
      if (deltaLat > maxDeltaLat) maxDeltaLat = deltaLat;
      if (deltaLng > maxDeltaLng) maxDeltaLng = deltaLng;
    }
    maxDeltaLat *= 1.2;
    maxDeltaLng *= 1.2;
    if (maxDeltaLat == 0) maxDeltaLat = 0.005;
    if (maxDeltaLng == 0) maxDeltaLng = 0.005;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.victimLat - maxDeltaLat,
        widget.victimLng - maxDeltaLng,
      ),
      northeast: LatLng(
        widget.victimLat + maxDeltaLat,
        widget.victimLng + maxDeltaLng,
      ),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Set<Marker> _buildMarkers(List<TrackingRescuerModel> rescuers) {
    Set<Marker> markers = {};
    markers.add(
      Marker(
        markerId: const MarkerId('victim_marker'),
        position: LatLng(widget.victimLat, widget.victimLng),
        icon:
            _victimMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.75),
      ),
    );
    for (var res in rescuers) {
      final bool isCompleted =
          res.phanCong.maTrangThaiTiepNhan ==
          'cuuho_trangthai_phancong_hoanthanh';

      markers.add(
        Marker(
          markerId: MarkerId('rescuer_${res.nguoiDung.maNguoiDung}'),
          position: LatLng(
            res.nguoiDung.viDo ?? 0.0,
            res.nguoiDung.kinhDo ?? 0.0,
          ),
          icon:
              res.markerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                isCompleted
                    ? BitmapDescriptor.hueAzure
                    : BitmapDescriptor.hueGreen,
              ),
          anchor: const Offset(0.5, 0.5),
          onTap: isCompleted ? null : () => _openRescuerRouteDetail(res),
          infoWindow: InfoWindow(
            title: '${res.index}. ${res.nguoiDung.hoTen}',
            snippet: isCompleted
                ? 'Đã hoàn thành cứu hộ'
                : 'Cách ${res.distanceKm.toStringAsFixed(1)}km',
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        body: ValueListenableBuilder<List<TrackingRescuerModel>>(
          valueListenable: _controller.trackingListNotifier,
          builder: (context, trackingList, child) {
            if (_isAutoFitEnabled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitAllMarkers(trackingList);
              });
            }

            int displayCount = trackingList.length > 3
                ? 3
                : trackingList.length;

            double calculatedHeight = _isCollapsed
                ? 130.0
                : (130.0 + 40.0 + (displayCount * 85.0)).clamp(
                    130.0,
                    screenHeight * 0.6,
                  );

            int movingCount = trackingList
                .where(
                  (r) =>
                      r.phanCong.maTrangThaiTiepNhan ==
                      'cuuho_trangthai_phancong_tiepnhan',
                )
                .length;

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.victimLat, widget.victimLng),
                    zoom: 14.5,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _buildMarkers(trackingList),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  padding: EdgeInsets.only(bottom: calculatedHeight),
                  onCameraMoveStarted: () {
                    if (_isAutoFitEnabled) {
                      setState(() {
                        _isAutoFitEnabled = false;
                      });
                    }
                  },
                ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: calculatedHeight,
                  child: RescuerListBottomSheet(
                    trackingList: trackingList,
                    maYeuCau: widget.maYeuCau,
                    currentUserId: widget.currentUserId,
                    victimLat: widget.victimLat,
                    victimLng: widget.victimLng,
                    isCollapsed: _isCollapsed,
                    onToggleCollapse: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                    },
                    onRescuerAvatarTap: (item) {
                      _openRescuerRouteDetail(item);
                    },
                    onRescuerTap: (lat, lng) async {
                      setState(() {
                        _isAutoFitEnabled = false;
                      });

                      if (_mapController != null) {
                        double currentZoom = await _mapController!
                            .getZoomLevel();
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(lat, lng),
                              zoom: currentZoom,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: RescuerTopNavBar(
                    rescuerCount: movingCount > 0
                        ? movingCount
                        : trackingList.length,
                    onBack: () => Navigator.pop(context),
                    onChatAIPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatVoiAIScreen(),
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  right: 16,
                  top: 100,
                  child: Column(
                    children: [
                      MapControlButton(
                        icon: _isAutoFitEnabled
                            ? Icons.zoom_out_map
                            : Icons.center_focus_strong,
                        iconColor: _isAutoFitEnabled
                            ? Colors.blue
                            : Colors.black87,
                        onTap: () {
                          setState(() {
                            _isAutoFitEnabled = !_isAutoFitEnabled;
                          });
                          if (_isAutoFitEnabled) _fitAllMarkers(trackingList);
                        },
                      ),
                      const SizedBox(height: 12),
                      MapControlButton(
                        icon: Icons.my_location,
                        onTap: () async {
                          setState(() {
                            _isAutoFitEnabled = false;
                          });

                          if (_mapController != null) {
                            double currentZoom = await _mapController!
                                .getZoomLevel();
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    widget.victimLat,
                                    widget.victimLng,
                                  ),
                                  zoom: currentZoom,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
