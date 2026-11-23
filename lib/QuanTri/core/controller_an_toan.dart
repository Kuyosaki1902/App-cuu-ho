import 'luong_truc_tiep.dart';
import 'package:flutter/foundation.dart';

class ControllerAnToan extends ChangeNotifier {
  bool disposed = false;
  final luong = PhienTheoDoi();
  void emit() {
    if (!disposed) notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    luong.dispose();
    super.dispose();
  }
}
