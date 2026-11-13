class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

/// Điểm đạt tối thiểu (%) để được nộp hồ sơ.
const int kQuizPassPercent = 80;

/// Ngân hàng câu hỏi tình huống sơ cấp cứu cơ bản.
/// Nên nhờ giảng viên / người có chuyên môn rà soát lại nội dung trước khi dùng thật,
/// và về lâu dài chuyển ngân hàng câu hỏi + việc chấm điểm lên server.
const List<QuizQuestion> kQuizBank = [
  QuizQuestion(
    question:
        'Bạn thấy một người ngã gục, gọi không phản ứng và không thở (hoặc chỉ thở ngáp). Sau khi đã kiểm tra hiện trường an toàn, việc cần làm ngay là gì?',
    options: [
      'Cho uống nước ấm để tỉnh lại',
      'Gọi 115 (hoặc nhờ người xung quanh gọi) và bắt đầu ép tim ngoài lồng ngực',
      'Đổ nước lên mặt và chờ vài phút xem có tỉnh không',
      'Bóp tay, bóp chân cho máu lưu thông',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Tần số ép tim ngoài lồng ngực cho người lớn là bao nhiêu?',
    options: [
      '40 - 60 lần/phút',
      '60 - 80 lần/phút',
      '100 - 120 lần/phút',
      '150 - 180 lần/phút',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Độ sâu ép tim phù hợp cho người lớn là:',
    options: ['Khoảng 1 - 2 cm', 'Khoảng 5 - 6 cm', 'Khoảng 8 - 10 cm', 'Càng sâu càng tốt'],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Nạn nhân bị chảy máu nhiều ở cánh tay. Cách xử trí ban đầu đúng nhất?',
    options: [
      'Ấn trực tiếp lên vết thương bằng gạc hoặc vải sạch và giữ chặt',
      'Rửa vết thương dưới vòi nước rồi để máu tự cầm',
      'Bôi bột hoặc lá cây lên vết thương',
      'Nâng cao tay và không cần làm gì thêm',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Khi đến hiện trường một vụ tai nạn giao thông, điều ưu tiên đầu tiên là gì?',
    options: [
      'Lao vào kéo nạn nhân ra khỏi xe ngay',
      'Chụp ảnh, quay video gửi người thân',
      'Đảm bảo an toàn cho bản thân và hiện trường (xe cộ, cháy nổ, điện) rồi mới tiếp cận',
      'Chờ người khác đến xử lý mà không gọi ai',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Nạn nhân ngã từ trên cao, kêu đau cổ và tê tay chân. Bạn nên:',
    options: [
      'Đỡ nạn nhân ngồi dậy cho dễ thở',
      'Xoay cổ nhẹ nhàng để kiểm tra',
      'Hạn chế tối đa di chuyển, giữ cố định đầu cổ và gọi 115',
      'Cho nạn nhân tự đứng dậy đi lại thử',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Bị bỏng nước sôi diện tích nhỏ ở cẳng tay. Xử trí ban đầu đúng là:',
    options: [
      'Bôi kem đánh răng hoặc nước mắm lên vết bỏng',
      'Chườm đá lạnh trực tiếp và chọc vỡ bọng nước',
      'Làm mát bằng nước mát chảy nhẹ khoảng 10 - 20 phút rồi che phủ sạch',
      'Quấn kín bằng bông gòn dính vào vết bỏng',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Người đuối nước được vớt lên, không phản ứng và không thở. Bạn nên:',
    options: [
      'Dốc ngược người, vỗ lưng cho nước chảy hết ra rồi mới làm tiếp',
      'Gọi 115, bắt đầu hồi sinh tim phổi (ép tim, thổi ngạt nếu đã được huấn luyện)',
      'Đặt nằm nghỉ và theo dõi 30 phút',
      'Cho uống nước đường',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Khi nào cần gọi 115?',
    options: [
      'Chỉ khi đã thử mọi cách sơ cứu mà không hiệu quả',
      'Ngay khi gặp tình huống nguy hiểm tính mạng (bất tỉnh, khó thở, chảy máu không cầm, đau ngực dữ dội...)',
      'Chỉ khi có người thân của nạn nhân yêu cầu',
      'Chỉ vào ban ngày',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question:
        'Bạn không có chứng chỉ hành nghề khám chữa bệnh. Khi nạn nhân nguy kịch, bạn nên làm gì?',
    options: [
      'Tiêm thuốc hoặc truyền dịch cho nhanh vì tình huống khẩn cấp',
      'Cho uống thuốc kê đơn của mình để giảm đau',
      'Chỉ sơ cứu trong phạm vi đã được huấn luyện, gọi 115 và giữ an toàn cho nạn nhân tới khi nhân viên y tế đến',
      'Từ chối mọi hỗ trợ vì không có chứng chỉ',
    ],
    correctIndex: 2,
  ),
];
