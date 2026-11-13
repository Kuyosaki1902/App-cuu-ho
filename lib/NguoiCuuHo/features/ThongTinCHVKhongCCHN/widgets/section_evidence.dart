import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chv_khong_cchn_controller.dart';
import 'form_widgets.dart';

/// Section 3: Minh chứng kiểm chứng được + người bảo chứng + ảnh hoạt động (bổ trợ).
class SectionEvidence extends StatelessWidget {
  const SectionEvidence({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CuuHoVienKhongCCHNController>();
    final type = c.evidenceType;

    return FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.verified_user_outlined,
            title: '3. Minh chứng & người bảo chứng',
          ),
          const SizedBox(height: 12),

          // ---- Minh chứng chính ----
          const FieldLabel('Minh chứng có thể kiểm chứng (bắt buộc ít nhất 1)',
              isRequired: true),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kEvidenceTypes.map((t) {
              final sel = t.code == c.selectedEvidenceCode;
              return ChoiceChip(
                label: Text(t.label, style: const TextStyle(fontSize: 11)),
                selected: sel,
                selectedColor: kTealLight,
                labelStyle: TextStyle(
                  color: sel ? kTealDark : Colors.black87,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(color: sel ? kTeal : Colors.grey.shade300),
                onSelected: (_) => c.setEvidenceType(t.code),
              );
            }).toList(),
          ),
          if (type != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoTile(
                  label: 'Ảnh / scan\nminh chứng',
                  file: c.singlePhotos[ImageSlot.evidence],
                  onAdd: () async {
                    final s = await showPhotoSourceSheet(
                      context,
                      title: 'Ảnh minh chứng',
                    );
                    if (s != null) await c.pickSlot(ImageSlot.evidence, s);
                  },
                  onRemove: () => c.removeSlot(ImageSlot.evidence),
                ),
                const SizedBox(width: 10),
                if (type.needsExpiry)
                  Expanded(
                    child: LabeledField(
                      label: 'Hạn sử dụng của chứng nhận',
                      isRequired: true,
                      controller: c.evidenceExpiryController,
                      readOnly: true,
                      hint: 'dd/MM/yyyy',
                      onTap: () => c.selectDate(
                        context,
                        c.evidenceExpiryController,
                        firstDate: DateTime.now(),
                      ),
                      suffix: const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      validator: (v) =>
                          c.validateRequired(v, 'Chọn hạn sử dụng'),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Ví dụ: giấy chứng nhận sơ cấp cứu do Hội Chữ thập đỏ cấp, chứng chỉ BLS/CPR, '
            'hoặc thư xác nhận của đội cứu hộ / CLB tình nguyện.',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),

          const Divider(height: 28),

          // ---- Người bảo chứng ----
          const FieldLabel('Người bảo chứng (bắt buộc)', isRequired: true),
          const SizedBox(height: 2),
          const Text(
            'Nên là đại diện tổ chức / đội cứu hộ, hoặc bác sĩ / cứu hộ viên đã được duyệt. '
            'Hệ thống sẽ gửi mã để họ tự xác nhận, hoặc người duyệt sẽ gọi lại.',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Họ và tên',
                  controller: c.guarantorNameController,
                  hint: 'Nguyễn Văn B',
                  validator: (v) => c.validateRequired(v, 'Nhập họ tên'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LabeledField(
                  label: 'Số điện thoại',
                  controller: c.guarantorPhoneController,
                  hint: '09xxxxxxxx',
                  keyboardType: TextInputType.phone,
                  validator: c.validatePhone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const FieldLabel('Quan hệ với bạn'),
          const SizedBox(height: 4),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: kFieldFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: c.guarantorRelation,
                isExpanded: true,
                hint: Text(
                  'Chọn quan hệ...',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                items: kGuarantorRelations
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) c.setGuarantorRelation(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          LabeledField(
            label: 'Tổ chức của người bảo chứng',
            controller: c.guarantorOrgController,
            hint: 'Tên đội / CLB / Hội / Bệnh viện...',
            validator: (v) => c.validateRequired(v, 'Nhập tổ chức'),
          ),

          const Divider(height: 28),

          // ---- Ảnh hoạt động: bổ trợ ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Ảnh hoạt động thực tế (tùy chọn, chỉ để tham khảo)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${c.activityPhotos.length}/3',
                style: const TextStyle(
                  fontSize: 10,
                  color: kTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Ảnh hoạt động không được dùng làm tiêu chí duyệt chính vì khó xác thực.',
            style: TextStyle(fontSize: 10, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < c.activityPhotos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PhotoTile(
                      label: '',
                      size: 85,
                      file: c.activityPhotos[i],
                      onAdd: () {},
                      onRemove: () => c.removeActivityPhoto(i),
                    ),
                  ),
                if (c.activityPhotos.length < 3)
                  PhotoTile(
                    label: 'Thêm ảnh',
                    size: 85,
                    file: null,
                    onAdd: () async {
                      final s = await showPhotoSourceSheet(
                        context,
                        title: 'Thêm ảnh hoạt động (tối đa 3)',
                      );
                      if (s != null) await c.pickActivityPhoto(s);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Ghi chú thêm (tùy chọn)',
            controller: c.noteController,
            maxLines: 3,
            hint: 'Thông tin bổ sung cho người duyệt...',
          ),
        ],
      ),
    );
  }
}
