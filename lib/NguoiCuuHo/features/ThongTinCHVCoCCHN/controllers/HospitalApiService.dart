import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HospitalApiService {
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.nchc.org.tw/api/interpreter',
  ];

  /// Lấy danh sách Bệnh viện theo Tỉnh/Thành phố và Quận/Huyện cụ thể
  static Future<List<Map<String, String>>> fetchHospitalsByProvince(
    String provinceName, {
    String? districtName,
  }) async {
    // Tối ưu tên Tỉnh để đưa vào Query
    String cleanProvince = provinceName
        .replaceAll('Thành phố', '')
        .replaceAll('Tỉnh', '')
        .trim();

    // Làm sạch tên Quận/Huyện nếu có (Ví dụ: "Quận 1" -> "1", "Huyện Bình Chánh" -> "Bình Chánh")
    String? cleanDistrict = districtName
        ?.replaceAll('Quận', '')
        .replaceAll('Huyện', '')
        .replaceAll('Thị xã', '')
        .replaceAll('Thành phố', '')
        .trim();

    final String query =
        '''
[out:json][timeout:10];
area["name"~"$cleanProvince"]["boundary"="administrative"]->.searchArea;
(
  node["amenity"="hospital"](area.searchArea);
  way["amenity"="hospital"](area.searchArea);
);
out tags;
''';

    for (String endpoint in _endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'CuuHoKhanCapApp/1.0 (contact@cuhokhancap.com)',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(
            utf8.decode(response.bodyBytes),
          );
          final List<dynamic> elements = data['elements'] ?? [];

          List<Map<String, String>> hospitalList = [];

          for (var item in elements) {
            final tags = item['tags'];
            if (tags != null) {
              String? name = tags['name:vi'] ?? tags['name'];

              if (name != null && name.trim().isNotEmpty) {
                String province =
                    tags['addr:province'] ?? tags['is_in:province'] ?? '';
                String district =
                    tags['addr:district'] ?? tags['is_in:district'] ?? '';
                String street = tags['addr:street'] ?? '';
                String fullAddress = '$street $district $province'.trim();

                // 🟢 Lọc theo Quận/Huyện nếu có tham số districtName
                if (cleanDistrict != null && cleanDistrict.isNotEmpty) {
                  String hpAddrLower = fullAddress.toLowerCase();
                  String hpNameLower = name.toLowerCase();
                  String targetDistrictLower = cleanDistrict.toLowerCase();

                  // Kiểm tra xem tên hoặc địa chỉ bệnh viện có chứa tên Quận/Huyện không
                  if (!hpAddrLower.contains(targetDistrictLower) &&
                      !hpNameLower.contains(targetDistrictLower)) {
                    continue; // Bỏ qua nếu bệnh viện không thuộc quận/huyện này
                  }
                }

                hospitalList.add({
                  'name': name.trim(),
                  'province': province.trim(),
                  'district': district.trim(),
                  'address': fullAddress,
                });
              }
            }
          }

          if (hospitalList.isNotEmpty) {
            debugPrint(
              'Lấy thành công ${hospitalList.length} bệnh viện tại $provinceName - $districtName',
            );
            return hospitalList;
          }
        }
      } catch (e) {
        debugPrint('Endpoint $endpoint lỗi/timeout: $e');
        continue;
      }
    }

    return [];
  }
}
