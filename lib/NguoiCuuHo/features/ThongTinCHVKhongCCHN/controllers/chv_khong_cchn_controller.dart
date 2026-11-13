import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/KyNangCuuHo/ky_nang_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/ho_so_cuu_ho_khong_cchn_model.dart';
import '../models/quiz_question.dart';

/// Các ô ảnh 1 file.
enum ImageSlot { cccdFront, cccdBack, selfie, evidence }

/// Loại minh chứng có thể kiểm chứng (cần ít nhất 1).
class EvidenceType {
  final String code;
  final String label;
  final bool needsExpiry;
  const EvidenceType(this.code, this.label, {this.needsExpiry = false});
}

const List<EvidenceType> kEvidenceTypes = [
  EvidenceType(
    'chungnhan_sococuu',
    'Chứng nhận sơ cấp cứu / BLS / CPR',
    needsExpiry: true,
  ),
  EvidenceType('thu_xacnhan_tochuc', 'Thư xác nhận của tổ chức / đội cứu hộ'),
];

const List<String> kGuarantorRelations = [
  'Đại diện tổ chức / đội cứu hộ',
  'Bác sĩ / cứu hộ viên đã được duyệt',
  'Giảng viên / người tập huấn sơ cấp cứu',
  'Khác',
];

class CuuHoVienKhongCCHNController extends ChangeNotifier {
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _cccdRegex = RegExp(r'^\d{12}$');
  static final _phoneRegex = RegExp(r'^(0|\+84)\d{9}$');

  final formKey = GlobalKey<FormState>();

  // --- Thông tin cá nhân ---
  final fullNameController = TextEditingController();
  final cccdCardNoController = TextEditingController();
  final cccdIssueDateController = TextEditingController(); // Ngày cấp
  final cccdExpiryDateController = TextEditingController(); // Ngày hết hạn
  final cccdIssuerController = TextEditingController();

  // --- Kinh nghiệm ---
  final organizationController = TextEditingController();
  final rescueTimesController = TextEditingController(text: '0');
  final customSkillsController = TextEditingController(); // tự khai
  final summaryController = TextEditingController();
  final noteController = TextEditingController();

  // --- Minh chứng ---
  String? selectedEvidenceCode;
  final evidenceExpiryController = TextEditingController();

  // --- Người bảo chứng (bắt buộc, có cấu trúc) ---
  final guarantorNameController = TextEditingController();
  final guarantorPhoneController = TextEditingController();
  final guarantorOrgController = TextEditingController();
  String? guarantorRelation;

  // --- Đồng ý ---
  bool isAgreed = false; // cam kết phạm vi sơ cấp cứu
  bool isDataConsent = false; // đồng ý xử lý dữ liệu cá nhân
  bool isSubmitting = false;

  // --- Ảnh ---
  final Map<ImageSlot, File> singlePhotos = {};
  final List<File> activityPhotos = []; // ảnh hoạt động: chỉ bổ trợ, tối đa 3
  final ImagePicker _picker = ImagePicker();

  // --- Bài kiểm tra ---
  final Map<int, int> quizAnswers = {};
  bool quizGraded = false;
  int quizScore = 0;

  // --- Danh mục ---
  String selectedExperience = '1 - 3 năm';
  final List<String> experienceOptions = [
    'Dưới 1 năm',
    '1 - 3 năm',
    '3 - 5 năm',
    'Trên 5 năm',
  ];

  /// Danh sách tổ chức đã đăng ký (tải từ collection `ToChuc`, có giá trị dự phòng).
  List<String> organizationOptions = [
    'Hội Chữ thập đỏ địa phương',
    'Đội / CLB cứu hộ tình nguyện',
    'Đội PCCC & Cứu nạn cứu hộ',
    'Tình nguyện viên độc lập (chưa thuộc tổ chức)',
  ];

  List<Map<String, String>> availableSkills = [
    {'maKyNang': 'kn_cpr', 'tenKyNang': 'Ép tim CPR'},
    {'maKyNang': 'kn_bang_bo', 'tenKyNang': 'Băng bó vết thương'},
    {'maKyNang': 'kn_co_dinh', 'tenKyNang': 'Cố định gãy xương'},
    {'maKyNang': 'kn_duoi_nuoc', 'tenKyNang': 'Sơ cứu đuối nước'},
    {'maKyNang': 'kn_bong', 'tenKyNang': 'Xử lý bỏng ban đầu'},
  ];
  List<String> selectedSkillCodes = [];

  bool _disposed = false;

