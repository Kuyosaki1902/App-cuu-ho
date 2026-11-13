import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../controllers/rescue_process_controller.dart';
import 'rescue_theme.dart';

/// Bản đồ phủ toàn vùng nội dung. Vùng "padding" giữ trung tâm camera và
/// logo Google nằm ngoài phần bị thẻ nổi / bottom sheet che.
class MapAccessCard extends StatefulWidget {
  const MapAccessCard({super.key});

  @override
  State<MapAccessCard> createState() => _MapAccessCardState();
}

class _MapAccessCardState extends State<MapAccessCard> {
  BitmapDescriptor? _victimIcon;
  BitmapDescriptor? _doctorIcon;
  late final RescueProcessController _rescue;
  GoogleMapController? _mapCtrl;
  int _lastStep = 0;

  @override
  void initState() {
    super.initState();
    _rescue = context.read<RescueProcessController>();
    _lastStep = _rescue.currentStep;
    _rescue.addListener(_onControllerChanged);
    _createVictimMarkerIcon();
    _createBlueDotMarker();
  }

  @override
  void dispose() {
    _rescue.removeListener(_onControllerChanged);
    if (identical(_rescue.mapController, _mapCtrl)) {
      _rescue.mapController = null; // tránh dùng controller đã bị huỷ
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (_rescue.currentStep != _lastStep) {
      _lastStep = _rescue.currentStep;
      if (_lastStep >= RescueProcessController.stepArrived) {
        _rescue.focusVictim();
      }
    }
  }

  // Marker nạn nhân: nền trắng, viền đỏ, biểu tượng người.
  Future<void> _createVictimMarkerIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(96, 96);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center + const Offset(0, 2),
      38,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, 38, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      38,
      Paint()
        ..color = RC.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontSize: 44,
          fontFamily: Icons.person.fontFamily,
          color: RC.red,
        ),
      )
      ..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (mounted && bytes != null) {
      setState(() {
        _victimIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }

  // Chấm xanh định vị của cứu hộ viên.
  Future<void> _createBlueDotMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(100, 100);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center + const Offset(0, 2),
      18,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, 18, Paint()..color = RC.blue);
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (mounted && bytes != null) {
      setState(() {
        _doctorIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RescueProcessController>();
    final inApproach = c.currentStep == RescueProcessController.stepMoving;

    final initialTarget = c.hasDoctorLocation
        ? c.doctorLocation
        : (c.hasVictimLocation
              ? c.victimLocation
              : const LatLng(10.762622, 106.660172));

    final markers = <Marker>{
      if (c.hasDoctorLocation)
        Marker(
          markerId: const MarkerId('doctor'),
          position: c.doctorLocation,
          icon:
              _doctorIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          zIndex: 2,
          infoWindow: InfoWindow(title: 'Vị trí của bạn'),
        ),
      if (c.hasVictimLocation)
        Marker(
          markerId: const MarkerId('victim'),
          position: c.victimLocation,
          icon:
              _victimIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(0.5, 0.5),
          zIndex: 1,
          infoWindow: InfoWindow(
            title: c.victimName,
            snippet: c.isVictimLocationApproximate ? 'Vị trí gần đúng' : null,
          ),
        ),
    };

    final circles = <Circle>{
      if (c.hasDoctorLocation)
        Circle(
          circleId: const CircleId('gps_accuracy'),
          center: c.doctorLocation,
          radius: (c.gpsAccuracyMeters ?? 10).clamp(5, 150).toDouble(),
          fillColor: RC.blue.withOpacity(0.12),
          strokeColor: RC.blue.withOpacity(0.35),
          strokeWidth: 1,
        ),
      if (c.hasVictimLocation && inApproach)
        Circle(
          circleId: const CircleId('arrival_zone'),
          center: c.victimLocation,
          radius: RescueProcessController.arrivalRadiusMeters,
          fillColor: RC.red.withOpacity(0.10),
          strokeColor: RC.red.withOpacity(0.55),
          strokeWidth: 1,
        ),
    };

    final polylines = <Polyline>{
      if (inApproach && c.polylineCoordinates.length >= 2) ...[
        Polyline(
          polylineId: const PolylineId('route_casing'),
          points: c.polylineCoordinates,
          color: Colors.white,
          width: 9,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: c.polylineCoordinates,
          color: RC.blue,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      ],
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return GoogleMap(
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 16),
          padding: EdgeInsets.only(top: 170, bottom: constraints.maxHeight * 0.40),
          markers: markers,
          circles: circles,
          polylines: polylines,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onMapCreated: (ctrl) {
            _mapCtrl = ctrl;
            c.mapController = ctrl;
            if (c.hasDoctorLocation && c.hasVictimLocation) {
              c.fitMapBounds();
            } else if (c.hasDoctorLocation) {
              ctrl.animateCamera(
                CameraUpdate.newLatLngZoom(c.doctorLocation, 16),
              );
            }
          },
        );
      },
    );
  }
}
