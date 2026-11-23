import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'controllers/dieu_phoi_controller.dart';
import 'models/dieu_phoi_model.dart';
import 'services/dieu_phoi_service.dart';
import 'models/chi_tiet_yeu_cau_model.dart';
import 'models/yeu_cau_ho_tro_model.dart';
import 'ban_do_yeu_cau_screen.dart';
import 'widgets/co_so_y_te_panel.dart';
import 'chat_yeu_cau_screen.dart';

Future<BitmapDescriptor> _taoMarkerDieuPhoi({
  required Color color,
  required IconData icon,
}) async {
  const size = 88.0;
  const center = Offset(size / 2, size / 2);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawCircle(
    center + const Offset(0, 3),
    34,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawCircle(center, 34, Paint()..color = Colors.white);
  canvas.drawCircle(
    center,
    34,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );

  final painter = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 40,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    )
    ..layout();
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );

  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) {
    final hue = color == Colors.red
        ? BitmapDescriptor.hueRed
        : color == Colors.green || color == Colors.teal
        ? BitmapDescriptor.hueGreen
        : color == Colors.orange
        ? BitmapDescriptor.hueOrange
        : BitmapDescriptor.hueAzure;
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }
  return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
}

/// Năm marker này cố định theo màu/icon. Cache Future ở mức isolate để
/// nhiều màn Điều phối dùng chung, kể cả khi cùng mở trong lúc đang vẽ.
/// Không giữ BuildContext, GoogleMapController hay dữ liệu của một ca cụ thể.
class _DieuPhoiMarkerCache {
  static Future<Map<String, BitmapDescriptor>>? _icons;

  static Future<Map<String, BitmapDescriptor>> load() => _icons ??= _build();

  static Future<Map<String, BitmapDescriptor>> _build() async {
    try {
      final entries = await Future.wait([
        _taoMarkerDieuPhoi(color: Colors.red, icon: Icons.person),
        _taoMarkerDieuPhoi(color: Colors.blue, icon: Icons.person),
        _taoMarkerDieuPhoi(color: Colors.orange, icon: Icons.person),
        _taoMarkerDieuPhoi(color: Colors.green, icon: Icons.local_hospital),
        _taoMarkerDieuPhoi(color: Colors.teal, icon: Icons.local_hospital),
      ]);
      return Map<String, BitmapDescriptor>.unmodifiable({
        'incident': entries[0],
        'rescuer': entries[1],
        'rescuerSelected': entries[2],
        'medical': entries[3],
        'medicalSelected': entries[4],
      });
    } catch (_) {
      // Không giữ một Future lỗi mãi mãi; lần mở sau có thể thử lại.
      _icons = null;
      rethrow;
    }
  }
}

class DieuPhoiScreen extends StatefulWidget {
  final String id;
  const DieuPhoiScreen({super.key, required this.id});
  @override
  State<DieuPhoiScreen> createState() => _DieuPhoiScreenState();
}

class _DieuPhoiScreenState extends State<DieuPhoiScreen> {
  final sheet = DraggableScrollableController();
  String? selected;
  int _dispatchTab = 0; // 0: cứu hộ viên, 1: cơ sở y tế.
  bool _showMedicalCard = false;
  CoSoYTe? selectedMedical;
  String? _acceptedMedicalPlaceId;
  CoSoYTe? _acceptedMedicalFacility;
  String? _acceptedMedicalName;
  String? _localAcceptedAwaitingHistory;
  // Chờ lần đọc lịch sử đầu tiên trước khi gọi Google Places:
  // nếu ca đã có nơi tiếp nhận thì không tìm lại cả bán kính.
  bool _acceptedMedicalReady = false;
  bool _acceptedMedicalHistoryError = false;
  bool _replacingMedical = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _acceptedMedicalSub;
  int _acceptedHistoryVersion = 0;
  bool _checkingLegacyHistory = false;
  bool _legacyHistoryChecked = false;

  Query<Map<String, dynamic>> get _latestAcceptedMedicalQuery =>
      FirebaseFirestore.instance
          .collection('YeuCauCuuHo')
          .doc(widget.id)
          .collection('LichSuLienHeCoSoYTe')
          .where('ketQuaLienHe', isEqualTo: 'da_tiep_nhan');

  final _medicalService = CoSoYTeService();
  double? _searchedRadius;
  int _searchVersion = 0;
  AsyncSnapshot<List<CoSoYTe>> _medicalResult = const AsyncSnapshot.nothing();
  List<CoSoYTe> get medicalFacilities => _medicalResult.data ?? const [];
  List<CoSoYTe> get _visibleMedicalFacilities => coSoYTeHienThiTrenBanDo(
    facilities: medicalFacilities,
    acceptedPlaceId: _acceptedMedicalPlaceId,
    acceptedFacility: _acceptedMedicalFacility,
  );
  CoSoYTe? get _medicalRouteFacility => _acceptedMedicalPlaceId == null
      ? selectedMedical
      : _visibleMedicalFacilities.firstOrNull;

  final Map<String, BitmapDescriptor> _mapIcons = {};
  late final c = DieuPhoiController(DieuPhoiService(), widget.id);
  @override
  void initState() {
    super.initState();
    c.addListener(_searchMedicalIfNeeded);
    _watchAcceptedMedical();
    c.start();
    _loadMapIcons();
  }