  CuuHoVienKhongCCHNController({String? existingFullName}) {
    fullNameController.text = _stripMedicalTitle(existingFullName ?? '');
    cccdIssuerController.text =
        'Cục Cảnh sát quản lý hành chính về trật tự xã hội';

    for (final c in [
      cccdCardNoController,
      cccdIssueDateController,
      cccdExpiryDateController,
      cccdIssuerController,
      organizationController,
      evidenceExpiryController,
      guarantorNameController,
      guarantorPhoneController,
      guarantorOrgController,
    ]) {
      c.addListener(notifyListeners);
    }

    _loadSkillsFromFirestore();
    _loadOrganizations();
  }

  /// Nhóm không CCHN không được hiển thị danh xưng "BS.", "ThS.BS"...
  static String _stripMedicalTitle(String name) {
    return name
        .replaceFirst(
          RegExp(
            r'^\s*(bác sĩ|bs\.?\s*(ckii|cki)?\.?|ths\.?\s*bs\.?)\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Tải danh mục
  // ---------------------------------------------------------------------------
  Future<void> _loadSkillsFromFirestore() async {
    try {
      final kyNangService = KyNangService();
      await kyNangService.seedDefaultSkills();
      final skills = await kyNangService.fetchAllSkills();
      if (skills.isNotEmpty) {
        availableSkills = skills;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải kỹ năng: $e');
    }
  }

  Future<void> _loadOrganizations() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('ToChuc').get();
      final names = snap.docs
          .map((d) => (d.data()['tenToChuc'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        // Luôn giữ lựa chọn "độc lập" ở cuối.
        names.add('Tình nguyện viên độc lập (chưa thuộc tổ chức)');
        organizationOptions = names;
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        'Không tải được danh sách tổ chức, dùng danh sách mặc định: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Chọn giá trị
  // ---------------------------------------------------------------------------
  void toggleSkillCode(String code) {
    if (selectedSkillCodes.contains(code)) {
      selectedSkillCodes.remove(code);
    } else {
      selectedSkillCodes.add(code);
    }
    notifyListeners();
  }

  void setExperience(String val) {
    selectedExperience = val;
    notifyListeners();
  }

  void setEvidenceType(String code) {
    selectedEvidenceCode = code;
    if (!(evidenceType?.needsExpiry ?? false)) evidenceExpiryController.clear();
    notifyListeners();
  }

  EvidenceType? get evidenceType {
    for (final t in kEvidenceTypes) {
      if (t.code == selectedEvidenceCode) return t;
    }
    return null;
  }

  void setGuarantorRelation(String val) {
    guarantorRelation = val;
    notifyListeners();
  }

  void setAgreed(bool val) {
    isAgreed = val;
    notifyListeners();
  }

  void setDataConsent(bool val) {
    isDataConsent = val;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Ảnh
  // ---------------------------------------------------------------------------
  Future<void> pickSlot(ImageSlot slot, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600, // đủ nét để người duyệt đọc giấy tờ
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        singlePhotos[slot] = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  void removeSlot(ImageSlot slot) {
    singlePhotos.remove(slot);
    notifyListeners();
  }

  Future<void> pickActivityPhoto(ImageSource source) async {
    if (activityPhotos.length >= 3) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        activityPhotos.add(File(picked.path));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  void removeActivityPhoto(int index) {
    if (index >= 0 && index < activityPhotos.length) {
      activityPhotos.removeAt(index);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Bài kiểm tra
  // ---------------------------------------------------------------------------
  bool get quizAllAnswered => quizAnswers.length == kQuizBank.length;

  bool get quizPassed =>
      quizGraded && quizScore * 100 >= kQuizPassPercent * kQuizBank.length;

  void answerQuiz(int questionIndex, int optionIndex) {
    if (quizPassed) return; // đã đạt thì khóa lại
    quizAnswers[questionIndex] = optionIndex;
    quizGraded = false; // đổi đáp án thì phải chấm lại
    notifyListeners();
  }

  void gradeQuiz() {
    if (!quizAllAnswered) return;
    int score = 0;
    for (int i = 0; i < kQuizBank.length; i++) {
      if (quizAnswers[i] == kQuizBank[i].correctIndex) score++;
    }
    quizScore = score;
    quizGraded = true;
    notifyListeners();
  }

  void resetQuiz() {
    quizAnswers.clear();
    quizGraded = false;
    quizScore = 0;
    notifyListeners();
  }

  /// Câu nào sai (chỉ dùng để gợi ý làm lại, không lộ đáp án đúng).
  bool isQuestionWrong(int i) =>
      quizGraded && quizAnswers[i] != kQuizBank[i].correctIndex;

  // ---------------------------------------------------------------------------
  // Kiểm tra hợp lệ
  // ---------------------------------------------------------------------------
  DateTime? _parseDate(String text) {
    try {
      return _dateFmt.parseStrict(text.trim());
    } catch (_) {
      return null;
    }
  }

  String? validateCccd(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Vui lòng nhập số CCCD/Căn cước';
    if (!_cccdRegex.hasMatch(s)) return 'Số CCCD gồm đúng 12 chữ số';
    return null;
  }

  String? validateRequired(String? v, String message) =>
      (v ?? '').trim().isEmpty ? message : null;

  String? validatePhone(String? v) {
    final s = (v ?? '').trim().replaceAll(' ', '');
    if (s.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!_phoneRegex.hasMatch(s)) return 'Số điện thoại không hợp lệ';
    return null;
  }

  /// Trả về thông báo cho mục đầu tiên còn thiếu, `null` nếu đã đủ.
  String? get firstMissingMessage {
    if (fullNameController.text.trim().isEmpty) {
      return 'Thiếu họ và tên';
    }
    if (validateCccd(cccdCardNoController.text) != null) {
      return 'Vui lòng nhập đúng số CCCD (12 chữ số)';
    }
    final issue = _parseDate(cccdIssueDateController.text);
    final expiry = _parseDate(cccdExpiryDateController.text);
    if (issue == null || expiry == null) {
      return 'Vui lòng chọn ngày cấp và ngày hết hạn CCCD';
    }
    if (!expiry.isAfter(DateTime.now())) {
      return 'CCCD đã hết hạn, vui lòng dùng giấy tờ còn hiệu lực';
    }
    if (cccdIssuerController.text.trim().isEmpty) {
      return 'Vui lòng chọn cơ quan cấp CCCD';
    }
    if (singlePhotos[ImageSlot.cccdFront] == null ||
        singlePhotos[ImageSlot.cccdBack] == null) {
      return 'Vui lòng chụp CCCD mặt trước và mặt sau';
    }
    if (singlePhotos[ImageSlot.selfie] == null) {
      return 'Vui lòng chụp ảnh selfie cầm CCCD';
    }
    if (organizationController.text.trim().isEmpty) {
      return 'Vui lòng chọn đội nhóm / tổ chức';
    }
    if (evidenceType == null) {
      return 'Vui lòng chọn loại minh chứng';
    }
    if (singlePhotos[ImageSlot.evidence] == null) {
      return 'Vui lòng tải ảnh minh chứng đã chọn';
    }
    if (evidenceType!.needsExpiry) {
      final d = _parseDate(evidenceExpiryController.text);
      if (d == null) return 'Vui lòng nhập hạn sử dụng của chứng nhận';
      if (!d.isAfter(DateTime.now())) {
        return 'Chứng nhận đã hết hạn';
      }
    }
    if (guarantorNameController.text.trim().isEmpty ||
        validatePhone(guarantorPhoneController.text) != null ||
        guarantorRelation == null ||
        guarantorOrgController.text.trim().isEmpty) {
      return 'Vui lòng nhập đầy đủ thông tin người bảo chứng';
    }
    if (!quizPassed) {
      return 'Bạn cần đạt từ $kQuizPassPercent% ở bài kiểm tra năng lực';
    }
    if (!isAgreed) return 'Vui lòng tích chọn cam kết phạm vi sơ cấp cứu';
    if (!isDataConsent) {
      return 'Vui lòng đồng ý cho xử lý dữ liệu cá nhân';
    }
    return null;
  }

  bool get isFormValid => firstMissingMessage == null;

  int _parseExperienceYears(String text) {
    if (text.contains('Dưới 1 năm')) return 0;
    if (text.contains('1 - 3 năm')) return 2;
    if (text.contains('3 - 5 năm')) return 4;
    if (text.contains('Trên 5 năm')) return 5;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Gửi hồ sơ
  // ---------------------------------------------------------------------------
  Future<String> _upload(File file, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    // Chỉ lưu ĐƯỜNG DẪN, không lưu link tải có token, để Storage Rules
    // (chỉ chủ hồ sơ + người duyệt được đọc) thực sự bảo vệ ảnh CCCD.
    return ref.fullPath;
  }

  Future<bool> submitHoSoToFirebase(String currentUserId) async {
    if (!isFormValid) return false;

    isSubmitting = true;
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final base = 'HoSoCuuHoKhongCCHN/$currentUserId';

      // 1. Tải ảnh lên Firebase Storage
      final cccdFrontPath = await _upload(
        singlePhotos[ImageSlot.cccdFront]!,
        '$base/cccd_truoc_$ts.jpg',
      );
      final cccdBackPath = await _upload(
        singlePhotos[ImageSlot.cccdBack]!,
        '$base/cccd_sau_$ts.jpg',
      );
      final selfiePath = await _upload(
        singlePhotos[ImageSlot.selfie]!,
        '$base/selfie_$ts.jpg',
      );
      final evidencePath = await _upload(
        singlePhotos[ImageSlot.evidence]!,
        '$base/minhchung_$ts.jpg',
      );
      final activityPaths = <String>[];
      for (int i = 0; i < activityPhotos.length; i++) {
        activityPaths.add(
          await _upload(activityPhotos[i], '$base/hoatdong_${ts}_$i.jpg'),
        );
      }

      // 2. Kỹ năng (tự khai) vào bảng ChiTietKyNang
      await KyNangService().saveChiTietKyNang(
        maNguoiDung: currentUserId,
        danhSachMaKyNang: selectedSkillCodes,
        customSkills: customSkillsController.text.trim(),
      );

      // 3. Ghi hồ sơ + minh chứng + người bảo chứng trong 1 batch
      final now = DateTime.now();
      final batch = db.batch();

      final hoSo = HoSoCuuHoKhongCCHNModel(
        maNguoiDung: currentUserId,
        soCanCuoc: cccdCardNoController.text.trim(),
        ngayCapCanCuoc: cccdIssueDateController.text.trim(),
        ngayHetHanCanCuoc: cccdExpiryDateController.text.trim(),
        coQuanCapCanCuoc: cccdIssuerController.text.trim(),
        doiNhom: organizationController.text.trim(),
        soNamHoatDongCuuHo: _parseExperienceYears(selectedExperience),
        soLanThamGiaCuuHo: int.tryParse(rescueTimesController.text.trim()) ?? 0,
        tomTatCuuHo: summaryController.text.trim().isEmpty
            ? null
            : summaryController.text.trim(),
        ghiChu: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
        thoiGianOnline: now.toIso8601String(),
        anhCccdTruocPath: cccdFrontPath,
        anhCccdSauPath: cccdBackPath,
        anhSelfiePath: selfiePath,
        daDongYXuLyDuLieu: true,
        thoiGianDongY: now.toIso8601String(),
        diemBaiKiemTra: quizScore,
        tongCauBaiKiemTra: kQuizBank.length,
        maTrangThaiHoSo: kTrangThaiTiepNhan,
      );
      final hoSoMap = hoSo.toMap();
      // Giờ nộp lấy theo đồng hồ máy chủ, màn trạng thái dùng nó để đếm ngược.
      hoSoMap['thoiGianNop'] = FieldValue.serverTimestamp();
      batch.set(
        db.collection('HoSoCuuHoKhongCCHN').doc(currentUserId),
        hoSoMap,
      );

      // MinhChung: chính + ảnh hoạt động (bổ trợ)
      final expiry = evidenceType!.needsExpiry
          ? Timestamp.fromDate(_parseDate(evidenceExpiryController.text)!)
          : null;
      batch.set(
        db
            .collection('MinhChung')
            .doc()
            .collection('DanhSachDangKy')
            .doc(currentUserId),
        {
          'maNguoiDung': currentUserId,
          'loai': evidenceType!.code,
          'filePath': evidencePath,
          'trangThai': 'choduyet',
          'hanSuDung': expiry,
          'nguoiDuyet': null,
          'thoiGianNop': Timestamp.fromDate(now),
        },
      );
      for (final p in activityPaths) {
        batch.set(
          db
              .collection('MinhChung')
              .doc()
              .collection('DanhSachDangKy')
              .doc(currentUserId),
          {
            'maNguoiDung': currentUserId,
            'loai': 'anh_hoatdong',
            'filePath': p,
            'trangThai': 'choduyet',
            'hanSuDung': null,
            'nguoiDuyet': null,
            'thoiGianNop': Timestamp.fromDate(now),
          },
        );
      }

      // NguoiBaoChung: mã xác nhận (maXacNhan) và cờ daXacNhan do server /
      // Cloud Function tạo và cập nhật, client không tự ghi.
      batch.set(db.collection('NguoiBaoChung').doc(), {
        'maNguoiDung': currentUserId,
        'hoTen': guarantorNameController.text.trim(),
        'soDienThoai': guarantorPhoneController.text.trim().replaceAll(' ', ''),
        'quanHe': guarantorRelation,
        'toChuc': guarantorOrgController.text.trim(),
        'daXacNhan': false,
        'thoiGianTao': Timestamp.fromDate(now),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('🔴 Lỗi lưu hồ sơ: $e');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    DateTime initialDate = DateTime.now();
    final parsed = _parseDate(controller.text);
    if (parsed != null) initialDate = parsed;

    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? DateTime(2100);
    if (initialDate.isBefore(first)) initialDate = first;
    if (initialDate.isAfter(last)) initialDate = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      controller.text = _dateFmt.format(picked);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final c in [
      fullNameController,
      cccdCardNoController,
      cccdIssueDateController,
      cccdExpiryDateController,
      cccdIssuerController,
      organizationController,
      rescueTimesController,
      customSkillsController,
      summaryController,
      noteController,
      evidenceExpiryController,
      guarantorNameController,
      guarantorPhoneController,
      guarantorOrgController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
