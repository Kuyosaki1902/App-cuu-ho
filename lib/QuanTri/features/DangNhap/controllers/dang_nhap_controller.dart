import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../services/dang_nhap_service.dart';
import '../../YeuCauHoTro/services/thong_bao_day_service.dart';
import '../../../core/controller_an_toan.dart';

enum TrangThaiDangNhap {
  loading,
  signedOut,
  allowed,
  denied,
  verificationError,
}

class DangNhapController extends ControllerAnToan {
  final NguonDangNhap repository;
  DangNhapController(
    this.repository, {
    this.verificationTimeout = const Duration(seconds: 12),
  });

  // Offline Firestore streams may deliver cache data indefinitely without
  // throwing, so stop waiting for the FIRST server-confirmed snapshot.
  final Duration verificationTimeout;

  TrangThaiDangNhap phase = TrangThaiDangNhap.loading;
  PhienQuanTri? session;
  String? error;
  bool busy = false;
  int _generation = 0;
  String? _lastMirrorUid;
  User? _currentUser;
  Timer? _verificationTimer;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<PhienQuanTri?>? _adminSubscription;

  void start() {
    if (disposed || _authSubscription != null) return;
    _authSubscription = repository.changes.listen(
      (user) {
        if (_currentUser?.uid != user?.uid) _lastMirrorUid = null;
        _currentUser = user;
        unawaited(_verifyCurrentUser(user));
      },
      onError: (Object _) {
        if (disposed) return;
        _failVerification(
          'Không kiểm tra được phiên đăng nhập. Vui lòng thử lại.',
        );
      },
    );
  }

  /// Restart ONLY the Admin document listener for the existing authenticated
  /// UID. No password is required and the Firebase Auth session is preserved.
  void retryVerification() {
    if (disposed || phase != TrangThaiDangNhap.verificationError) return;
    // Firebase Auth is authoritative if the stored User signed out meanwhile.
    final user = repository.currentUser;
    if (user == null) {
      phase = TrangThaiDangNhap.signedOut;
      error = null;
      emit();
      return;
    }
    _currentUser = user;
    unawaited(_verifyCurrentUser(user));
  }

  Future<void> _verifyCurrentUser(User? user) async {
    final generation = ++_generation;
    _verificationTimer?.cancel();
    _verificationTimer = null;
    session = null;
    error = null;
    phase = user == null
        ? TrangThaiDangNhap.signedOut
        : TrangThaiDangNhap.loading;
    emit();

    final previous = _adminSubscription;
    _adminSubscription = null;
    try {
      await previous?.cancel();
    } catch (_) {
      // A broken previous listener must not prevent a new verification.
    }
    if (disposed || generation != _generation || user == null) return;

    try {
      _adminSubscription = repository
          .watchSession(user)
          .listen(
            (nextSession) {
              if (disposed || generation != _generation) return;
              _verificationTimer?.cancel();
              _verificationTimer = null;
              session = nextSession;
              error = null;
              phase = nextSession == null
                  ? TrangThaiDangNhap.denied
                  : TrangThaiDangNhap.allowed;
              emit();

              if (nextSession != null && _lastMirrorUid != nextSession.uid) {
                _lastMirrorUid = nextSession.uid;
                // A chat mirror failure must not revoke a server-verified admin.
                unawaited(
                  repository.syncAdminMirror().catchError((Object _) {
                    if (!disposed && generation == _generation) {
                      _lastMirrorUid = null;
                    }
                  }),
                );
              }
            },
            onError: (Object _) {
              if (disposed || generation != _generation) return;
              _failVerification(
                'Không kết nối được để xác minh quyền Admin. Hãy thử lại.',
              );
            },
            onDone: () {
              if (disposed || generation != _generation) return;
              _failVerification(
                'Kết nối xác minh quyền bị gián đoạn. Hãy thử lại.',
              );
            },
          );
      _verificationTimer = Timer(verificationTimeout, () {
        if (disposed ||
            generation != _generation ||
            phase != TrangThaiDangNhap.loading) {
          return;
        }
        _failVerification(
          'Chưa nhận được xác minh quyền từ máy chủ. Kiểm tra mạng và thử lại.',
        );
      });
    } catch (_) {
      if (disposed || generation != _generation) return;
      _failVerification(
        'Không kết nối được để xác minh quyền Admin. Hãy thử lại.',
      );
    }
  }

  void _failVerification(String message) {
    if (disposed) return;
    // Invalidate any in-flight response before cancelling its listener.
    ++_generation;
    _verificationTimer?.cancel();
    _verificationTimer = null;
    final previous = _adminSubscription;
    _adminSubscription = null;
    if (previous != null) unawaited(previous.cancel());
    session = null;
    phase = TrangThaiDangNhap.verificationError;
    error = message;
    emit();
  }

  Future<void> login(String email, String password) async {
    if (disposed || busy) return;
    if (!email.trim().contains('@') || password.isEmpty) {
      error = 'Nhập email và mật khẩu.';
      emit();
      return;
    }
    busy = true;
    error = null;
    emit();
    try {
      await repository.login(email, password);
    } catch (_) {
      error = 'Đăng nhập thất bại. Kiểm tra tài khoản, mật khẩu và mạng.';
    } finally {
      busy = false;
      emit();
    }
  }

  Future<void> logout() async {
    if (disposed) return;
    try {
      await ThongBaoDayService.instance.unregister();
      await repository.logout();
    } catch (_) {
      error = 'Không đăng xuất được. Hãy thử lại.';
      emit();
    }
  }

  @override
  void dispose() {
    ++_generation;
    _verificationTimer?.cancel();
    _authSubscription?.cancel();
    _adminSubscription?.cancel();
    super.dispose();
  }
}