  void _watchAcceptedMedical() {
    _acceptedMedicalSub = _latestAcceptedMedicalQuery
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            if (!mounted) return;
            // Truy vấn một trường không yêu cầu composite index.
            // Chỉ chọn bản ghi có thoiGian khi có dữ liệu mới, tương tự
            // orderBy trước đây (vốn loại bản ghi cũ thiếu thoiGian).
            final acceptedRows = snapshot.docs
                .map((doc) => doc.data())
                .toList(growable: false);
            final datedRows = acceptedRows
                .where((row) {
                  final time = row['thoiGian'];
                  return time is Timestamp || time is DateTime;
                })
                .toList(growable: false);
            // Không xác định được bản ghi mới nhất nếu có nhiều bản ghi cũ
            // cùng thiếu thời gian: tiếp tục chặn tìm kiếm để bảo toàn lựa chọn.
            if (datedRows.isEmpty && acceptedRows.length > 1) {
              setState(() {
                _acceptedMedicalHistoryError = true;
                _acceptedMedicalReady = false;
                ++_searchVersion;
              });
              return;
            }
            final latest = coSoYTeBanGhiDongYMoiNhat(
              datedRows.isNotEmpty ? datedRows : acceptedRows,
            );
            // Snapshot cache rỗng chưa chứng minh không có nơi tiếp nhận.
            if (latest == null && snapshot.metadata.isFromCache) return;
            // Đang xác nhận ghi thành công: snapshot cũ hoặc lựa chọn khác
            // không được hủy Future kiểm tra server đã khởi chạy.
            if (dangChoLichSuXacNhan(
              pendingPlaceId: _localAcceptedAwaitingHistory,
              history: latest == null
                  ? const <Map<String, dynamic>>[]
                  : [latest],
            ))
              return;
            if (latest == null) {
              // Nếu không thấy nơi đã tiếp nhận, xác nhận lại từ server.
              // Giới hạn tối đa 2 bản ghi khi kiểm tra tương thích.
              // Không cho Nearby Search chạy khi chưa kiểm tra xong.
              if (!_legacyHistoryChecked && !_checkingLegacyHistory) {
                _checkLegacyMedicalHistory();
              }
              return;
            }
            ++_acceptedHistoryVersion; // vô hiệu hóa fallback đang chạy
            _applyAcceptedHistory(latest);
          },
          onError: (Object error) {
            debugPrint('Loi truy van lich su tiep nhan co so y te: $error');
            if (!mounted) return;
            ++_acceptedHistoryVersion;
            // Khi lỗi quyền đọc hoặc mạng, không âm thầm tìm Places vì
            // chưa xác định được ca có bệnh viện tiếp nhận hay chưa.
            setState(() {
              _acceptedMedicalHistoryError = true;
              _acceptedMedicalReady = false;
              _replacingMedical = false;
              ++_searchVersion;
            });
          },
        );
  }

  /// Khi mọi bản ghi chuẩn đều không có kết quả, kiểm tra tối đa 2 bản
  /// ghi cũ chỉ có ketQuaLienHe nhưng có thể thiếu thoiGian.
  /// Nhiều bản ghi không có timestamp không thể xếp mới nhất an toàn;
  /// khóa Nearby Search để tránh tự chọn nhầm nơi tiếp nhận.
  Future<void> _checkLegacyMedicalHistory() async {
    _checkingLegacyHistory = true;
    _legacyHistoryChecked = true;
    final version = ++_acceptedHistoryVersion;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('YeuCauCuuHo')
          .doc(widget.id)
          .collection('LichSuLienHeCoSoYTe')
          .where('ketQuaLienHe', isEqualTo: 'da_tiep_nhan')
          .limit(2)
          .get(const GetOptions(source: Source.server));
      if (!mounted || version != _acceptedHistoryVersion) return;
      if (snapshot.docs.length > 1) {
        setState(() {
          _acceptedMedicalReady = false;
          _acceptedMedicalHistoryError = true;
          ++_searchVersion;
        });
        return;
      }
      final legacy = snapshot.docs.isEmpty ? null : snapshot.docs.single.data();
      _applyAcceptedHistory(legacy);
    } catch (error) {
      debugPrint('Loi kiem tra lich su co so y te tren server: $error');
      if (!mounted || version != _acceptedHistoryVersion) return;
      setState(() {
        _acceptedMedicalReady = false;
        _acceptedMedicalHistoryError = true;
        ++_searchVersion;
      });
    } finally {
      if (version == _acceptedHistoryVersion) {
        _checkingLegacyHistory = false;
      }
    }
  }

  /// Cùng một đường cập nhật cho stream mới nhất và kiểm tra tương thích.
  /// Không dùng dữ liệu trả về muộn để ghi đè bệnh viện vừa lưu thành công.
  void _applyAcceptedHistory(
    Map<String, dynamic>? latest, {
    bool confirmedByServer = false,
  }) {
    if (!mounted) return;
    if (!confirmedByServer &&
        dangChoLichSuXacNhan(
          pendingPlaceId: _localAcceptedAwaitingHistory,
          history: latest == null ? const <Map<String, dynamic>>[] : [latest],
        ))
      return;
    _localAcceptedAwaitingHistory = null;
    final placeId = latest?['maCoSoYTe']?.toString().trim();
    final acceptedId = placeId == null || placeId.isEmpty ? null : placeId;
    final changed = acceptedId != _acceptedMedicalPlaceId;
    final oldFacility = _acceptedMedicalFacility;
    final facilityFromHistory = coSoYTeTuLichSu(latest);
    final facilityFromSearch = medicalFacilities
        .where((row) => row.placeId == acceptedId)
        .firstOrNull;
    final nameFromHistory = latest?['tenCoSoYTe']?.toString().trim();
    if (changed && acceptedId != null) {
      ++_searchVersion;
      _searchedRadius = null;
    }
    setState(() {
      _acceptedMedicalReady = true;
      _acceptedMedicalHistoryError = false;
      _acceptedMedicalPlaceId = acceptedId;
      if (acceptedId == null) {
        _acceptedMedicalFacility = null;
        _acceptedMedicalName = null;
      } else {
        _acceptedMedicalFacility =
            !changed && oldFacility?.placeId == acceptedId
            ? oldFacility
            : facilityFromHistory ?? facilityFromSearch;
        final validName = nameFromHistory != null && nameFromHistory.isNotEmpty
            ? nameFromHistory
            : null;
        _acceptedMedicalName = _acceptedMedicalFacility?.name ?? validName;
        if (changed) {
          selectedMedical = _acceptedMedicalFacility;
          _showMedicalCard = false;
          _replacingMedical = false;
        }
      }
    });
    if (acceptedId == null) _searchMedicalIfNeeded();
  }

  /// Khi hai Admin chọn bệnh viện gần như đồng thời, xác nhận lại
  /// lịch sử trên server sau khi Cloud Function ghi thành công.
  /// Chọn bản ghi mới nhất theo thời gian, không cần composite index.
  Future<void> _confirmLocalAcceptance(int version) async {
    try {
      final snapshot = await _latestAcceptedMedicalQuery.get(
        const GetOptions(source: Source.server),
      );
      if (!mounted ||
          version != _acceptedHistoryVersion ||
          _localAcceptedAwaitingHistory == null)
        return;
      final rows = snapshot.docs.map((doc) => doc.data()).toList();
      final datedRows = rows.where((row) {
        final time = row['thoiGian'];
        return time is Timestamp || time is DateTime;
      }).toList();
      // Không chốt từ nhiều bản ghi cũ nếu không biết bản mới nhất.
      if (datedRows.isEmpty && rows.length > 1) return;
      final latest = coSoYTeBanGhiDongYMoiNhat(
        datedRows.isNotEmpty ? datedRows : rows,
      );
      if (latest != null) {
        ++_acceptedHistoryVersion;
        _applyAcceptedHistory(latest, confirmedByServer: true);
      }
    } catch (_) {
      // Giữ lựa chọn đã ghi thành công; listener realtime vẫn có thể
      // xác nhận nó sau khi kết nối được phục hồi.
    }
  }

  void _onMedicalAccepted(CoSoYTe facility) {
    if (!mounted) return;
    ++_searchVersion;
    final version = ++_acceptedHistoryVersion;
    setState(() {
      _acceptedMedicalReady = true;
      _acceptedMedicalHistoryError = false;
      _acceptedMedicalPlaceId = facility.placeId;
      _localAcceptedAwaitingHistory = facility.placeId;
      _acceptedMedicalFacility = facility;
      _acceptedMedicalName = facility.name;
      selectedMedical = facility;
      _showMedicalCard = false;
      _replacingMedical = false;
      _searchedRadius = null;
      _dispatchTab = 1;
    });
    _confirmLocalAcceptance(version);
  }

  Future<void> _requestMedicalReplacement() async {
    if (_acceptedMedicalPlaceId == null ||
        _replacingMedical ||
        !_acceptedMedicalReady ||
        _acceptedMedicalHistoryError)
      return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thay đổi cơ sở tiếp nhận?'),
        content: const Text(
          'Cơ sở đã đồng ý vẫn là nơi tiếp nhận hiện tại và vẫn được giữ '
          'trên bản đồ. Chỉ thay thế sau khi ghi nhận cơ sở mới đồng ý. '
          'Tìm kiếm lại sẽ sử dụng Google Places.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tìm cơ sở khác'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _replacingMedical = true;
      _searchedRadius = null;
      _medicalResult = const AsyncSnapshot.nothing();
    });
    _searchMedicalIfNeeded();
  }

  void _retryMedicalSearch() {
    if (!nenTimCoSoYTe(
      historyResolved: _acceptedMedicalReady,
      historyError: _acceptedMedicalHistoryError,
      acceptedPlaceId: _acceptedMedicalPlaceId,
      replacing: _replacingMedical,
    ))
      return;
    _searchedRadius = null;
    _searchMedicalIfNeeded();
  }

  void _cancelMedicalReplacement() {
    if (!_replacingMedical) return;
    ++_searchVersion;
    setState(() {
      _replacingMedical = false;
      _searchedRadius = null;
      _medicalResult = const AsyncSnapshot.nothing();
      selectedMedical = _acceptedMedicalFacility;
      _showMedicalCard = false;
    });
  }

  void _retryMedicalHistory() {
    _acceptedMedicalSub?.cancel();
    ++_acceptedHistoryVersion;
    _legacyHistoryChecked = false;
    _checkingLegacyHistory = false;
    setState(() {
      _acceptedMedicalReady = false;
      _acceptedMedicalHistoryError = false;
    });
    _watchAcceptedMedical();
  }

  Future<void> _loadMapIcons() async {
    try {
      final icons = await _DieuPhoiMarkerCache.load();
      if (!mounted) return;
      setState(() => _mapIcons.addAll(icons));
    } catch (_) {
      // Marker mặc định vẫn hiển thị; lần mở tiếp theo có thể thử lại.
    }
  }

  Future<void> _searchMedicalIfNeeded() async {
    if (!nenTimCoSoYTe(
      historyResolved: _acceptedMedicalReady,
      historyError: _acceptedMedicalHistoryError,
      acceptedPlaceId: _acceptedMedicalPlaceId,
      replacing: _replacingMedical,
    ))
      return;
    final radius = c.radius;
    if (_searchedRadius == radius) return;
    final request = c.request;
    if (request == null) return;
    final incident = YeuCauHoTro(widget.id, request.data);
    if (!incident.hasLocation) return;

    _searchedRadius = radius;
    final version = ++_searchVersion;
    setState(() {
      _medicalResult = const AsyncSnapshot.waiting();
      if (_acceptedMedicalPlaceId == null) {
        selectedMedical = null;
        _showMedicalCard = false;
      }
    });
    try {
      final facilities = await _medicalService.search(
        requestId: widget.id,
        radiusKm: radius,
        incidentLatitude: incident.latitude!,
        incidentLongitude: incident.longitude!,
      );
      if (!mounted ||
          version != _searchVersion ||
          !nenTimCoSoYTe(
            historyResolved: _acceptedMedicalReady,
            historyError: _acceptedMedicalHistoryError,
            acceptedPlaceId: _acceptedMedicalPlaceId,
            replacing: _replacingMedical,
          ))
        return;
      setState(() {
        _medicalResult = AsyncSnapshot.withData(
          ConnectionState.done,
          facilities,
        );
        final accepted = facilities
            .where((facility) => facility.placeId == _acceptedMedicalPlaceId)
            .firstOrNull;
        if (accepted != null) _acceptedMedicalFacility = accepted;
      });
    } catch (error, stack) {
      if (!mounted ||
          version != _searchVersion ||
          !nenTimCoSoYTe(
            historyResolved: _acceptedMedicalReady,
            historyError: _acceptedMedicalHistoryError,
            acceptedPlaceId: _acceptedMedicalPlaceId,
            replacing: _replacingMedical,
          ))
        return;
      setState(
        () => _medicalResult = AsyncSnapshot.withError(
          ConnectionState.done,
          error,
          stack,
        ),
      );
    }
  }

  @override
  void dispose() {
    c.removeListener(_searchMedicalIfNeeded);
    ++_acceptedHistoryVersion;
    _acceptedMedicalSub?.cancel();
    sheet.dispose();
    c.dispose();
    super.dispose();
  }

  void selectOnMap(String uid) {
    setState(() {
      selected = uid;
      _showMedicalCard = false;
    });
    if (sheet.isAttached && sheet.size > .25) {
      sheet.animateTo(
        .25,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void selectMedicalOnMap(CoSoYTe facility) {
    // Sau khi đã chốt nơi tiếp nhận, không cho mở thẻ trên bản đồ
    // của một cơ sở khác. Vẫn có thể gọi cơ sở khác ở bảng bên dưới.
    if (_acceptedMedicalPlaceId != null &&
        _acceptedMedicalPlaceId != facility.placeId) {
      return;
    }
    setState(() {
      selectedMedical = facility;
      _showMedicalCard = true;
    });
  }

  void _clearMapSelection(LatLng _) {
    if (selectedMedical == null && selected == null) return;
    setState(() {
      selectedMedical = null;
      selected = null;
      _showMedicalCard = false;
    });
  }

  Widget medicalMapContact(CoSoYTe facility) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              facility.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${facility.categoryLabel} · '
              '${facility.distanceKm.toStringAsFixed(2)} km',
            ),
            if (facility.address.isNotEmpty) Text(facility.address),
            const SizedBox(height: 8),
            if (_acceptedMedicalPlaceId == facility.placeId)
              const Text('Đã đồng ý tiếp nhận. Dùng mục Cơ sở y tế để gọi lại.')
            else
              CoSoYTeMapContactActions(
                key: ValueKey('medical-contact-${facility.placeId}'),
                requestId: widget.id,
                radiusKm: c.radius,
                facility: facility,
                onAccepted: _onMedicalAccepted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _dispatchTabButton(String label, IconData icon, int tab) {
    final active = _dispatchTab == tab;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _dispatchTab = tab),
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        backgroundColor: active
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        foregroundColor: active
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
    );
  }

  String _dispatchSummary() {
    final pending = c.caseInvitations
        .where(
          (row) =>
              pendingAssignmentCodes.contains(row.data['maTrangThaiTiepNhan']),
        )
        .toList();
    if (pending.isEmpty) {
      if (c.busy) return 'Đang xử lý yêu cầu…';
      return c.topRated.isEmpty
          ? 'Chưa có ứng viên sẵn sàng'
          : '${c.topRated.length} ứng viên sẵn sàng';
    }
    final seconds = pending
        .map((row) => hanLoiMoi(row.data))
        .whereType<DateTime>()
        .map(
          (deadline) =>
              deadline.difference(DateTime.now()).inSeconds.clamp(0, 180),
        )
        .toList();
    if (seconds.isEmpty)
      return 'Đã mời ${pending.length} người · Đang chờ phản hồi';
    final remaining = seconds.reduce((a, b) => a < b ? a : b);
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final secondsText = (remaining % 60).toString().padLeft(2, '0');
    final wait = ' · Còn $minutes:$secondsText';
    return 'Đã mời ${pending.length} người$wait';
  }

  Widget _mapLegend() {
    Widget item(Color color, String label, {bool route = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: route ? 18 : 8,
          height: route ? 4 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: route ? BorderRadius.circular(3) : null,
            shape: route ? BoxShape.rectangle : BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
    return Material(
      color: Colors.white.withValues(alpha: .96),
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            item(Colors.red, 'Ca cứu hộ'),
            item(Colors.blue, 'Cứu hộ'),
            item(Colors.green, 'Cơ sở y tế'),
            item(const Color(0xFF1677E8), 'Tuyến cứu hộ', route: true),
            item(const Color(0xFF8E24AA), 'Tuyến y tế', route: true),
          ],
        ),
      ),
    );
  }

  Widget mapContact(UngVienDieuPhoi user) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${user.ratingAverage?.toStringAsFixed(1) ?? '—'} / 5 sao · '
              '${user.ratingCount} đánh giá · ${user.distance.toStringAsFixed(1)} km',
            ),
            Text(user.coCCHN ? 'Có CCHN' : 'Không CCHN'),
            if (user.unit.isNotEmpty) Text(user.unit),
          ],
        ),
      ),
    );
  }

  Future<void> inviteTop3() async {
    final selected = c.topRated;
    if (selected.isEmpty) return;
    final names = selected.map((row) => row.name).join(', ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi lời mời đồng thời'),
        content: Text(
          'Gửi lời mời cùng lúc cho ${selected.length} cứu hộ viên?\n\n$names',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi đồng thời'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final count = await c.inviteTop3();
    if (!mounted) return;
    if (count != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi đồng thời $count lời mời cứu hộ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final request = c.request == null
          ? null
          : YeuCauHoTro(widget.id, c.request!.data);
      final rows = c.topRated;
      final chosen =
          rows.where((u) => u.uid == selected).firstOrNull ??
          (selected == null ? rows.firstOrNull : null);
      return PopScope(
        canPop: !c.busy,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Điều phối ${widget.id}'),
            actions: [
              if (request != null)
                IconButton(
                  tooltip: 'Nhắn tin ca cứu hộ',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ChatYeuCauScreen(maYeuCau: widget.id),
                  ),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, bounds) {
              final maxSheetSize = (1 - 64 / bounds.maxHeight)
                  .clamp(.43, .9)
                  .toDouble();
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (request != null && request.hasLocation)
                    AnimatedBuilder(
                      animation: sheet,
                      builder: (_, child) => FractionallySizedBox(
                        alignment: Alignment.topCenter,
                        heightFactor: 1 - (sheet.isAttached ? sheet.size : .42),
                        child: child,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _BanDoDieuPhoi(
                            onMapTap: _clearMapSelection,
                            origin: chosen == null
                                ? null
                                : LatLng(chosen.latitude, chosen.longitude),
                            medicalOrigin: _medicalRouteFacility == null
                                ? null
                                : LatLng(
                                    _medicalRouteFacility!.latitude,
                                    _medicalRouteFacility!.longitude,
                                  ),
                            destination: LatLng(
                              request.latitude!,
                              request.longitude!,
                            ),
                            circles: {
                              Circle(
                                circleId: const CircleId('radius'),
                                center: LatLng(
                                  request.latitude!,
                                  request.longitude!,
                                ),
                                radius: c.radius * 1000,
                                fillColor: Colors.blue.withValues(alpha: 0.08),
                                strokeColor: Colors.blue,
                                strokeWidth: 1,
                              ),
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('incident'),
                                position: LatLng(
                                  request.latitude!,
                                  request.longitude!,
                                ),
                                icon:
                                    _mapIcons['incident'] ??
                                    BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                anchor: const Offset(.5, .5),
                                zIndex: 4,
                                infoWindow: const InfoWindow(
                                  title: 'Vị trí sự cố',
                                ),
                              ),
                              for (final u in rows)
                                Marker(
                                  markerId: MarkerId(u.uid),
                                  consumeTapEvents: true,
                                  onTap: () => selectOnMap(u.uid),
                                  position: LatLng(u.latitude, u.longitude),
                                  icon: selected == u.uid
                                      ? (_mapIcons['rescuerSelected'] ??
                                            BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueOrange,
                                            ))
                                      : (_mapIcons['rescuer'] ??
                                            BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueAzure,
                                            )),
                                  anchor: const Offset(.5, .5),
                                  zIndex: selected == u.uid ? 3 : 2,
                                  infoWindow: InfoWindow(
                                    title: u.name,
                                    snippet:
                                        '${u.distance.toStringAsFixed(2)} km · '
                                        '${u.ratingAverage?.toStringAsFixed(1) ?? '—'} sao',
                                  ),
                                ),
                              for (final facility in _visibleMedicalFacilities)
                                Marker(
                                  markerId: MarkerId(
                                    'medical-${facility.placeId}',
                                  ),
                                  consumeTapEvents: true,
                                  onTap: () => selectMedicalOnMap(facility),
                                  position: LatLng(
                                    facility.latitude,
                                    facility.longitude,
                                  ),
                                  icon:
                                      (_acceptedMedicalPlaceId ??
                                              selectedMedical?.placeId) ==
                                          facility.placeId
                                      ? (_mapIcons['medicalSelected'] ??
                                            BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueGreen,
                                            ))
                                      : (_mapIcons['medical'] ??
                                            BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueGreen,
                                            )),
                                  anchor: const Offset(.5, .5),
                                  zIndex:
                                      (_acceptedMedicalPlaceId ??
                                              selectedMedical?.placeId) ==
                                          facility.placeId
                                      ? 3
                                      : 1,
                                  infoWindow: InfoWindow(
                                    title: facility.name,
                                    snippet:
                                        '${facility.categoryLabel} · '
                                        '${facility.distanceKm.toStringAsFixed(2)} km',
                                  ),
                                ),
                            },
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 64,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: _mapLegend(),
                            ),
                          ),
                          if ((_showMedicalCard && selectedMedical != null) ||
                              (!_showMedicalCard &&
                                  selected != null &&
                                  chosen != null))
                            Positioned(
                              top: 54,
                              left: 8,
                              right: 64,
                              bottom: 8,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: SingleChildScrollView(
                                  child:
                                      _showMedicalCard &&
                                          selectedMedical != null
                                      ? medicalMapContact(selectedMedical!)
                                      : mapContact(chosen!),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Align(
                      alignment: const Alignment(0, -.6),
                      child: Text(
                        request == null
                            ? 'Đang tải yêu cầu…'
                            : 'Yêu cầu chưa có vị trí',
                      ),
                    ),
                  DraggableScrollableSheet(
                    controller: sheet,
                    minChildSize: (120 / bounds.maxHeight)
                        .clamp(.19, .40)
                        .toDouble(),
                    initialChildSize: .42,
                    maxChildSize: maxSheetSize,
                    snap: true,
                    snapSizes: const [.42],
                    builder: (context, scroll) => Material(
                      elevation: 8,
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (_dispatchTab == 0 &&
                              notification.depth == 0 &&
                              notification is ScrollUpdateNotification &&
                              notification.metrics.extentAfter < 250) {
                            c.loadMore();
                          }
                          return false;
                        },
                        child: ListView(
                          controller: scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 3, 0, 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          request?.address ??
                                              'Đang tải địa chỉ ca…',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          request?.statusLabel ?? 'Đang tải',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _dispatchSummary(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475467),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _dispatchTabButton(
                                          'Cứu hộ viên',
                                          Icons.medical_services_outlined,
                                          0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _dispatchTabButton(
                                          'Cơ sở y tế',
                                          Icons.local_hospital_outlined,
                                          1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (c.error != null)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    c.error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            if (request == null)
                              const Text('Đang tải yêu cầu…')
                            else ...[
                              if (c.active &&
                                  request.text('maAdminDieuPhoi').isEmpty)
                                FilledButton.icon(
                                  onPressed: c.busy
                                      ? null
                                      : () => c.perform('claim'),
                                  icon: const Icon(
                                    Icons.assignment_ind_outlined,
                                  ),
                                  label: const Text('Nhận điều phối ca này'),
                                ),
                              if (!c.active)
                                const Text(
                                  'Ca không còn ở trạng thái cho phép điều phối.',
                                ),
                              if (c.active &&
                                  !c.mine &&
                                  request.text('maAdminDieuPhoi').isNotEmpty)
                                TenAdminDieuPhoi(
                                  request.text('maAdminDieuPhoi'),
                                  mine: false,
                                ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Bán kính',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  for (final km in const [1, 3, 5])
                                    Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: ChoiceChip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text('$km km'),
                                        selected: c.radius == km,
                                        onSelected: (_) {
                                          if (c.radius == km) return;
                                          selected = null;
                                          selectedMedical =
                                              _acceptedMedicalFacility;
                                          _showMedicalCard = false;
                                          c.searchRadius(km.toDouble());
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              if (_dispatchTab == 0) ...[
                                if (c.assignmentError != null)
                                  ListTile(
                                    title: Text(c.assignmentError!),
                                    trailing: TextButton(
                                      onPressed: c.retryAssignments,
                                      child: const Text('Thử lại'),
                                    ),
                                  ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Mời thêm người hỗ trợ'),
                                  value: c.additional,
                                  onChanged: c.pending
                                      ? null
                                      : (value) {
                                          c.additional = value;
                                          c.emit();
                                        },
                                ),
                                if (c.ratingError != null)
                                  ListTile(
                                    title: Text(c.ratingError!),
                                    trailing: TextButton(
                                      onPressed: c.loading || c.busy
                                          ? null
                                          : () => c.searchRadius(c.radius),
                                      child: const Text('Thử lại'),
                                    ),
                                  ),
                                Text(
                                  '${rows.length}/3 cứu hộ viên đủ điều kiện',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (c.loading || c.ratingsLoading)
                                  const LinearProgressIndicator(),
                                if (!c.loading &&
                                    !c.ratingsLoading &&
                                    c.ratingError == null &&
                                    rows.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Chưa tìm thấy cứu hộ viên đủ điều kiện.',
                                    ),
                                  ),
                                for (final candidate in rows)
                                  Card(
                                    margin: const EdgeInsets.only(top: 7),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(
                                        candidate.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${candidate.distance.toStringAsFixed(2)} km · '
                                        '${candidate.ratingAverage?.toStringAsFixed(1) ?? '—'} sao · '
                                        '${candidate.coCCHN ? 'Có CCHN' : 'Không CCHN'}',
                                      ),
                                      trailing: const Tooltip(
                                        message: 'Sẵn sàng nhận lời mời',
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                      onTap: () => selectOnMap(candidate.uid),
                                    ),
                                  ),
                                for (final candidate
                                    in c.visible
                                        .where((user) => !user.ready)
                                        .take(5))
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                    ),
                                    title: Text(candidate.name),
                                    subtitle: Text(
                                      '${candidate.distance.toStringAsFixed(2)} km · '
                                      '${c.reason(candidate)}',
                                    ),
                                  ),
                                if (c.mine && c.active && rows.isNotEmpty)
                                  FilledButton.icon(
                                    onPressed:
                                        c.busy ||
                                            c.pending ||
                                            c.loading ||
                                            c.ratingsLoading ||
                                            c.ratingError != null
                                        ? null
                                        : inviteTop3,
                                    icon: const Icon(Icons.send),
                                    label: Text(
                                      c.pending
                                          ? 'Đang chờ phản hồi lời mời'
                                          : 'Gửi đồng thời ${rows.length} lời mời',
                                    ),
                                  ),
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text('Lời mời và phản hồi'),
                                  children: [_LichSuMoi(widget.id, c)],
                                ),
                              ],
                              if (_acceptedMedicalHistoryError &&
                                  _dispatchTab == 1)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Không kiểm tra được lịch sử tiếp nhận',
                                  ),
                                  subtitle: const Text(
                                    'Tạm dừng tìm cơ sở để tránh bỏ qua bệnh viện đã đồng ý.',
                                  ),
                                  trailing: TextButton(
                                    onPressed: _retryMedicalHistory,
                                    child: const Text('Thử lại'),
                                  ),
                                ),
                              // Giữ panel trong cây widget khi đổi tab: không mất
                              // marker và không truy vấn lại cơ sở y tế mỗi lần.
                              Offstage(
                                offstage: _dispatchTab != 1,
                                child:
                                    _acceptedMedicalHistoryError &&
                                        _acceptedMedicalPlaceId == null
                                    ? const SizedBox.shrink()
                                    : !_acceptedMedicalReady &&
                                          _acceptedMedicalPlaceId == null
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Đang kiểm tra nơi tiếp nhận đã ghi nhận…',
                                        ),
                                      )
                                    : request.hasLocation
                                    ? CoSoYTePanel(
                                        requestId: widget.id,
                                        result: _medicalResult,
                                        radiusKm: c.radius,
                                        selectedPlaceId:
                                            selectedMedical?.placeId,
                                        acceptedPlaceId:
                                            _acceptedMedicalPlaceId,
                                        acceptedFacility:
                                            _acceptedMedicalFacility,
                                        acceptedName: _acceptedMedicalName,
                                        replacing: _replacingMedical,
                                        onRequestReplace:
                                            _acceptedMedicalReady &&
                                                !_acceptedMedicalHistoryError
                                            ? _requestMedicalReplacement
                                            : null,
                                        onCancelReplace:
                                            _cancelMedicalReplacement,
                                        onRetrySearch: _retryMedicalSearch,
                                        onFacilitySelected:
                                            _acceptedMedicalPlaceId == null
                                            ? selectMedicalOnMap
                                            : null,
                                        onAccepted: _onMedicalAccepted,
                                      )
                                    : const Text('Ca chưa có tọa độ hợp lệ.'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class _BanDoDieuPhoi extends StatefulWidget {
  final LatLng? origin;
  final LatLng? medicalOrigin;
  final LatLng destination;
  final Set<Circle> circles;
  final Set<Marker> markers;

  final ValueChanged<LatLng> onMapTap;

  const _BanDoDieuPhoi({
    required this.onMapTap,
    required this.origin,
    required this.medicalOrigin,
    required this.destination,
    required this.circles,
    required this.markers,
  });

  @override
  State<_BanDoDieuPhoi> createState() => _BanDoDieuPhoiState();
}

class _BanDoDieuPhoiState extends State<_BanDoDieuPhoi> {
  final client = http.Client();
  Timer? timer;
  int generation = 0;
  List<LatLng> rescuePoints = [];
  List<LatLng> medicalPoints = [];
  bool rescueFailed = false;
  bool medicalFailed = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didUpdateWidget(_BanDoDieuPhoi old) {
    super.didUpdateWidget(old);
    if (old.origin != widget.origin ||
        old.medicalOrigin != widget.medicalOrigin ||
        old.destination != widget.destination) {
      refresh();
    }
  }

  Future<List<LatLng>?> _tryRoute(LatLng from, LatLng to) async {
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.longitude},${from.latitude};'
            '${to.longitude},${to.latitude}',
        {'overview': 'full', 'geometries': 'geojson'},
      );
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const FormatException('OSRM request failed.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw const FormatException('OSRM returned no route.');
      }
      final geometry = routes.first['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      final path = coordinates
          .map(
            (point) => LatLng(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            ),
          )
          .toList();
      if (path.length < 2) {
        throw const FormatException('OSRM route is too short.');
      }
      return path;
    } catch (_) {
      return null;
    }
  }

  void refresh() {
    final token = ++generation;
    timer?.cancel();
    rescuePoints = [];
    medicalPoints = [];
    rescueFailed = false;
    medicalFailed = false;

    final rescueStart = widget.origin;
    final medicalStart = widget.medicalOrigin;
    final destination = widget.destination;
    if ((rescueStart == null || rescueStart == destination) &&
        (medicalStart == null || medicalStart == destination)) {
      return;
    }

    timer = Timer(const Duration(milliseconds: 350), () async {
      final rescueFuture = rescueStart == null || rescueStart == destination
          ? Future<List<LatLng>?>.value(null)
          : _tryRoute(rescueStart, destination);
      final medicalFuture = medicalStart == null || medicalStart == destination
          ? Future<List<LatLng>?>.value(null)
          : _tryRoute(medicalStart, destination);

      final results = await Future.wait([rescueFuture, medicalFuture]);
      if (!mounted || generation != token) return;

      final rescuePath = results[0];
      final medicalPath = results[1];
      setState(() {
        rescuePoints = rescuePath ?? [];
        medicalPoints = medicalPath ?? [];
        rescueFailed =
            rescueStart != null &&
            rescueStart != destination &&
            rescuePath == null;
        medicalFailed =
            medicalStart != null &&
            medicalStart != destination &&
            medicalPath == null;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      KhungBanDo(
        onMapTap: widget.onMapTap,
        dispatch: true,
        markers: widget.markers,
        circles: widget.circles,
        polylines: {
          if (medicalPoints.length >= 2) ...[
            Polyline(
              polylineId: const PolylineId('medical_route_casing'),
              points: medicalPoints,
              color: Colors.white,
              width: 9,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              zIndex: 1,
            ),
            Polyline(
              polylineId: const PolylineId('medical_route'),
              points: medicalPoints,
              color: const Color(0xFF8E24AA),
              width: 5,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              zIndex: 2,
            ),
          ],
          if (rescuePoints.length >= 2) ...[
            Polyline(
              polylineId: const PolylineId('rescue_route_casing'),
              points: rescuePoints,
              color: Colors.white,
              width: 9,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              zIndex: 3,
            ),
            Polyline(
              polylineId: const PolylineId('rescue_route'),
              points: rescuePoints,
              color: const Color(0xFF1677E8),
              width: 5,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              zIndex: 4,
            ),
          ],
        },
      ),
      if (rescueFailed || medicalFailed)
        Positioned(
          top: 64,
          left: 8,
          child: ActionChip(
            label: Text(
              rescueFailed && medicalFailed
                  ? 'Chưa tải được 2 tuyến · Thử lại'
                  : rescueFailed
                  ? 'Chưa tải được tuyến cứu hộ · Thử lại'
                  : 'Chưa tải được tuyến y tế · Thử lại',
            ),
            onPressed: () => setState(refresh),
          ),
        ),
    ],
  );
}

class TenAdminDieuPhoi extends StatefulWidget {
  final String uid;
  final bool mine;
  final String label;
  TenAdminDieuPhoi(
    this.uid, {
    required this.mine,
    this.label = 'Admin phụ trách',
  }) : super(key: ValueKey(uid));

  @override
  State<TenAdminDieuPhoi> createState() => _TenAdminDieuPhoiState();
}

class _TenAdminDieuPhoiState extends State<TenAdminDieuPhoi> {
  late final profile = FirebaseFirestore.instance
      .collection('Admin')
      .doc(widget.uid)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) return Text('${widget.label}: Chưa nhận');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profile,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = '${data?['hoTen'] ?? ''}'.trim();
        final email = '${data?['email'] ?? ''}'.trim();
        final label = name.isNotEmpty
            ? name
            : email.isNotEmpty
            ? email
            : snapshot.connectionState == ConnectionState.waiting
            ? '…'
            : 'Quản trị viên';
        final compact = widget.label != 'Admin phụ trách';
        return Text(
          '${widget.label}: $label${widget.mine ? ' (bạn)' : ''}',
          maxLines: compact ? 1 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: compact
              ? const TextStyle(fontSize: 12, color: Color(0xFF64748B))
              : null,
        );
      },
    );
  }
}

class _TenNguoiDuocMoi extends StatefulWidget {
  final String uid;
  _TenNguoiDuocMoi(this.uid) : super(key: ValueKey(uid));

  @override
  State<_TenNguoiDuocMoi> createState() => _TenNguoiDuocMoiState();
}

class _TenNguoiDuocMoiState extends State<_TenNguoiDuocMoi> {
  late final profile = FirebaseFirestore.instance
      .collection('NguoiDung')
      .doc(widget.uid)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) return const Text('Người được mời: Chưa có');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profile,
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['hoTen']?.toString().trim();
        final label = name != null && name.isNotEmpty
            ? name
            : snapshot.connectionState == ConnectionState.waiting
            ? '…'
            : 'Chưa có tên';
        return Text('Người được mời: $label');
      },
    );
  }
}

