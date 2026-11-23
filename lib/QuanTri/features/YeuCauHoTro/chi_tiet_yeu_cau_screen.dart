import 'dieu_phoi_screen.dart';
import 'chat_yeu_cau_screen.dart';
import 'services/dieu_phoi_service.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'controllers/chi_tiet_yeu_cau_controller.dart';
import '../TaiKhoan/models/tai_khoan_model.dart';
import '../../models/ban_ghi.dart';
import 'models/chi_tiet_yeu_cau_model.dart';
import 'models/dieu_phoi_model.dart';
import 'models/yeu_cau_ho_tro_model.dart';
import 'services/chi_tiet_yeu_cau_service.dart';
import 'widgets/du_lieu_lien_quan.dart';
import '../../widgets/giao_dien_tai_khoan.dart';
import 'widgets/bieu_mau_kiem_tra.dart';
import 'widgets/dong_ca_bottom_sheet.dart';
import 'widgets/ban_do_truc_tiep.dart';

DateTime? requestDate(Object? value) => value is Timestamp
    ? value.toDate()
    : value is String
    ? DateTime.tryParse(value)
    : null;

DateTime? locationUpdatedAt(Map<String, dynamic>? user) =>
    requestDate(user?['ngayCapNhatViTri']) ?? requestDate(user?['capNhatLuc']);

class ChiTietYeuCauScreen extends StatefulWidget {
  final String id;
  final NguonChiTietYeuCau? repository;
  const ChiTietYeuCauScreen({super.key, required this.id, this.repository});
  @override
  State<ChiTietYeuCauScreen> createState() => _ChiTietYeuCauScreenState();
}

class _ChiTietYeuCauScreenState extends State<ChiTietYeuCauScreen> {
  late final c = ChiTietYeuCauController(
    widget.repository ?? ChiTietYeuCauService(),
    widget.id,
  );
  bool completing = false;
  final _assignmentsAnchor = GlobalKey();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingSub;
  int? _pendingCount;

  Future<void> completeRequest() async {
    if (completing) {
      return;
    }

    final current = c.request;
    final request = YeuCauHoTro(
      widget.id,
      current?.data ?? const <String, dynamic>{},
      typeName: c.typeName,
      tenNanNhan: c.nanNhan?.text('hoTen', '') ?? '',
    );

    final confirmed = await showDongCaBottomSheet(
      context,
      requestCode: request.code,
      requestTitle: request.title,
      statusLabel: request.statusLabel,
    );

    if (!mounted || confirmed != true || completing) {
      return;
    }
    setState(() => completing = true);
    try {
      await DieuPhoiService().act(widget.id, 'complete');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã đóng ca cứu hộ.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? e.message.toString()
                  : 'Không đóng được ca. Hãy kiểm tra kết nối và quyền truy cập.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => completing = false);
    }
  }

