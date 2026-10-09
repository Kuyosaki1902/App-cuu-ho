import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Người Thân Của Bạn',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        primaryColor: const Color(0xFF006D5B),
      ),
      home: const RelativeScreen(),
    );
  }
}

class RelativeScreen extends StatefulWidget {
  const RelativeScreen({super.key});

  @override
  State<RelativeScreen> createState() => _RelativeScreenState();
}

class _RelativeScreenState extends State<RelativeScreen> {
  // 0: Tab Người thân của bạn, 1: Tab Tìm kiếm người thân
  int _selectedTab = 0;

  // Trạng thái thanh tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _selectedFilterIndex =
      0; // 0: Tất cả, 1: Yêu cầu đã nhận, 2: Yêu cầu đã gửi

  final Color primaryColor = const Color(0xFF006A55);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Người Thân Của Bạn',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // PHẦN CỐ ĐỊNH PHÍA TRÊN
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // 2 NÚT TAB CHÍNH
                Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Người Thân Của Bạn',
                        isSelected: _selectedTab == 0,
                        onTap: () {
                          setState(() {
                            _selectedTab = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Tìm Kiếm Người Thân',
                        isSelected: _selectedTab == 1,
                        onTap: () {
                          setState(() {
                            _selectedTab = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // NẾU LÀ TAB TÌM KIẾM -> HIỂN THỊ THANH TÌM KIẾM CỐ ĐỊNH
                if (_selectedTab == 1) ...[
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _isSearching = true;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm theo số điện thoại, email hoặc...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon:
                          _searchController.text.isNotEmpty || _isSearching
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // THANH PHÂN LOẠI KÉO SANG TRÁI PHẢI (TO HƠN)
                  if (!_isSearching) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42, // Làm to kích thước chiều cao
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip(0, 'Tất cả', count: 4),
                          const SizedBox(width: 8),
                          _buildFilterChip(1, 'Yêu cầu đã nhận', count: 2),
                          const SizedBox(width: 8),
                          _buildFilterChip(2, 'Yêu cầu đã gửi', count: 2),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // PHẦN KÉO LÊN XUỐNG BÊN DƯỚI
          Expanded(
            child: _selectedTab == 0
                ? _buildMyRelativesList()
                : (_isSearching
                      ? _buildSearchResultView()
                      : _buildSearchTabList()),
          ),
        ],
      ),
    );
  }

  // WIDGET NÚT CHUYỂN TAB
  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // WIDGET CHIP PHÂN LOẠI (KÉO NGANG)
  Widget _buildFilterChip(int index, String label, {required int count}) {
    bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. TAB 1: DANH SÁCH NGƯỜI THÂN CỦA BẠN (HÌNH 1)
  Widget _buildMyRelativesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRelativeCard(
          name: 'Trần Văn Hùng',
          age: 58,
          phone: '0912 345 678',
          email: 'hung.tran58@gmail.com',
          relation: 'Bố (Cha)',
          avatarUrl: 'https://i.pravatar.cc/150?img=11',
        ),
        _buildRelativeCard(
          name: 'Nguyễn Thị Mai',
          age: 55,
          phone: '0903 888 999',
          email: 'mai.nguyen@gmail.com',
          relation: 'Mẹ',
          avatarUrl: 'https://i.pravatar.cc/150?img=5',
        ),
        _buildRelativeCard(
          name: 'Nguyễn Văn Hùng',
          age: 34,
          phone: '0903 123 456',
          email: 'hung.nguyen89@gmail.com',
          relation: 'Chồng',
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
        ),
      ],
    );
  }

  Widget _buildRelativeCard({
    required String name,
    required int age,
    required String phone,
    required String email,
    required String relation,
    required String avatarUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$age tuổi',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: Color(0xFF006A55),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(email, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 18,
                      color: Color(0xFF006A55),
                    ),
                    const SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Mối quan hệ: ',
                        style: const TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: relation,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {},
              icon: const Icon(Icons.call, size: 18, color: Colors.white),
              label: const Text(
                'Gọi điện',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. TAB 2 (CHƯA TÌM KIẾM): DANH SÁCH YÊU CẦU ĐÃ NHẬN VÀ ĐÃ GỬI (HÌNH 2)
  Widget _buildSearchTabList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
          const Text(
            'Yêu cầu đã nhận',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildReceivedCard(
            'Khang Nguyễn',
            '0912 345 678',
            'khang.nguyen@gmail.com',
            'Con trai',
            '10 phút trước',
          ),
          _buildReceivedCard(
            'Thùy Linh',
            '0988 765 432',
            'thuylinh.pham@gmail.com',
            'Em gái',
            '1 giờ trước',
          ),
        ],
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
          const SizedBox(height: 8),
          const Text(
            'Yêu cầu đã gửi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildSentCard(
            'Thu Hà',
            29,
            '0987 654 321',
            'thuha.tran@gmail.com',
            '15 phút trước',
          ),
          _buildSentCard(
            'Lê Quốc Bảo',
            42,
            '0934 567 890',
            'baole.med@gmail.com',
            '2 giờ trước',
          ),
        ],
      ],
    );
  }

  Widget _buildReceivedCard(
    String name,
    String phone,
    String email,
    String rel,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(email),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Muốn thành lập mối quan hệ: ',
              children: [
                TextSpan(
                  text: rel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            'Đã nhận $time',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Chấp nhận',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentCard(
    String name,
    int age,
    String phone,
    String email,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=47',
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$age tuổi', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Chờ xem xét',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(email),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã gửi $time',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Thu hồi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. TRẠNG THÁI TÌM KIẾM: KẾT QUẢ TÌM KIẾM DUY NHẤT (HÌNH 3)
  Widget _buildSearchResultView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kết quả tìm kiếm',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=60',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nguyễn Văn An',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Color(0xFF006A55),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '0123 456 789',
                            style: TextStyle(
                              color: Color(0xFF006A55),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // NÚT DẤU CỘNG TRÒN
                GestureDetector(
                  onTap: () {
                    _showAddRelationBottomSheet(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. BOTTOM SHEET THIẾT LẬP MỐI QUAN HỆ (HÌNH 4)
  void _showAddRelationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo nhỏ trên đầu
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    'Thiết lập mối quan hệ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Card thông tin ngắn gọn
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=60',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nguyễn Văn An',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '0123 456 789',
                          style: TextStyle(color: Color(0xFF006A55)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mối quan hệ hai chiều',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bạn là',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: 'Con trai',
                          items: const [
                            DropdownMenuItem(
                              value: 'Con trai',
                              child: Text(
                                'Con trai',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Con gái',
                              child: Text(
                                'Con gái',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (val) {},
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.swap_horiz, color: Color(0xFF006A55)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nguyễn Văn An là',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: 'Bố (Ba)',
                          items: const [
                            DropdownMenuItem(
                              value: 'Bố (Ba)',
                              child: Text(
                                'Bố (Ba)',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Mẹ',
                              child: Text('Mẹ', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) {},
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Gửi yêu cầu thiết lập',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
