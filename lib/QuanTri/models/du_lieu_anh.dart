import 'dart:convert';
import 'dart:typed_data';

class DuLieuAnh {
  final Uint8List? bytes;
  final String? url;
  const DuLieuAnh.memory(this.bytes) : url = null;
  const DuLieuAnh.network(this.url) : bytes = null;
}

String documentImageSource(Map<String, dynamic> data) {
  for (final key in [
    'anhBase64',
    'base64',
    'anhURL',
    'base64Image',
    'duongDanAnh',
    'duLieuAnh',
  ]) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

DuLieuAnh decodeDocumentImage(String source) {
  final value = source.trim();
  if (value.isEmpty) throw const FormatException('Chưa có ảnh giấy tờ.');
  final uri = Uri.tryParse(value);
  if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
    return DuLieuAnh.network(value);
  }
  if (value.length > 8 * 1024 * 1024) {
    throw const FormatException('Ảnh quá lớn để hiển thị.');
  }
  String payload = value;
  if (value.toLowerCase().startsWith('data:')) {
    final comma = value.indexOf(',');
    if (comma < 0 ||
        !RegExp(
          r'^data:image/[a-z0-9.+-]+;base64$',
          caseSensitive: false,
        ).hasMatch(value.substring(0, comma))) {
      throw const FormatException('Dữ liệu không phải ảnh Base64 hợp lệ.');
    }
    payload = value.substring(comma + 1);
  } else if (uri != null && uri.hasScheme) {
    throw const FormatException('Định dạng ảnh chưa được hỗ trợ.');
  }
  try {
    final bytes = base64Decode(
      base64.normalize(payload.replaceAll(RegExp(r'\s+'), '')),
    );
    if (bytes.isEmpty) throw const FormatException();
    return DuLieuAnh.memory(bytes);
  } on FormatException {
    throw const FormatException('Dữ liệu ảnh Base64 không hợp lệ.');
  }
}