class _LichSuMoi extends StatefulWidget {
  final String id;
  final DieuPhoiController c;
  const _LichSuMoi(this.id, this.c);
  @override
  State<_LichSuMoi> createState() => _LichSuMoiState();
}

class _LichSuMoiState extends State<_LichSuMoi> {
  int limit = 10;
  late var stream = query();
  Stream<QuerySnapshot<Map<String, dynamic>>> query() => FirebaseFirestore
      .instance
      .collectionGroup('DanhSachPhanCong')
      .where('maYeuCau', isEqualTo: widget.id)
      .limit(limit + 1)
      .snapshots();

  DateTime? date(Object? raw) => raw is Timestamp
      ? raw.toDate()
      : raw is String
      ? DateTime.tryParse(raw)
      : null;

  String time(DateTime? value) {
    if (value == null) return 'Chưa ghi nhận';
    final v = value.toUtc().add(const Duration(hours: 7));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(v.hour)}:${two(v.minute)} · ${two(v.day)}/${two(v.month)}/${v.year}';
  }

  Future<void> cancel(String attempt, String path) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lời mời này?'),
        content: const Text(
          'Chỉ hủy lời mời của người cứu hộ này. Yêu cầu SOS vẫn mở và các lời mời khác không bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy lời mời'),
          ),
        ],
      ),
    );
    if (mounted && ok == true) {
      await widget.c.perform(
        'cancel',
        expectedInvitation: attempt,
        expectedInvitationPath: path,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TextButton(
              onPressed: () => setState(() => stream = query()),
              child: const Text('Không tải được lời mời · Thử lại'),
            );
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final docs = snapshot.data!.docs;
          final rows = <Map<String, dynamic>>[];
          for (final doc in docs.take(limit)) {
            final data = doc.data();
            for (final row
                in (data['lichSuLoiMoi'] as List? ?? const [])
                    .whereType<Map>()) {
              rows.add({
                ...Map<String, dynamic>.from(row),
                'uid': data['maNguoiCuuHo'],
              });
            }
            rows.add({
              ...data,
              'uid': data['maNguoiCuuHo'],
              'current': true,
              'path': doc.reference.path,
            });
          }
          rows.sort(
            (a, b) => (date(b['thoiGianGui'])?.millisecondsSinceEpoch ?? 0)
                .compareTo(date(a['thoiGianGui'])?.millisecondsSinceEpoch ?? 0),
          );
          final c = widget.c;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lời mời đã gửi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (rows.isEmpty) const Text('Ca này chưa có lời mời.'),
              for (final row in rows) ...[
                const Divider(),
                _TenNguoiDuocMoi(row['uid']?.toString() ?? ''),
                Text('Gửi lúc: ${time(date(row['thoiGianGui']))}'),
                Text(
                  row['lyDoKetThuc'] == 'het_han'
                      ? 'Hết hạn lời mời'
                      : assignmentLabel(row['maTrangThaiTiepNhan']),
                ),
                if (row['thoiGianPhanHoi'] != null)
                  Text('Phản hồi: ${time(date(row['thoiGianPhanHoi']))}'),
                if (row['current'] == true &&
                    pendingAssignmentCodes.contains(
                      row['maTrangThaiTiepNhan'],
                    )) ...[
                  if (hanLoiMoi(row) != null)
                    Text(
                      'Còn ${hanLoiMoi(row)!.difference(DateTime.now()).inSeconds.clamp(0, 180)} giây phản hồi',
                    ),
                  if (c.mine && c.active)
                    TextButton(
                      onPressed: c.busy
                          ? null
                          : () => cancel(
                              row['maPhanCong'] as String,
                              row['path'] as String,
                            ),
                      child: const Text('Hủy lời mời này'),
                    ),
                ],
              ],
              if (docs.length > limit)
                TextButton(
                  onPressed: () => setState(() {
                    limit += 10;
                    stream = query();
                  }),
                  child: const Text('Xem thêm lời mời'),
                ),
            ],
          );
        },
      ),
    ),
  );
}
