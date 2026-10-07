import 'package:flutter/material.dart';

void main() {
  runApp(const CommunityLeaderboardApp());
}

class CommunityLeaderboardApp extends StatelessWidget {
  const CommunityLeaderboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFA7B1C2),
        fontFamily: 'Roboto',
      ),
      home: const CommunityLeaderboardScreen(),
    );
  }
}

class RescuerLeaderboardModel {
  final int rank;
  final String name;
  final int casesCount;
  final String specialty;
  final String organization;
  final double rating;
  final int reviewsCount;
  final Color? cardBgColor;

  RescuerLeaderboardModel({
    required this.rank,
    required this.name,
    required this.casesCount,
    required this.specialty,
    required this.organization,
    required this.rating,
    required this.reviewsCount,
    this.cardBgColor,
  });
}

class CommunityLeaderboardScreen extends StatefulWidget {
  const CommunityLeaderboardScreen({super.key});

  @override
  State<CommunityLeaderboardScreen> createState() =>
      _CommunityLeaderboardScreenState();
}

class _CommunityLeaderboardScreenState
    extends State<CommunityLeaderboardScreen> {
  int selectedTab = 1; // 0: Tuần này, 1: Tháng này, 2: Tất cả

  final List<String> tabs = ['Tuần này', 'Tháng này', 'Tất cả'];

  final List<RescuerLeaderboardModel> rescuers = [
    RescuerLeaderboardModel(
      rank: 1,
      name: 'BS. Mai Anh',
      casesCount: 98,
      specialty: 'Cấp cứu hồi sức & Đột quỵ',
      organization: 'Đội Cứu hộ 115',
      rating: 4.9,
      reviewsCount: 142,
      cardBgColor: const Color(0xFFFFFDF0), // Vàng nhạt Top 1
    ),
    RescuerLeaderboardModel(
      rank: 2,
      name: 'BS. Nam',
      casesCount: 86,
      specialty: 'Cấp cứu tim mạch & Lưu động',
      organization: 'BV Bạch Mai',
      rating: 4.9,
      reviewsCount: 128,
      cardBgColor: const Color(0xFFF8FAFC), // Xám bạc Top 2
    ),
    RescuerLeaderboardModel(
      rank: 3,
      name: 'KTV. Hoàng Long',
      casesCount: 74,
      specialty: 'Hỗ trợ CC chấn thương',
      organization: 'BV Chợ Rẫy',
      rating: 4.8,
      reviewsCount: 95,
      cardBgColor: const Color(0xFFFFF7ED), // Đồng/Cam nhạt Top 3
    ),
    RescuerLeaderboardModel(
      rank: 4,
      name: 'BS. Trần Minh Tuấn',
      casesCount: 71,
      specialty: 'Hồi sức tích cực (ICU)',
      organization: 'BV ĐH Y Dược TP.HCM',
      rating: 4.9,
      reviewsCount: 84,
    ),
    RescuerLeaderboardModel(
      rank: 5,
      name: 'Điều dưỡng Lê Thảo',
      casesCount: 68,
      specialty: 'Sơ cấp cứu & Bỏng',
      organization: 'Trung tâm Cấp cứu 115',
      rating: 4.8,
      reviewsCount: 76,
    ),
    RescuerLeaderboardModel(
      rank: 6,
      name: 'Đặng Quốc Bảo',
      casesCount: 64,
      specialty: 'Cứu nạn đường sông & Bão lũ',
      organization: 'Cứu hộ Thủy Tự nguyện',
      rating: 4.9,
      reviewsCount: 92,
    ),
    RescuerLeaderboardModel(
      rank: 7,
      name: 'ThS.BS. Vũ Thảo',
      casesCount: 52,
      specialty: 'Cấp cứu Nhi khoa & Ngạt nước',
      organization: 'PKĐK Medic Sài Gòn',
      rating: 4.7,
      reviewsCount: 65,
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
              // 1. HEADER MÀN HÌNH BẢNG XẾP HẠNG
              Container(
                padding: const EdgeInsets.only(
                  top: 48,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                color: Colors.white,
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
                    const Expanded(
                      child: Text(
                        'Bảng xếp hạng cộng đồng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                      width: 48,
                    ), // Cân bằng không gian với nút back
                  ],
                ),
              ),

              // 2. THANH CHỌN THỜI GIAN (FILTER TABS)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: List.generate(tabs.length, (index) {
                      final isSelected = selectedTab == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedTab = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                tabs[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // 3. TIÊU ĐỀ DANH SÁCH & THỜI GIAN
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'DANH SÁCH CỨU HỘ VIÊN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Tháng 10/2024',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // 4. DANH SÁCH BẢNG XẾP HẠNG (LEADERBOARD LIST)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: rescuers.length,
                  itemBuilder: (context, index) {
                    final item = rescuers[index];
                    return _buildLeaderboardItem(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget xây dựng từng dòng cứu hộ viên
  Widget _buildLeaderboardItem(RescuerLeaderboardModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: item.cardBgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.rank == 1
              ? const Color(0xFFFEF08A)
              : item.rank == 2
              ? const Color(0xFFE2E8F0)
              : item.rank == 3
              ? const Color(0xFFFFEDD5)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cột Hạng / Vương miện
          SizedBox(
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.rank == 1)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 20,
                  )
                else if (item.rank == 2)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  )
                else if (item.rank == 3)
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                const SizedBox(height: 2),
                Text(
                  '#${item.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.rank <= 3 ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Avatar kèm Badge Đánh giá Sao bên dưới
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.rank == 1
                        ? Colors.amber
                        : item.rank == 2
                        ? const Color(0xFF94A3B8)
                        : item.rank == 3
                        ? const Color(0xFFD97706)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${item.rating}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        ' (${item.reviewsCount})',
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Thông tin tên, ca hỗ trợ & chuyên khoa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.casesCount} ca hỗ trợ',
                    style: const TextStyle(
                      color: Color(0xFF0C5C4D),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.specialty,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.organization,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Nút nhắn tin / trò chuyện tròn bên phải
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[100],
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: Colors.black54,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
