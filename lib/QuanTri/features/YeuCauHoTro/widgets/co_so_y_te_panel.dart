import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _ketQuaLienHe = <String, String>{
  'da_tiep_nhan': 'Đã liên hệ – cơ sở đồng ý tiếp nhận',
  'khong_tiep_nhan': 'Đã liên hệ – cơ sở không tiếp nhận',
  'khong_nghe_may': 'Không nghe máy',
  'khong_lien_lac_duoc': 'Số điện thoại không liên lạc được',
  'hen_goi_lai': 'Hẹn gọi lại',
  'khac': 'Kết quả khác',
};

class CoSoYTe {
  final String placeId;
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const CoSoYTe({
    required this.placeId,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  String get id => placeId;

  String get categoryLabel {
    switch (category) {
      case 'hospital':
      case 'general_hospital':
        return 'Bệnh viện';
      case 'medical_clinic':
      case 'medical_center':
        return 'Phòng khám / trung tâm y tế';
      case 'doctor':
        return 'Phòng khám bác sĩ';
      default:
        return 'Cơ sở y tế';
    }
  }
}

/// Đọc lựa chọn gần nhất từ lịch sử, không tự tìm lại Google Places.
/// Một số bản ghi cũ có tọa độ/tên; Places v2 chỉ lưu Place ID.
Map<String, dynamic>? coSoYTeBanGhiDongYMoiNhat(
  Iterable<Map<String, dynamic>> history,
) {
  DateTime? latestTime;
  Map<String, dynamic>? selected;
  for (final row in history) {
    if (row['ketQuaLienHe'] != 'da_tiep_nhan') continue;
    final placeId = (row['maCoSoYTe'] ?? '').toString().trim();
    if (placeId.isEmpty) continue;
    final raw = row['thoiGian'];
    final time = raw is Timestamp
        ? raw.toDate()
        : raw is DateTime
        ? raw
        : null;
    if (selected == null ||
        (time != null && (latestTime == null || time.isAfter(latestTime)))) {
      selected = row;
      latestTime = time;
    }
  }
  return selected;
}

String? coSoYTeDongYTiepNhanMoiNhat(Iterable<Map<String, dynamic>> history) =>
    coSoYTeBanGhiDongYMoiNhat(history)?['maCoSoYTe']?.toString();

/// Backend đã ghi kết quả nhưng listener có thể còn trả snapshot cũ.
/// Không để snapshot đó xóa lựa chọn vừa chốt hoặc bật lại Nearby Search.
bool dangChoLichSuXacNhan({
  required String? pendingPlaceId,
  required Iterable<Map<String, dynamic>> history,
}) =>
    pendingPlaceId != null &&
    !history.any(
      (row) =>
          row['ketQuaLienHe'] == 'da_tiep_nhan' &&
          row['maCoSoYTe']?.toString().trim() == pendingPlaceId,
    );

/// Chỉ phát sinh tìm kiếm sau khi lịch sử được xác định và Admin chưa
/// chốt cơ sở, hoặc đã chủ động yêu cầu thay đổi nơi tiếp nhận.
bool nenTimCoSoYTe({
  required bool historyResolved,
  required bool historyError,
  required String? acceptedPlaceId,
  required bool replacing,
}) =>
    historyResolved && !historyError && (acceptedPlaceId == null || replacing);

/// Khôi phục marker từ lịch sử chỉ khi thực sự có tọa độ hợp lệ.
/// Không dùng (0,0) làm marker thay thế trong trường hợp Places v2.
CoSoYTe? coSoYTeTuLichSu(Map<String, dynamic>? row) {
  if (row == null) return null;
  final id = (row['maCoSoYTe'] ?? '').toString().trim();
  final lat = row['viDo'];
  final lng = row['kinhDo'];
  if (id.isEmpty ||
      lat is! num ||
      lng is! num ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180 ||
      (lat == 0 && lng == 0))
    return null;
  return CoSoYTe(
    placeId: id,
    name: ((row['tenCoSoYTe'] ?? '').toString().trim().isNotEmpty)
        ? row['tenCoSoYTe'].toString().trim()
        : 'Cơ sở y tế đã tiếp nhận',
    address: row['diaChi']?.toString() ?? '',
    category: '',
    latitude: lat.toDouble(),
    longitude: lng.toDouble(),
    distanceKm: (row['khoangCachKm'] is num)
        ? (row['khoangCachKm'] as num).toDouble()
        : 0,
  );
}

/// Nếu một cơ sở đã đồng ý, chỉ trả về cơ sở đó cho lớp marker y tế.
/// Marker hiện trường và cứu hộ viên được quản lý ở lớp riêng.
List<CoSoYTe> coSoYTeHienThiTrenBanDo({
  required List<CoSoYTe> facilities,
  required String? acceptedPlaceId,
  CoSoYTe? acceptedFacility,
}) {
  if (acceptedPlaceId == null) return facilities;
  final found = facilities
      .where((f) => f.placeId == acceptedPlaceId)
      .firstOrNull;
  final chosen =
      found ??
      (acceptedFacility?.placeId == acceptedPlaceId ? acceptedFacility : null);
  return chosen == null ? const <CoSoYTe>[] : <CoSoYTe>[chosen];
}

class CoSoYTeContact {
  final String phone;
  final String contactToken;

  const CoSoYTeContact({required this.phone, required this.contactToken});
}

/// Tính khoảng cách từ ca cứu hộ tới cơ sở y tế khi Places v2
/// chỉ trả tọa độ mà không có sẵn `distanceKm`.
double khoangCachCoSoYTeKm(
  double incidentLatitude,
  double incidentLongitude,
  double latitude,
  double longitude,
) {
  const earthRadiusKm = 6371.0;
  double rad(double value) => value * math.pi / 180.0;
  final dLat = rad(latitude - incidentLatitude);
  final dLon = rad(longitude - incidentLongitude);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(incidentLatitude)) *
          math.cos(rad(latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.sqrt(a.toDouble().clamp(0.0, 1.0)));
}

class CoSoYTeService {
  static final Map<String, Future<CoSoYTeContact>> _inFlightContacts = {};
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  Future<List<CoSoYTe>> search({
    required String requestId,
    required double radiusKm,
    required double incidentLatitude,
    required double incidentLongitude,
  }) async {
    final response = await _functions
        .httpsCallable(
          'adminTimCoSoYTe',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
        )
        .call({'maYeuCau': requestId, 'radiusKm': radiusKm});

    final data = Map<String, dynamic>.from(response.data as Map);
    final rawPlaces = data['places'];
    if (rawPlaces is! List) {
      throw const FormatException('Dữ liệu Google Places không hợp lệ.');
    }

    return rawPlaces
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .where(
          (raw) =>
              raw['placeId'] is String &&
              raw['name'] is String &&
              raw['latitude'] is num &&
              raw['longitude'] is num,
        )
        .map(
          (raw) => CoSoYTe(
            placeId: raw['placeId'] as String,
            name: raw['name'] as String,
            address: raw['address']?.toString() ?? '',
            category: raw['category']?.toString() ?? '',
            latitude: (raw['latitude'] as num).toDouble(),
            longitude: (raw['longitude'] as num).toDouble(),
            distanceKm: raw['distanceKm'] is num
                ? (raw['distanceKm'] as num).toDouble()
                : khoangCachCoSoYTeKm(
                    incidentLatitude,
                    incidentLongitude,
                    (raw['latitude'] as num).toDouble(),
                    (raw['longitude'] as num).toDouble(),
                  ),
          ),
        )
        .toList();
  }

  Future<CoSoYTeContact> loadContactDetails({
    required String requestId,
    required CoSoYTe facility,
    required double radiusKm,
  }) async {
    return loadContactByPlaceId(
      requestId: requestId,
      placeId: facility.placeId,
      radiusKm: radiusKm,
    );
  }

  /// Lấy số theo Place ID khi Admin chủ động bấm Gọi lại; không tìm
  /// toàn bộ danh sách trong bán kính và không tự động gọi khi mở màn.
  Future<CoSoYTeContact> loadContactByPlaceId({
    required String requestId,
    required String placeId,
    required double radiusKm,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = '$uid|$requestId|$placeId|$radiusKm';
    final previous = _inFlightContacts[key];
    if (previous != null) return previous;
    final task = _requestContactDetails(
      requestId: requestId,
      placeId: placeId,
      radiusKm: radiusKm,
    );
    _inFlightContacts[key] = task;
    try {
      return await task;
    } finally {
      if (identical(_inFlightContacts[key], task)) {
        _inFlightContacts.remove(key);
      }
    }
  }

  Future<CoSoYTeContact> _requestContactDetails({
    required String requestId,
    required String placeId,
    required double radiusKm,
  }) async {
    final response = await _functions
        .httpsCallable(
          'adminLayThongTinLienHeCoSoYTe',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
        )
        .call({
          'maYeuCau': requestId,
          'placeId': placeId,
          'radiusKm': radiusKm,
        });
    final data = Map<String, dynamic>.from(response.data as Map);
    return CoSoYTeContact(
      phone: data['phone']?.toString() ?? '',
      contactToken: data['contactToken']?.toString() ?? '',
    );
  }

  Future<void> recordContact({
    required String requestId,
    required CoSoYTe facility,
    required String contactToken,
    required String result,
    required String note,
  }) async {
    await _functions.httpsCallable('adminGhiNhanLienHeCoSoYTe').call({
      'maYeuCau': requestId,
      'placeId': facility.placeId,
      'contactToken': contactToken,
      'ketQuaLienHe': result,
      'ghiChu': note,
    });
  }
}

class CoSoYTeMapContactActions extends StatefulWidget {
  final String requestId;
  final double radiusKm;
  final CoSoYTe facility;
  final ValueChanged<CoSoYTe>? onAccepted;

  const CoSoYTeMapContactActions({
    super.key,
    required this.requestId,
    required this.radiusKm,
    required this.facility,
    this.onAccepted,
  });

  @override
  State<CoSoYTeMapContactActions> createState() =>
      _CoSoYTeMapContactActionsState();
}

class _CoSoYTeMapContactActionsState extends State<CoSoYTeMapContactActions> {
  final CoSoYTeService _service = CoSoYTeService();
  CoSoYTeContact? _contact;
  bool _loading = false;
  bool _calling = false;
  bool _saving = false;
  int _selectionGeneration = 0;

  String get _selectionKey =>
      '${widget.requestId}|${widget.facility.placeId}|${widget.radiusKm}';

  @override
  void didUpdateWidget(covariant CoSoYTeMapContactActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId != widget.requestId ||
        oldWidget.radiusKm != widget.radiusKm ||
        oldWidget.facility.placeId != widget.facility.placeId) {
      ++_selectionGeneration;
      _contact = null;
      _loading = false;
      _calling = false;
      _saving = false;
    }
  }

  @override
  void dispose() {
    ++_selectionGeneration;
    super.dispose();
  }

  Future<void> _loadContact() async {
    if (_loading) return;
    final key = _selectionKey;
    final generation = ++_selectionGeneration;
    setState(() => _loading = true);
    try {
      final details = await _service.loadContactDetails(
        requestId: widget.requestId,
        facility: widget.facility,
        radiusKm: widget.radiusKm,
      );
      if (!mounted ||
          generation != _selectionGeneration ||
          key != _selectionKey)
        return;
      setState(() => _contact = details);
      if (details.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Places không cung cấp số điện thoại cho cơ sở này.',
            ),
          ),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted &&
          generation == _selectionGeneration &&
          key == _selectionKey) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Không lấy được số điện thoại.'),
          ),
        );
      }
    } catch (_) {
      if (mounted &&
          generation == _selectionGeneration &&
          key == _selectionKey) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được thông tin liên hệ.')),
        );
      }
    } finally {
      if (mounted &&
          generation == _selectionGeneration &&
          key == _selectionKey) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _call() async {
    final details = _contact;
    if (_calling || details == null || details.phone.isEmpty) return;
    setState(() => _calling = true);
    try {
      final normalized = details.phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: normalized),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được trình gọi điện.')),
        );
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  Future<void> _recordResult() async {
    final selectionKey = _selectionKey;
    final details = _contact;
    if (_saving ||
        details == null ||
        details.phone.isEmpty ||
        details.contactToken.isEmpty) {
      return;
    }

    String? selected;
    final note = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ghi nhận kết quả liên hệ'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.facility.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SelectableText(details.phone),
                  const SizedBox(height: 8),
                  for (final entry in _ketQuaLienHe.entries)
                    RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: entry.key,
                      groupValue: selected,
                      title: Text(entry.value),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selected = value);
                        }
                      },
                    ),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      'result': selected!,
                      'note': note.text.trim(),
                    }),
              child: const Text('Lưu kết quả'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
    if (result == null || !mounted || selectionKey != _selectionKey) return;

    setState(() => _saving = true);
    try {
      await _service.recordContact(
        requestId: widget.requestId,
        facility: widget.facility,
        contactToken: details.contactToken,
        result: result['result']!,
        note: result['note'] ?? '',
      );
      // Chỉ chốt marker sau khi Cloud Function xác nhận ghi thành công.
      if (mounted && selectionKey == _selectionKey) {
        if (result['result'] == 'da_tiep_nhan') {
          widget.onAccepted?.call(widget.facility);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kết quả liên hệ cơ sở y tế.')),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Không lưu được kết quả liên hệ.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lưu được kết quả liên hệ.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _contact;
    final hasPhone = details?.phone.isNotEmpty == true;
    final canRecord = hasPhone && details!.contactToken.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            FilledButton.icon(
              onPressed: _loading ? null : _loadContact,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.contact_phone),
              label: Text(_loading ? 'Đang lấy số…' : 'Liên hệ'),
            ),
            if (hasPhone)
              OutlinedButton.icon(
                onPressed: _calling ? null : _call,
                icon: const Icon(Icons.call),
                label: const Text('Gọi điện'),
              ),
            if (hasPhone)
              TextButton.icon(
                onPressed: _saving || !canRecord ? null : _recordResult,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_note),
                label: const Text('Ghi kết quả'),
              ),
          ],
        ),
        if (hasPhone) ...[
          const SizedBox(height: 4),
          SelectableText(
            details!.phone,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class CoSoYTePanel extends StatefulWidget {
  final String requestId;
  final AsyncSnapshot<List<CoSoYTe>> result;
  final double radiusKm;
  final String? selectedPlaceId;
  final ValueChanged<CoSoYTe>? onFacilitySelected;
  final ValueChanged<CoSoYTe>? onAccepted;
  final String? acceptedPlaceId;
  final CoSoYTe? acceptedFacility;
  final String? acceptedName;
  final bool replacing;
  final VoidCallback? onRequestReplace;
  final VoidCallback? onCancelReplace;
  final VoidCallback? onRetrySearch;

  const CoSoYTePanel({
    super.key,
    required this.requestId,
    required this.result,
    required this.radiusKm,
    this.selectedPlaceId,
    this.onFacilitySelected,
    this.onAccepted,
    this.acceptedPlaceId,
    this.acceptedFacility,
    this.acceptedName,
    this.replacing = false,
    this.onRequestReplace,
    this.onCancelReplace,
    this.onRetrySearch,
  });

  @override
  State<CoSoYTePanel> createState() => _CoSoYTePanelState();
}

class _CoSoYTePanelState extends State<CoSoYTePanel> {
  final CoSoYTeService _service = CoSoYTeService();
  bool _callingAccepted = false;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _watchRecentHistory(widget.requestId);
  }

  @override
  void didUpdateWidget(covariant CoSoYTePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId != widget.requestId) {
      _historyStream = _watchRecentHistory(widget.requestId);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchRecentHistory(
    String requestId,
  ) => FirebaseFirestore.instance
      .collection('YeuCauCuuHo')
      .doc(requestId)
      .collection('LichSuLienHeCoSoYTe')
      .orderBy('thoiGian', descending: true)
      .limit(10)
      .snapshots();

  Future<void> _callAccepted() async {
    final id = widget.acceptedPlaceId;
    if (id == null || _callingAccepted) return;
    setState(() => _callingAccepted = true);
    try {
      final details = await _service.loadContactByPlaceId(
        requestId: widget.requestId,
        placeId: id,
        // Cơ sở đã được chọn từ bán kính tối đa 5 km; thay đổi bán kính
        // tìm cứu hộ viên không được làm mất khả năng gọi lại.
        radiusKm: 5,
      );
      if (!mounted || widget.acceptedPlaceId != id) return;
      if (details.phone.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Places không cung cấp số điện thoại.'),
          ),
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            widget.acceptedFacility?.name ??
                widget.acceptedName ??
                'Cơ sở đã đồng ý tiếp nhận',
          ),
          content: SelectableText(details.phone),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.call),
              label: const Text('Gọi lại'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted || widget.acceptedPlaceId != id) return;
      final normalized = details.phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: normalized),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được trình gọi điện.')),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Không lấy được số điện thoại.'),
          ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể liên hệ cơ sở y tế lúc này.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _callingAccepted = false);
    }
  }

  Future<void> _openAcceptedMap() async {
    final placeId = widget.acceptedPlaceId;
    if (placeId == null) return;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': placeId,
      'query_place_id': placeId,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps.')),
      );
    }
  }

  Widget _acceptedView(BuildContext context) {
    final facility = widget.acceptedFacility;
    final name =
        facility?.name ??
        widget.acceptedName ??
        'Cơ sở y tế đã đồng ý tiếp nhận';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã có nơi tiếp nhận',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (facility != null && facility.address.isNotEmpty)
                  Text(facility.address),
                if (facility == null && widget.acceptedName == null)
                  Text(
                    'Google Place ID: ${widget.acceptedPlaceId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (facility != null)
                  Text(
                    '${facility.distanceKm.toStringAsFixed(2)} km từ hiện trường',
                  ),
                if (facility == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Lịch sử đã xác nhận bệnh viện nhưng chưa có tọa độ '
                      'để khôi phục ghim. Có thể xem đúng địa điểm trên Google Maps.',
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _callingAccepted ? null : _callAccepted,
                      icon: _callingAccepted
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.call),
                      label: const Text('Gọi lại'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openAcceptedMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Mở Google Maps'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: widget.onRequestReplace,
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Thay đổi cơ sở tiếp nhận'),
                ),
              ],
            ),
          ),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Lịch sử liên hệ'),
          children: [_history()],
        ),
      ],
    );
  }

  Future<void> _openMap(CoSoYTe facility) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': facility.placeId,
      'query_place_id': facility.placeId,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được Google Maps.')),
        );
      }
    }
  }

  Future<CoSoYTeContact?> _loadContact(CoSoYTe facility) async {
    try {
      return await _service.loadContactDetails(
        requestId: widget.requestId,
        facility: facility,
        radiusKm: widget.radiusKm,
      );
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Không lấy được số điện thoại.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được thông tin liên hệ.')),
        );
      }
    }
    return null;
  }

  Future<void> _call(CoSoYTe facility) async {
    final details = await _loadContact(facility);
    if (details == null || !mounted) return;
    if (details.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google không cung cấp số điện thoại cho cơ sở này.'),
        ),
      );
      return;
    }

    final normalized = details.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(facility.name),
        content: SelectableText(details.phone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.call),
            label: const Text('Gọi điện'),
          ),
        ],
      ),
    );
    if (shouldCall != true || !mounted) return;

    final opened = await launchUrl(
      Uri(scheme: 'tel', path: normalized),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được trình gọi điện.')),
      );
      return;
    }
    await _recordResult(facility, details.contactToken, details.phone);
  }

  Future<void> _recordWithoutCall(CoSoYTe facility) async {
    final details = await _loadContact(facility);
    if (details == null || !mounted) return;
    await _recordResult(facility, details.contactToken, details.phone);
  }

  Future<void> _recordResult(
    CoSoYTe facility,
    String contactToken,
    String phone,
  ) async {
    String? selected;
    final note = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ghi nhận kết quả liên hệ'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (phone.isNotEmpty) SelectableText(phone),
                  const SizedBox(height: 8),
                  for (final entry in _ketQuaLienHe.entries)
                    RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: entry.key,
                      groupValue: selected,
                      title: Text(entry.value),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selected = value);
                        }
                      },
                    ),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      'result': selected!,
                      'note': note.text.trim(),
                    }),
              child: const Text('Lưu kết quả'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
    if (result == null || !mounted) return;
    try {
      await _service.recordContact(
        requestId: widget.requestId,
        facility: facility,
        contactToken: contactToken,
        result: result['result']!,
        note: result['note'] ?? '',
      );
      if (mounted) {
        if (result['result'] == 'da_tiep_nhan') {
          widget.onAccepted?.call(facility);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kết quả liên hệ cơ sở y tế.')),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Không lưu được kết quả liên hệ.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lưu được kết quả liên hệ.')),
        );
      }
    }
  }

  String _time(Object? raw) {
    final date = raw is Timestamp ? raw.toDate() : null;
    if (date == null) return 'Chưa rõ thời gian';
    final local = date.toUtc().add(const Duration(hours: 7));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)} · '
        '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  Future<void> _openHistoryPlace(String placeId) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': placeId,
      'query_place_id': placeId,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _history() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    key: ValueKey('medical-history-${widget.requestId}'),
    stream: _historyStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text('Chưa tải được lịch sử liên hệ.');
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Text('Chưa có lịch sử liên hệ cơ sở y tế.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Text(
            'LỊCH SỬ LIÊN HỆ',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final row in snapshot.data!.docs) ...[
            const Divider(),
            Text(
              row.data()['tenCoSoYTe']?.toString() ??
                  'Cơ sở y tế trên Google Maps',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(row.data()['tenKetQuaLienHe']?.toString() ?? ''),
            Text(
              '${_time(row.data()['thoiGian'])} · '
              'Admin ${row.data()['maAdmin'] ?? ''}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            if (row.data()['nguonDuLieu'] == 'GooglePlaces' &&
                (row.data()['maCoSoYTe'] ?? '').toString().isNotEmpty)
              TextButton(
                onPressed: () =>
                    _openHistoryPlace(row.data()['maCoSoYTe'].toString()),
                child: const Text('Mở địa điểm trên Google Maps'),
              ),
            if ((row.data()['ghiChu'] ?? '').toString().isNotEmpty)
              Text('Ghi chú: ${row.data()['ghiChu']}'),
          ],
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    // Khi đã chốt bệnh viện, tuyệt đối không hiện danh sách cũ hoặc
    // các nút lấy số/ghi kết quả của những cơ sở chưa được chọn.
    if (widget.acceptedPlaceId != null && !widget.replacing) {
      return _acceptedView(context);
    }
    final snapshot = widget.result;
    if (widget.replacing && !snapshot.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đang tìm cơ sở thay thế'),
            subtitle: const Text(
              'Bệnh viện đã đồng ý trước đó vẫn được giữ trên bản đồ.',
            ),
            trailing: TextButton(
              onPressed: widget.onCancelReplace,
              child: const Text('Hủy đổi'),
            ),
          ),
          if (snapshot.hasError) ...[
            const Text('Không tải được danh sách cơ sở y tế.'),
            TextButton.icon(
              onPressed: widget.onRetrySearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ] else
            const LinearProgressIndicator(),
          const SizedBox(height: 8),
          _history(),
        ],
      );
    }
    if (snapshot.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            snapshot.error is FirebaseFunctionsException
                ? (snapshot.error as FirebaseFunctionsException).message ??
                      'Không tải được cơ sở y tế.'
                : 'Không tải được cơ sở y tế.',
          ),
          TextButton.icon(
            onPressed: widget.onRetrySearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
          _history(),
        ],
      );
    }
    if (!snapshot.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Đang tìm cơ sở y tế trong bán kính đã chọn…'),
          ],
        ),
      );
    }

    final facilities = snapshot.data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.replacing)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Chọn cơ sở tiếp nhận thay thế'),
            subtitle: const Text(
              'Nơi tiếp nhận cũ tiếp tục được giữ đến khi cơ sở mới đồng ý.',
            ),
            trailing: TextButton(
              onPressed: widget.onCancelReplace,
              child: const Text('Hủy đổi'),
            ),
          ),
        Text(
          'Tìm thấy ${facilities.length} cơ sở y tế trong ${widget.radiusKm.toStringAsFixed(0)} km',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (facilities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Không tìm thấy cơ sở y tế trong bán kính đã chọn.'),
          ),
        for (var i = 0; i < facilities.length; i++)
          Card(
            margin: const EdgeInsets.only(top: 10),
            color: widget.selectedPlaceId == facilities[i].placeId
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            shape: widget.selectedPlaceId == facilities[i].placeId
                ? RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onFacilitySelected?.call(facilities[i]),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facilities[i].name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${facilities[i].categoryLabel} · '
                      '${facilities[i].distanceKm.toStringAsFixed(2)} km',
                    ),
                    if (facilities[i].address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(facilities[i].address),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _call(facilities[i]),
                          icon: const Icon(Icons.contact_phone),
                          label: const Text('Liên hệ'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openMap(facilities[i]),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Mở bản đồ'),
                        ),
                        TextButton.icon(
                          onPressed: () => _recordWithoutCall(facilities[i]),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Ghi kết quả'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        _history(),
      ],
    );
  }
}
