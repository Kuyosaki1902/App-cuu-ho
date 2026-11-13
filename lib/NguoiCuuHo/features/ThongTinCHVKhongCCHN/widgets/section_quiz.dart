import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chv_khong_cchn_controller.dart';
import '../models/quiz_question.dart';
import 'form_widgets.dart';

/// Section 4: Bài kiểm tra năng lực sơ cấp cứu (đạt từ 80% mới nộp được hồ sơ).
class SectionQuiz extends StatelessWidget {
  const SectionQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CuuHoVienKhongCCHNController>();
    final total = kQuizBank.length;

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.quiz_outlined,
            title: '4. Bài kiểm tra năng lực sơ cấp cứu',
          ),
          const SizedBox(height: 6),
          Text(
            '$total câu tình huống. Cần đúng từ $kQuizPassPercent% '
            '(${(total * kQuizPassPercent / 100).ceil()}/$total câu) để nộp hồ sơ.',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < total; i++) _QuestionTile(index: i),
          const SizedBox(height: 4),
          if (c.quizGraded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: c.quizPassed
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                c.quizPassed
                    ? 'Đạt: ${c.quizScore}/$total câu đúng.'
                    : 'Chưa đạt: ${c.quizScore}/$total câu đúng. Các câu sai được '
                        'đánh dấu đỏ, hãy xem lại kiến thức và làm lại.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.quizPassed
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: c.quizAllAnswered && !c.quizPassed ? c.gradeQuiz : null,
                  child: Text(
                    c.quizPassed
                        ? 'Đã đạt'
                        : c.quizAllAnswered
                            ? 'Chấm điểm'
                            : 'Trả lời đủ ${c.quizAnswers.length}/$total câu',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              if (c.quizGraded && !c.quizPassed) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: c.resetQuiz,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Làm lại',
                    style: TextStyle(color: kTeal, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final int index;
  const _QuestionTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CuuHoVienKhongCCHNController>();
    final q = kQuizBank[index];
    final wrong = c.isQuestionWrong(index);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: wrong ? Colors.red.shade300 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu ${index + 1}. ${q.question}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          for (int o = 0; o < q.options.length; o++)
            InkWell(
              onTap: () => c.answerQuiz(index, o),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      c.quizAnswers[index] == o
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: c.quizAnswers[index] == o ? kTeal : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.options[o],
                        style: const TextStyle(fontSize: 11.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
