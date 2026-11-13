import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const Color kTeal = Color(0xFF00897B);
const Color kTealDark = Color(0xFF00695C);
const Color kTealLight = Color(0xFFE0F2F1);
const Color kFieldFill = Color(0xFFEEF2FF);

class FormCard extends StatelessWidget {
  final Widget child;
  const FormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const SectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kTealLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kTeal, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  const FieldLabel(this.text, {super.key, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

InputDecoration fieldDecoration({
  String? hint,
  bool readOnly = false,
  Widget? suffix,
  bool multiline = false,
}) {
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.grey.shade400,
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 10,
      vertical: multiline ? 10 : 10,
    ),
    filled: true,
    fillColor: readOnly ? const Color(0xFFF1F5F9) : kFieldFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    errorStyle: const TextStyle(fontSize: 10),
    suffixIcon: suffix != null
        ? Padding(padding: const EdgeInsets.only(right: 6), child: suffix)
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
  );
}

/// Ô nhập có nhãn phía trên, dùng chung cho các section.
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: readOnly && onTap == null
                ? Colors.grey.shade700
                : Colors.black87,
          ),
          decoration: fieldDecoration(
            hint: hint,
            readOnly: readOnly && onTap == null,
            suffix: suffix,
            multiline: maxLines > 1,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet chọn nguồn ảnh.
Future<ImageSource?> showPhotoSourceSheet(
  BuildContext context, {
  String title = 'Thêm ảnh',
  bool allowGallery = true,
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (allowGallery)
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Chọn từ thư viện ảnh'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text('Chụp ảnh mới từ Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Ô ảnh vuông: trống thì hiện nút thêm, có ảnh thì hiện ảnh + nút xóa.
class PhotoTile extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final double size;

  const PhotoTile({
    super.key,
    required this.label,
    required this.file,
    required this.onAdd,
    this.onRemove,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined, color: Colors.teal, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Image.file(file!, fit: BoxFit.cover),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hộp thoại chọn 1 giá trị từ danh sách (có ô tìm kiếm). Trả về giá trị đã chọn.
Future<String?> showSelectionDialog(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<String> items,
  String? selected,
}) async {
  final searchController = TextEditingController();
  List<String> filtered = List.from(items);

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: kTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20, color: kTeal),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kTeal, width: 1.5),
                      ),
                    ),
                    onChanged: (q) {
                      setStateDialog(() {
                        filtered = items
                            .where((e) => e.toLowerCase().contains(q.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Không tìm thấy kết quả phù hợp',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final item = filtered[i];
                              final isSel = item == selected;
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => Navigator.pop(ctx, item),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? kTealLight
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? kTeal : Colors.grey.shade200,
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSel
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSel
                                                ? kTealDark
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSel)
                                        const Icon(
                                          Icons.check_circle,
                                          size: 18,
                                          color: kTeal,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Đóng',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  searchController.dispose();
  return result;
}
