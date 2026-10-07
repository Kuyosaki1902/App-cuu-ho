import 'package:flutter/material.dart';

void main() {
  runApp(const DoctorSelectionApp());
}

class DoctorSelectionApp extends StatelessWidget {
  const DoctorSelectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(
          0xFFA7B1C2,
        ), // Màu nền ngoài màn hình
        fontFamily: 'Roboto',
      ),
      home: const DoctorSelectionScreen(),
    );
  }
}

class DoctorModel {
  final String initials;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final String name;
  final String specialty;
  final Color specialtyBgColor;
  final Color specialtyTextColor;
  final double rating;
  final int reviewsCount;
  final String distance;
  final String timeArrival;
  final String phone;
  final String status;
  final bool isSelected;

  DoctorModel({
    required this.initials,
    required this.avatarBgColor,
    required this.avatarTextColor,
    required this.name,
    required this.specialty,
    required this.specialtyBgColor,
    required this.specialtyTextColor,
    required this.rating,
    required this.reviewsCount,
    required this.distance,
    required this.timeArrival,
    required this.phone,
    required this.status,
    this.isSelected = false,
  });
}

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  int selectedCategoryIndex = 0;
  int selectedDoctorIndex = 0;

  final List<String> categories = [
    'Tất cả (6)',
    'Đa khoa (2)',
    'Nhi khoa (1)',
    'Tim mạch (1)',
  ];

  final List<DoctorModel> doctors = [
    DoctorModel(
      initials: 'HN',
      avatarBgColor: const Color(0xFFD2F5EC),
      avatarTextColor: const Color(0xFF0C5C4D),
      name: 'BS. CK1 Nguyễn Hoài Nam',
      specialty: 'Đa khoa',
      specialtyBgColor: const Color(0xFFE2F7F2),
      specialtyTextColor: const Color(0xFF0C5C4D),
      rating: 4.9,
      reviewsCount: 128,
      distance: '800m',
      timeArrival: '5–8 phút đến',
      phone: '0908.234.xxx',
      status: 'Sẵn sàng ngay lập tức',
      isSelected: true,
    ),
    DoctorModel(
      initials: 'MA',
      avatarBgColor: const Color(0xFFFDE8E8),
      avatarTextColor: const Color(0xFF9B1C1C),
      name: 'BS. Mai Anh',
      specialty: 'Tim mạch',
      specialtyBgColor: const Color(0xFFFDF2F2),
      specialtyTextColor: const Color(0xFF9B1C1C),
      rating: 5.0,
      reviewsCount: 94,
      distance: '1.4km',
      timeArrival: '10 phút đến',
      phone: '0912.***.888',
      status: 'Đang trực tuyến',
    ),
    DoctorModel(
      initials: 'QB',
      avatarBgColor: const Color(0xFFE1F5FE),
      avatarTextColor: const Color(0xFF0288D1),
      name: 'BS. Q. Bảo',
      specialty: 'Nhi khoa',
      specialtyBgColor: const Color(0xFFE0F2FE),
      specialtyTextColor: const Color(0xFF0369A1),
      rating: 4.8,
      reviewsCount: 76,
      distance: '2.1km',
      timeArrival: '12 phút đến',
      phone: '0988.***.233',
      status: 'Sẵn sàng tiếp nhận',
    ),
    DoctorModel(
      initials: 'TH',
      avatarBgColor: const Color(0xFFFEF3C7),
      avatarTextColor: const Color(0xFFB45309),
      name: 'BS. T. Hương',
      specialty: 'Hô hấp',
      specialtyBgColor: const Color(0xFFFFFBEB),
      specialtyTextColor: const Color(0xFFB45309),
      rating: 4.9,
      reviewsCount: 112,
      distance: '2.8km',
      timeArrival: '15 phút đến',
      phone: '0934.***.890',
      status: 'Sẵn sàng ngay',
    ),
    DoctorModel(
      initials: 'HL',
      avatarBgColor: const Color(0xFFE0E7FF),
      avatarTextColor: const Color(0xFF3730A3),
      name: 'BS. Lê Hoàng Long',
      specialty: 'Nội tổng quát',
      specialtyBgColor: const Color(0xFFEEF2FF),
      specialtyTextColor: const Color(0xFF3730A3),
      rating: 4.7,
      reviewsCount: 59,
      distance: '2.9km',
      timeArrival: '16 phút đến',
      phone: '0977.***.344',
      status: 'Sẵn sàng',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              // Thanh gạch xám phía trên cùng
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Navigation
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[100],
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Colors.black87,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    const Text(
                      'Chọn bác sĩ tiếp nhận',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.grey[100],
                      child: IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Colors.black87,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),

              // Location & Active doctor status
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF0C5C4D),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Pasteur, Q.1',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Text(
                      'Bán kính 3km',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F7F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '6 bác sĩ sẵn sàng',
                        style: TextStyle(
                          color: Color(0xFF0C5C4D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Bar
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedCategoryIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0C5C4D)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Doctors List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    final isSelected = selectedDoctorIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => selectedDoctorIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0C5C4D)
                                : Colors.transparent,
                            width: isSelected ? 2 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar with status tick badge
                                Stack(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: doctor.avatarBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          doctor.initials,
                                          style: TextStyle(
                                            color: doctor.avatarTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF0C5C4D),
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Doctor Information
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: doctor.specialtyBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              doctor.specialty,
                                              style: TextStyle(
                                                color:
                                                    doctor.specialtyTextColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${doctor.rating}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                          Text(
                                            ' (${doctor.reviewsCount})',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            doctor.distance,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const Text(
                                            '  •  ',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            doctor.timeArrival,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Radio Selection Icon
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0C5C4D)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 6 : 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                            ),

                            // Footer: Phone Number & Status
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 12,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        doctor.phone,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctor.status,
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Action Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C5C4D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        icon: const Icon(
                          Icons.send_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'XÁC NHẬN CHỌN BÁC SĨ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Chứng chỉ hành nghề & hồ sơ y tế đã được xác minh 100%',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
