/// Mã kỳ xếp hạng (tuần ISO, tháng). Tính theo giờ Việt Nam (UTC+7) để
/// thiết bị ở múi giờ khác không ghi vào kỳ khác nhau quanh nửa đêm.
class MaKy {
  MaKy._();

  static DateTime _gioVn(DateTime d) => d.toUtc().add(const Duration(hours: 7));

  /// [năm ISO, số tuần ISO]
  static List<int> tuanIso(DateTime d) {
    final v = _gioVn(d);
    final ngay = DateTime.utc(v.year, v.month, v.day);
    final thuNam = ngay.add(Duration(days: 4 - ngay.weekday));
    final dauNam = DateTime.utc(thuNam.year, 1, 1);
    final tuan = (thuNam.difference(dauNam).inDays ~/ 7) + 1;
    return [thuNam.year, tuan];
  }

  static String tuan(DateTime d) {
    final t = tuanIso(d);
    return 'tuan_${t[0]}-W${t[1].toString().padLeft(2, '0')}';
  }

  static String thang(DateTime d) {
    final v = _gioVn(d);
    return 'thang_${v.year}-${v.month.toString().padLeft(2, '0')}';
  }

  static int soThang(DateTime d) => _gioVn(d).month;
  static int namCuaThang(DateTime d) => _gioVn(d).year;
}
