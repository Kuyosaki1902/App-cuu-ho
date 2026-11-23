import 'package:flutter/material.dart';

class HopThoaiLyDo extends StatefulWidget {
  final String title, name;
  const HopThoaiLyDo({super.key, required this.title, required this.name});
  @override
  State<HopThoaiLyDo> createState() => _HopThoaiLyDoState();
}

class _HopThoaiLyDoState extends State<HopThoaiLyDo> {
  final key = GlobalKey<FormState>();
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tài khoản: ${widget.name}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Lý do (bắt buộc)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v?.trim().length ?? 0) < 5 ? 'Nhập ít nhất 5 ký tự.' : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (key.currentState!.validate()) {
            Navigator.pop(context, controller.text.trim());
          }
        },
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
