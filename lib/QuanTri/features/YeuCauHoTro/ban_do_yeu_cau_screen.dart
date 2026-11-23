import 'dart:math' as math;
import 'controllers/yeu_cau_ho_tro_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/yeu_cau_ho_tro_model.dart';

class BanDoYeuCauScreen extends StatelessWidget {
  final List<YeuCauHoTro> requests;
  final YeuCauHoTroController? controller;
  final Future<void> Function(YeuCauHoTro) onOpen;
  const BanDoYeuCauScreen({
    super.key,
    required this.requests,
    this.controller,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) {
    final live = controller;
    if (live == null) return buildMap(context, requests);
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) => buildMap(context, live.filtered),
    );
  }

  Widget buildMap(BuildContext context, List<YeuCauHoTro> requests) {
    final located = requests.where((r) => r.hasLocation).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ yêu cầu')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${located.length}/${requests.length} yêu cầu đã tải có vị trí hợp lệ.',
            ),
          ),
          Expanded(
            child: located.isEmpty
                ? const Center(child: Text('Chưa có tọa độ để hiển thị.'))
                : KhungBanDo(
                    markers: {
                      for (final r in located)
                        Marker(
                          markerId: MarkerId(r.id),
                          position: LatLng(r.latitude!, r.longitude!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            r.needsIntervention
                                ? BitmapDescriptor.hueRed
                                : BitmapDescriptor.hueAzure,
                          ),
                          infoWindow: InfoWindow(
                            title: r.code,
                            snippet: r.title,
                            onTap: () => onOpen(r),
                          ),
                        ),
                    },
                  ),
          ),
          if (located.isNotEmpty)
            SizedBox(
              height: 130,
              child: ListView.builder(
                itemCount: located.length,
                itemBuilder: (_, index) {
                  final r = located[index];
                  return ListTile(
                    title: Text('${r.code} · ${r.title}'),
                    subtitle: Text(r.address),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onOpen(r),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class KhungBanDo extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Circle> circles;
  final Set<Polyline> polylines;
  final bool dispatch;
  final ValueChanged<LatLng>? onMapTap;
  const KhungBanDo({
    this.onMapTap,
    super.key,
    required this.markers,
    this.polylines = const {},
    this.dispatch = false,
    this.circles = const <Circle>{},
  });

  @override
  State<KhungBanDo> createState() => _KhungBanDoState();
}

class _KhungBanDoState extends State<KhungBanDo> {
  final _RequestMapController controller = _RequestMapController();

  @override
  void initState() {
    super.initState();
    controller.updateMarkers(widget.markers, circles: widget.circles);
  }

  @override
  void didUpdateWidget(covariant KhungBanDo oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.updateMarkers(widget.markers, circles: widget.circles);
    if (widget.dispatch &&
        (_markerIdsChanged(oldWidget.markers, widget.markers) ||
            _circlesChanged(oldWidget.circles, widget.circles))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.fitPositions();
      });
    }
  }

  bool _markerIdsChanged(Set<Marker> oldMarkers, Set<Marker> newMarkers) {
    final oldIds = oldMarkers.map((marker) => marker.markerId.value).toSet();
    final newIds = newMarkers.map((marker) => marker.markerId.value).toSet();
    return oldIds.length != newIds.length || !oldIds.containsAll(newIds);
  }

  bool _circlesChanged(Set<Circle> oldCircles, Set<Circle> newCircles) {
    if (oldCircles.length != newCircles.length) return true;
    final oldById = {
      for (final circle in oldCircles) circle.circleId.value: circle,
    };
    for (final circle in newCircles) {
      final old = oldById[circle.circleId.value];
      if (old == null ||
          old.center != circle.center ||
          old.radius != circle.radius) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.markers.isEmpty) {
      return const Center(child: Text('Chưa có tọa độ hợp lệ.'));
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const Center(child: Text('Mở bản đồ trên ứng dụng Android.'));
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.markers.first.position,
              zoom: 14,
            ),
            onTap: widget.onMapTap,
            onMapCreated: controller.setMapController,
            markers: widget.markers,
            circles: widget.circles,
            polylines: widget.polylines,
            padding: widget.dispatch
                ? const EdgeInsets.only(top: 58, right: 56, bottom: 12)
                : EdgeInsets.zero,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            right: 12,
            bottom: widget.dispatch ? null : 12,
            top: widget.dispatch ? 12 : null,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                tooltip: 'Hiển thị tất cả vị trí',
                onPressed: controller.fitPositions,
                icon: const Icon(Icons.center_focus_strong),
              ),
            ),
          ),
          if (controller.error != null)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(controller.error!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestMapController extends ChangeNotifier {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _disposed = false;
  String? error;

  void updateMarkers(
    Set<Marker> markers, {
    Set<Circle> circles = const <Circle>{},
  }) {
    _markers = markers;
    _circles = circles;
  }

  void setMapController(GoogleMapController controller) {
    if (_disposed) return;
    _mapController = controller;
    fitPositions();
  }

  Future<void> fitPositions() async {
    final map = _mapController;
    if (_disposed || map == null || _markers.isEmpty) return;
    final points = _markers.map((marker) => marker.position).toList();
    for (final circle in _circles) {
      final center = circle.center;
      final latitudeDelta = circle.radius / 111320;
      final cosine = math
          .cos(center.latitude * math.pi / 180)
          .abs()
          .clamp(.01, 1.0);
      final longitudeDelta = circle.radius / (111320 * cosine);
      points
        ..add(LatLng(center.latitude - latitudeDelta, center.longitude))
        ..add(LatLng(center.latitude + latitudeDelta, center.longitude))
        ..add(LatLng(center.latitude, center.longitude - longitudeDelta))
        ..add(LatLng(center.latitude, center.longitude + longitudeDelta));
    }
    double south = points.first.latitude, north = south;
    double west = points.first.longitude, east = west;
    for (final point in points.skip(1)) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }
    try {
      error = null;
      await map.animateCamera(
        south == north && west == east
            ? CameraUpdate.newLatLngZoom(points.first, 15)
            : CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east),
                ),
                48,
              ),
      );
    } catch (_) {
      error = 'Chưa thể căn chỉnh bản đồ. Hãy thử lại.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _mapController = null;
    super.dispose();
  }
}
