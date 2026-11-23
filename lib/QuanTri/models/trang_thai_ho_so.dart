const firebaseProfileStatusCodes = {
  'cho_duyet': 'cuuho_trangthai_hoso_tiepnhan',
  'da_duyet': 'cuuho_trangthai_hoso_daduyet',
  'tu_choi': 'cuuho_trangthai_tuchoi',
  'can_bo_sung': 'cuuho_trangthai_hoso_canbosung',
};

String normalizeProfileStatus(Object? value) {
  final raw = value is String ? value.trim() : '';
  const aliases = {
    'CHO_DUYET': 'cho_duyet',
    'cuuho_trangthai_tiepnhan': 'cho_duyet',
    'cuuho_trangthai_hoso_tiepnhan': 'cho_duyet',
    'cuuho_trangthai_daduyet': 'da_duyet',
    'cuuho_trangthai_hoso_daduyet': 'da_duyet',
    'cuuho_trangthai_tuchoi': 'tu_choi',
    'cuuho_trangthai_canbosung': 'can_bo_sung',
    'cuuho_trangthai_hoso_canbosung': 'can_bo_sung',
  };
  if (aliases.containsKey(raw)) return aliases[raw]!;
  for (final entry in firebaseProfileStatusCodes.entries) {
    if (entry.value == raw) return entry.key;
  }
  return raw;
}

String firebaseProfileStatus(String value) =>
    firebaseProfileStatusCodes[normalizeProfileStatus(value)] ?? value;

String verificationNextStatus(String action) {
  const statuses = {
    'approve': 'da_duyet',
    'reject': 'tu_choi',
    'supplement': 'can_bo_sung',
  };
  final status = statuses[action];
  if (status == null) throw StateError('Thao tác không hợp lệ.');
  return firebaseProfileStatus(status);
}
