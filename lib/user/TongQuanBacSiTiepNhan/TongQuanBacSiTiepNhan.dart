// lib/user/TongQuanBacSiTiepNhan/TongQuanBacSiTiepNhan.dart
import 'package:cuhokhancap/user/ChiTietDuongDiBacSi.dart/ChiTietDuongDi.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/controllers/tongquancontroller.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/Models/tracking_rescuer_model.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/views/rescuer_overview_components.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  double _bottomSheetFraction =
      0.38; // 🌟 Phục hồi biến quản lý chiều cao bottom sheet

  @override
  void initState() {
    super.initState();
    _controller = RescuerOverviewController(
      maYeuCau: widget.maYeuCau,
      victimLat: widget.victimLat,
      victimLng: widget.victimLng,
    );
    _controller.initController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController?.dispose();
    super.dispose();
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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
      ),
    );
    for (var res in rescuers) {
      markers.add(
        Marker(
          markerId: MarkerId('rescuer_${res.nguoiDung.maNguoiDung}'),
          position: LatLng(
            res.nguoiDung.viDo ?? 0.0,
            res.nguoiDung.kinhDo ?? 0.0,
          ),
          icon:
              res.markerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 0.5),
          onTap: () {
            double sLat =
                widget.initialLocations?[res.nguoiDung.maNguoiDung]?.latitude ??
                res.nguoiDung.viDo ??
                widget.victimLat;
            double sLng =
                widget
                    .initialLocations?[res.nguoiDung.maNguoiDung]
                    ?.longitude ??
                res.nguoiDung.kinhDo ??
                widget.victimLng;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChiTietDuongDiScreen(
                  maNguoiCuuHo: res.nguoiDung.maNguoiDung!,
                  startLat: sLat,
                  startLng: sLng,
                  victimLat: widget.victimLat,
                  victimLng: widget.victimLng,
                  tenBacSi: res.nguoiDung.hoTen,
                ),
              ),
            );
          },
          infoWindow: InfoWindow(
            title: '${res.index}. ${res.nguoiDung.hoTen}',
            snippet: 'Cách ${res.distanceKm.toStringAsFixed(1)}km',
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double mapBottomPadding = screenHeight * _bottomSheetFraction;

    return Scaffold(
      body: ValueListenableBuilder<List<TrackingRescuerModel>>(
        valueListenable: _controller.trackingListNotifier,
        builder: (context, trackingList, child) {
          if (_isAutoFitEnabled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitAllMarkers(trackingList);
            });
          }

          return Stack(
            children: [
              // 1. BẢN ĐỒ (Đã gắn lại padding theo chiều cao BottomSheet)
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
                padding: EdgeInsets.only(bottom: mapBottomPadding),

                // Tự động tắt Auto-Fit khi người dùng chạm tay vuốt bản đồ
                onCameraMoveStarted: () {
                  if (_isAutoFitEnabled) {
                    setState(() {
                      _isAutoFitEnabled = false;
                    });
                  }
                },
              ),

              // 2. BOTTOM SHEET
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _bottomSheetFraction = notification.extent;
                  });
                  return true;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: 0.30,
                  minChildSize: 0.18,
                  maxChildSize: 0.42,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return RescuerListBottomSheet(
                      trackingList: trackingList,
                      maYeuCau: widget.maYeuCau,
                      currentUserId: widget.currentUserId,
                      victimLat:
                          widget.victimLat, // 🌟 Đảm bảo ở đây có truyền vào
                      victimLng:
                          widget.victimLng, // 🌟 Đảm bảo ở đây có truyền vào
                      scrollController: scrollController,
                      // 🌟 SỬA TẠI ĐÂY: Nhấn vào card/avatar sẽ lia map đến bác sĩ mà giữ nguyên mức zoom
                      onRescuerTap: (lat, lng) async {
                        setState(() {
                          _isAutoFitEnabled =
                              false; // Tắt chế độ tự động bao quát
                        });

                        if (_mapController != null) {
                          // Lấy mức zoom hiện tại người dùng đang xem
                          double currentZoom = await _mapController!
                              .getZoomLevel();

                          _mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(lat, lng),
                                zoom:
                                    currentZoom, // Giữ nguyên hiện trạng zoom, không bị phóng to thu nhỏ
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              // 3. TOP NAV
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RescuerTopNavBar(
                  rescuerCount: trackingList.length,
                  onBack: () => Navigator.pop(context),
                  onSosPressed: () {},
                ),
              ),

              // 4. MAP CONTROLS (Đủ 2 nút: Auto-fit & Định vị giữ zoom)
              Positioned(
                right: 16,
                top: 100,
                child: Column(
                  children: [
                    // Nút 1: Bật/Tắt Auto Fit (Bao quát lộ trình)
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
                    // Nút 2: Về vị trí nạn nhân (Giữ nguyên mức zoom hiện tại)
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
    );
  }
}
