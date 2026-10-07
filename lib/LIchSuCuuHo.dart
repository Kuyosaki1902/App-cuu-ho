import 'package:flutter/material.dart';

void main() {
  runApp(const RescueHistoryApp());
}

class RescueHistoryApp extends StatelessWidget {
  const RescueHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFA7B1C2),
        fontFamily: 'Roboto',
      ),
      home: const RescueHistoryScreen(),
    );
  }
}

class TimelineStep {
  final String time;
  final String title;
  final bool isLast;

  TimelineStep({required this.time, required this.title, this.isLast = false});
}

class RescueHistoryModel {
  final String id;
  final String status;
  final String timeRequested;
  final String injuryLocation;
  final String doctorName;
  final List<TimelineStep>? timeline;
  final int? rating;
  final String? ratingText;

  RescueHistoryModel({
    required this.id,
    required this.status,
    required this.timeRequested,
    required this.injuryLocation,
    required this.doctorName,
    this.timeline,
    this.rating,
    this.ratingText,
  });
}

class RescueHistoryScreen extends StatefulWidget {
  const RescueHistoryScreen({super.key});

  @override
  State<RescueHistoryScreen> createState() => _RescueHistoryScreenState();
}

class _RescueHistoryScreenState extends State<RescueHistoryScreen> {
  final List<RescueHistoryModel> historyList = [
    RescueHistoryModel(
      id: '#YC–99201',
      status: 'Hoàn tất sơ cứu',
      timeRequested: '14:32 – 24/10/2023',
      injuryLocation: 'Đầu gối phải – Chấn thương mô m...',
      doctorName: 'Bs. Trần Hoàng Hải – Kíp cấp cứu 115',
      rating: 5,
      ratingText: 'Rất hài lòng (5/5)',
      timeline: [
        TimelineStep(time: '14:32:04', title: '1. Yêu cầu SOS từ thiết bị'),
        TimelineStep(
          time: '14:33:15',
          title: '2. Bác sĩ tiếp nhận và gọi xe cấp cứu',
        ),
        TimelineStep(
          time: '14:34:00',
          title: '3. Bác sĩ hướng dẫn sơ cứu qua cuộc gọi',
        ),
        TimelineStep(
          time: '14:37:45',
          title: '4. Hoàn tất sơ cứu tại chỗ',
          isLast: true,
        ),
      ],
    ),
    RescueHistoryModel(
      id: '#YC–77103',
      status: 'Hoàn tất sơ cứu',
      timeRequested: '19:40 – 28/08/2023',
      injuryLocation: 'Cẳng tay trái – Bỏng',
      doctorName: 'Bs. Nguyễn Văn An – Kíp cấp cứu 115',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // 1. HEADER MÀN HÌNH LỊCH SỬ CỨU HỘ
              Container(
                padding: const EdgeInsets.only(
                  top: 48,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lịch Sử Cứu Hộ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. DANH SÁCH THẺ LỊCH SỬ CỨU HỘ
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final item = historyList[index];
                    return _buildHistoryCard(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget dựng từng thẻ lịch sử cứu hộ
  Widget _buildHistoryCard(RescueHistoryModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dải viền đỏ khẩn cấp bên trái thẻ
            Container(width: 5, color: const Color(0xFFE53E3E)),

            // Nội dung chính bên trong thẻ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header của Card: Mã YC & Badge Trạng thái
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.id,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item.status,
                            style: const TextStyle(
                              color: Color(0xFF0C5C4D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Thời gian yêu cầu
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Thời gian yêu cầu: ${item.timeRequested}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Khối Vị trí chấn thương
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6EE7B7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              color: Color(0xFF0C5C4D),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vị trí chấn thương',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.injuryLocation,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Khối Thông tin bác sĩ phụ trách
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0C5C4D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THÔNG TIN BÁC SĨ PHỤ TRÁCH',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C5C4D),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.doctorName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nhật ký điều phối (Nếu có timeline)
                    if (item.timeline != null && item.timeline!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.show_chart_rounded,
                                size: 16,
                                color: Color(0xFFE53E3E),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Nhật ký điều phối',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.timeline!.length} mốc hoàn tất',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0C5C4D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Danh sách dòng thời gian Timeline
                      Column(
                        children: item.timeline!
                            .map((tl) => _buildTimelineRow(tl))
                            .toList(),
                      ),
                    ],

                    // Đánh giá chất lượng hỗ trợ (Nếu có)
                    if (item.rating != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Đánh giá chất lượng hỗ trợ ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  item.ratingText ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (index) => const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Nút Phản ánh hỗ trợ / vấn đề (Nếu có)
                    if (item.rating != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {},
                          icon: const Icon(
                            Icons.mic_none_rounded,
                            size: 18,
                            color: Color(0xFF0C5C4D),
                          ),
                          label: const Text(
                            'Phản ánh hỗ trợ / vấn đề',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget xây dựng từng mốc Timeline[cite: 9]
  Widget _buildTimelineRow(TimelineStep step) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột thời gian
          SizedBox(
            width: 70,
            child: Text(
              step.time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Cột đường chấm tròn timeline
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: step.isLast
                      ? const Color(0xFFE53E3E)
                      : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              if (!step.isLast)
                Expanded(child: Container(width: 1.5, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 10),

          // Cột mô tả sự kiện
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: step.isLast ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