  Timer? clock;
  @override
  void initState() {
    super.initState();
    c.start();
    // watchSelected() chỉ lấy phân công đã nhận, không bao gồm lời mời chờ.
    // Lắng nghe riêng lời mời chờ để không hiển thị sai "0 lời mời".
    _pendingSub = FirebaseFirestore.instance
        .collectionGroup('DanhSachPhanCong')
        .where('maYeuCau', isEqualTo: widget.id)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(
                () => _pendingCount = snapshot.docs
                    .where(
                      (row) => pendingAssignmentCodes.contains(
                        row.data()['maTrangThaiTiepNhan'],
                      ),
                    )
                    .length,
              );
            }
          },
          onError: (Object _) {
            if (mounted) setState(() => _pendingCount = null);
          },
        );
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    clock?.cancel();
    _pendingSub?.cancel();
    c.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    await c.start();
  }

  Future<void> contact(String phone, String mode) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (clean.isEmpty) throw StateError('Chưa có số điện thoại.');
      await const MethodChannel(
        'cuhokhancap/contact',
      ).invokeMethod<void>(mode, {'phone': clean});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không mở được ứng dụng liên hệ. Bạn có thể sao chép số điện thoại.',
          ),
        ),
      );
    }
  }

  void map() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Theo dõi vị trí ca SOS')),
        body: BanDoTrucTiep(controller: c),
      ),
    ),
  );

  Widget panel(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE3EAF2)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                switch (title) {
                  'Nạn nhân' => Icons.person_outline,
                  'Vị trí sự cố' => Icons.location_on_outlined,
                  'Vị trí hiện trường' => Icons.location_on_outlined,
                  'Danh sách phân công' => Icons.medical_services_outlined,
                  'Người hỗ trợ phụ trách' => Icons.medical_services_outlined,
                  _ => Icons.description_outlined,
                },
                size: 18,
                color: accountBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172B4D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );

  Widget info(String label, Object? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value == null || '$value'.trim().isEmpty ? 'Chưa có' : '$value',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget requestOverview(YeuCauHoTro model) {
    final statusColor = model.needsDispatch
        ? const Color(0xFFC62828)
        : model.needsCheck
        ? const Color(0xFFB66A00)
        : switch (model.status) {
            'hoan_thanh' => const Color(0xFF18734D),
            'da_huy' => Colors.blueGrey,
            'cho_tiep_nhan' => const Color(0xFF946000),
            _ => accountBlue,
          };
    final urgencyColor = model.urgencyLevel == 1
        ? const Color(0xFFC62828)
        : model.urgencyLevel == 2
        ? const Color(0xFFB66A00)
        : const Color(0xFF64748B);

    Widget chip(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.code,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              chip(model.statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            model.title,
            style: const TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  model.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (model.urgencyKey.isNotEmpty)
                chip(model.urgencyLabel, urgencyColor),
              if (model.needsDispatch && model.status != 'qua_han_dieu_phoi')
                chip('Cần điều phối', const Color(0xFFC62828)),
              if (model.needsCheck)
                chip('Cần kiểm tra', const Color(0xFFB66A00)),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFEDF1F5)),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  requestAge(model.createdAt, DateTime.now()),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (model.text('maAdminDieuPhoi').isNotEmpty)
                Flexible(
                  child: TenAdminDieuPhoi(
                    model.text('maAdminDieuPhoi'),
                    mine:
                        model.text('maAdminDieuPhoi') ==
                        FirebaseAuth.instance.currentUser?.uid,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget canhBaoCa(YeuCauHoTro model, bool needsCheck, bool stale) {
    final dispatch = model.needsDispatch;
    final active =
        model.status == 'da_phan_cong' || model.status == 'dang_cuu_ho';
    final color = dispatch
        ? const Color(0xFFDC2626)
        : needsCheck
        ? const Color(0xFFB77900)
        : active
        ? const Color(0xFF15803D)
        : accountBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                dispatch
                    ? Icons.error_outline
                    : needsCheck
                    ? Icons.schedule
                    : Icons.info_outline,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dispatch
                          ? 'Cần điều phối'
                          : needsCheck
                          ? 'Cần kiểm tra'
                          : model.statusLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (dispatch || needsCheck) ...[
                      const SizedBox(height: 4),
                      Text(
                        dispatch
                            ? model.alert
                            : (stale
                                  ? 'Vị trí đã quá 8 phút chưa cập nhật. Liên hệ người hỗ trợ để kiểm tra.'
                                  : 'Liên hệ người hỗ trợ để xác nhận tình trạng ca.'),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (dispatch) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: map,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Xem bản đồ hiện trường'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: accountTheme(context),
    child: ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final r = c.request;
        final model = YeuCauHoTro(
          widget.id,
          r?.data ?? {},
          typeName: c.typeName,
          tenNanNhan: c.nanNhan?.text('hoTen', '') ?? '',
          createdAt: r == null ? null : requestDate(r.data['thoiGianTao']),
        );
        final owner = r?.data['maAdminDieuPhoi'];
        final mayComplete =
            owner == null ||
            owner == '' ||
            owner == FirebaseAuth.instance.currentUser?.uid;
        final stale = c.people.values.any(
          (p) => staleLocation(
            locationUpdatedAt(p?.data),
            DateTime.now(),
            const Duration(minutes: 8),
          ),
        );
        final needsCheck =
            model.needsCheck || (reviewableRequest(model.status) && stale);
        final canDispatch = !model.closed && model.status != 'cho_dong';
        final assignedStatuses = phanCongTrongCa(r?.data ?? {});
        final acceptedCount = c.assignments
            .where(
              (row) => selectedAssignmentCodes.contains(
                row.data['maTrangThaiTiepNhan'],
              ),
            )
            .length;
        final pendingCount = _pendingCount;
        final hasAssignees =
            acceptedCount > 0 ||
            assignedStatuses.values.any(
              (value) => assignmentStatus(value) == 'duoc_chon',
            );
        // Trạng thái chờ đóng là tín hiệu UI; transaction vẫn kiểm tra
        // tất cả lời mời thực tế trước khi thực hiện đóng ca.
        final canClose =
            model.status == 'cho_dong' && mayComplete && pendingCount == 0;
        final showCaseAction =
            r != null &&
            !model.closed &&
            ((canDispatch && mayComplete) ||
                hasAssignees ||
                canClose ||
                (model.status == 'cho_dong' && mayComplete));

        return PopScope(
          canPop: !c.busy && !completing,
          child: Scaffold(
            bottomNavigationBar: showCaseAction
                ? SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$acceptedCount người đang xử lý · '
                            '${pendingCount == null ? 'Chưa rõ số' : pendingCount} lời mời còn chờ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: completing || c.busy
                                  ? null
                                  : canClose
                                  ? completeRequest
                                  : model.status == 'cho_dong'
                                  ? null
                                  : hasAssignees
                                  ? () {
                                      final target =
                                          _assignmentsAnchor.currentContext;
                                      if (target != null) {
                                        Scrollable.ensureVisible(
                                          target,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    }
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            DieuPhoiScreen(id: widget.id),
                                      ),
                                    ),
                              icon: Icon(
                                canClose
                                    ? Icons.lock_outline
                                    : hasAssignees
                                    ? Icons.people_outline
                                    : Icons.person_search,
                              ),
                              label: Text(
                                completing
                                    ? 'Đang đóng ca…'
                                    : canClose
                                    ? 'Đóng ca cứu hộ'
                                    : model.status == 'cho_dong'
                                    ? pendingCount == null
                                          ? 'Đang kiểm tra lời mời'
                                          : 'Đang chờ xử lý lời mời'
                                    : hasAssignees
                                    ? 'Xem phân công'
                                    : 'Điều phối',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết ${model.code}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    model.statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              actions: [
                if (r != null && canDispatch)
                  IconButton(
                    tooltip: 'Điều phối',
                    icon: const Icon(Icons.person_search),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => DieuPhoiScreen(id: widget.id),
                      ),
                    ),
                  ),
                if (r != null)
                  IconButton(
                    tooltip: 'Chat ca cứu hộ',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ChatYeuCauScreen(maYeuCau: widget.id),
                    ),
                  ),
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: c.busy ? null : reload,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: c.loading
                ? const Center(child: CircularProgressIndicator())
                : c.error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.error!),
                        TextButton(
                          onPressed: reload,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : r == null
                ? const Center(child: Text('Yêu cầu không còn tồn tại.'))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: RefreshIndicator(
                        onRefresh: c.busy ? () async {} : reload,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [
                            requestOverview(model),
                            if (needsCheck || model.needsIntervention)
                              canhBaoCa(model, needsCheck, stale),

                            panel('Liên hệ nhanh', [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final phone =
                                      c.nanNhan?.data['soDienThoai']
                                          ?.toString()
                                          .trim() ??
                                      '';
                                  final callButton = FilledButton.icon(
                                    onPressed: phone.isEmpty
                                        ? null
                                        : () => contact(phone, 'dial'),
                                    icon: const Icon(Icons.phone_outlined),
                                    label: const Text('Gọi nạn nhân'),
                                  );
                                  final mapButton = OutlinedButton.icon(
                                    onPressed: model.hasLocation ? map : null,
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('Mở bản đồ'),
                                  );
                                  if (constraints.maxWidth < 390) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        callButton,
                                        const SizedBox(height: 8),
                                        mapButton,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: callButton),
                                      const SizedBox(width: 8),
                                      Expanded(child: mapButton),
                                    ],
                                  );
                                },
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed:
                                      (c.nanNhan?.data['soDienThoai'] ?? '')
                                          .toString()
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : () => contact(
                                          c.nanNhan!.data['soDienThoai']
                                              .toString(),
                                          'sms',
                                        ),
                                  icon: const Icon(
                                    Icons.sms_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Nhắn SMS'),
                                ),
                              ),
                              if ((c.nanNhan?.data['soDienThoai'] ?? '')
                                  .toString()
                                  .trim()
                                  .isEmpty)
                                const Text(
                                  'Nạn nhân chưa có số liên hệ.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                            ]),
                            panel('Vị trí hiện trường', [
                              SizedBox(
                                height: 220,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: BanDoTrucTiep(controller: c),
                                ),
                              ),
                              const SizedBox(height: 8),
                              info('Địa điểm', model.address),
                              TextButton.icon(
                                onPressed: map,
                                icon: const Icon(Icons.fullscreen),
                                label: const Text('Mở bản đồ toàn màn hình'),
                              ),
                            ]),

                            panel('Thông tin sự cố', [
                              info(
                                'Loại yêu cầu',
                                c.typeName.isEmpty
                                    ? r.data['maLoaiYeuCau']
                                    : c.typeName,
                              ),
                              if (c.typeError != null) Text(c.typeError!),
                              info('Mức độ khẩn cấp', model.urgencyLabel),
                              info(
                                'Số người cần hỗ trợ',
                                r.data['soNguoiCanCuuHo'],
                              ),
                              info('Tạo lúc', dateText(r.data['thoiGianTao'])),
                              if (r.data['thoiGianHoanThanh'] != null)
                                info(
                                  'Hoàn thành',
                                  dateText(r.data['thoiGianHoanThanh']),
                                ),
                            ]),

                            DuLieuLienQuan(
                              key: ValueKey('descriptions-${r.id}'),
                              repository: c.repository,
                              id: r.id,
                              kind: 'descriptions',
                              initiallyExpanded: true,
                              title: 'Mô tả hiện trường',
                            ),
                            DuLieuLienQuan(
                              key: ValueKey('request-images-${r.id}'),
                              repository: c.repository,
                              id: r.id,
                              kind: 'requestImages',
                              title: 'Ảnh và tệp đính kèm',
                              initiallyExpanded: true,
                            ),

                            panel('Nạn nhân', [
                              if (c.loiNanNhan != null) Text(c.loiNanNhan!),
                              info('Họ tên', c.nanNhan?.data['hoTen']),
                              info('Mã tài khoản', maNanNhan(r.data)),
                              if (c.nanNhan?.data['soDienThoai'] != null)
                                SelectableText(
                                  'Số điện thoại: ${c.nanNhan!.data['soDienThoai']}',
                                ),
                            ]),

                            Column(
                              key: _assignmentsAnchor,
                              children: khoiHoTro(model, r),
                            ),

                            DuLieuLienQuan(
                              key: ValueKey('invitations-${r.id}'),
                              repository: c.repository,
                              id: r.id,
                              kind: 'invitations',
                              title: 'Lịch sử tìm kiếm và lời mời',
                            ),
                            DuLieuLienQuan(
                              key: ValueKey('logs-${r.id}'),
                              repository: c.repository,
                              id: r.id,
                              kind: 'logs',
                              title: 'Lịch sử kiểm tra ca',
                            ),
                            DuLieuLienQuan(
                              key: ValueKey('reviews-${r.id}'),
                              repository: c.repository,
                              id: r.id,
                              kind: 'reviews',
                              title: 'Đánh giá',
                              initiallyExpanded: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    ),
  );

  List<Widget> khoiHoTro(YeuCauHoTro model, BanGhi r) {
    final members = phanCongTrongCa(r.data);
    final active = c.assignments;
    final shown = active.map((a) => a.data['maNguoiCuuHo']).toSet();
    final remaining =
        members.entries.where((e) => !shown.contains(e.key)).toList()..sort(
          (a, b) => thuTuPhanCong(a.value).compareTo(thuTuPhanCong(b.value)),
        );
    return [
      panel('Danh sách phân công', [
        if (c.assignmentsLoading) const LinearProgressIndicator(),
        if (c.assignmentError != null) Text(c.assignmentError!),
        if (!c.assignmentsLoading &&
            c.assignmentError == null &&
            active.isEmpty &&
            !members.values.any((s) => assignmentStatus(s) == 'duoc_chon'))
          const Text('Chưa có người tiếp nhận ca.'),
        for (final a in active) helper(a),
        for (final entry in remaining)
          _ThanhVienPhanCong(
            key: ValueKey(entry.key),
            uid: entry.key,
            status: entry.value,
            repository: c.repository,
          ),
        if (c.assignments.length == 10)
          const Text(
            'Đang theo dõi tối đa 10 phân công. Xem danh sách phân công bên dưới để kiểm tra thêm.',
          ),
      ]),
      if (reviewableRequest(model.status) &&
          active.isNotEmpty &&
          c.assignmentError == null)
        BieuMauKiemTra(
          key: ValueKey(r.id),
          controller: c,
          visibleIds: active.map((row) => row.id).toSet(),
          onSaved: () {},
        ),
    ];
  }

  Widget helper(BanGhi a) {
    final uid = a.text('maNguoiCuuHo', '');
    final p = c.people[uid];
    final profile = c.profiles[uid];
    final phone = p?.text('soDienThoai', '') ?? '';
    final locationTime = locationUpdatedAt(p?.data);
    return ThePhanCong(
      uid: uid,
      name: p?.text('hoTen', uid) ?? uid,
      status: a.data['maTrangThaiTiepNhan'],
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile != null && profile.isNotEmpty) ...[
            Text(
              '${profile['loaiHoSo']} · ${normalizeProfileStatus(profile['maTrangThaiHoSo']) == 'da_duyet' ? 'Đã xác minh' : 'Chưa xác minh'}',
            ),
            if (profile['donViCongTac'] != null || profile['doiNhom'] != null)
              Text('${profile['donViCongTac'] ?? profile['doiNhom']}'),
          ],
          if (c.personErrors[uid] != null) Text(c.personErrors[uid]!),
          if (c.profileErrors[uid] != null) Text(c.profileErrors[uid]!),
          if (locationTime == null)
            const Text('Chưa có thời điểm cập nhật vị trí.')
          else
            Text(
              'Vị trí cập nhật: ${requestAge(locationTime, DateTime.now())}',
            ),
          if (phone.isNotEmpty) ...[
            SelectableText(phone),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => contact(phone, 'dial'),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Gọi điện'),
                ),
                OutlinedButton.icon(
                  onPressed: () => contact(phone, 'sms'),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Nhắn SMS'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ThanhVienPhanCong extends StatefulWidget {
  final String uid, status;
  final NguonChiTietYeuCau repository;
  const _ThanhVienPhanCong({
    super.key,
    required this.uid,
    required this.status,
    required this.repository,
  });

  @override
  State<_ThanhVienPhanCong> createState() => _ThanhVienPhanCongState();
}

class _ThanhVienPhanCongState extends State<_ThanhVienPhanCong> {
  late final person = widget.repository.watchPerson(widget.uid);

  @override
  Widget build(BuildContext context) => StreamBuilder<BanGhi?>(
    stream: person,
    builder: (context, snapshot) {
      final name = snapshot.data?.text('hoTen', '') ?? '';
      return ThePhanCong(uid: widget.uid, name: name, status: widget.status);
    },
  );
}
