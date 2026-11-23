"use strict";
/**
 * Công cụ chẩn đoán CHỈ ĐỌC Firestore. Không tạo/cập nhật/xóa dữ liệu.
 * Đặt file này vào thư mục functions (cạnh package.json):
 *    node chan_doan_ca.js yeucau6 cuuhokhancap-d5178
 * Yêu cầu Application Default Credentials có quyền đọc Firestore.
 */
const { initializeApp, getApps } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const ca = process.argv[2];
const projectId = process.argv[3];
if (!ca || !/^[\w-]{1,150}$/.test(ca) || !projectId || !/^[a-z][\w-]+$/.test(projectId)) {
  console.error("Cách dùng: node chan_doan_ca.js <maYeuCau> <project-id>");
  process.exit(2);
}
if (getApps().length === 0) initializeApp({ projectId });
const db = getFirestore();
const fmt = x => {
  if (!x) return "—";
  const date = typeof x.toDate === "function" ? x.toDate() :
    x instanceof Date ? x : (typeof x === "string" ? new Date(x) : null);
  return date && Number.isFinite(date.getTime())
    ? date.toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh", hour12: false }) + " (VN)"
    : typeof x === "string" ? x : String(x);
};
const offset = (ts, base) => ts && base ? `${Math.round((ts.toMillis()-base.toMillis())/1000)}s` : "—";
const first = (r, keys) => Object.fromEntries(keys.filter(k => r[k] !== undefined).map(k => [k, r[k]]));
const fieldNames = ["maYeuCau", "maNguoiCuuHo", "maPhanCong", "maTrangThaiTiepNhan", "maNguoiTao", "maAdmin", "maNguoiDieuPhoi", "maNguoiPhanHoi", "nguonPhanCong", "nguonTao", "lyDoKetThuc", "thoiGianGui", "hanPhanHoi", "thoiGianPhanHoi", "thoiGianTiepNhan", "thoiGianHoanThanh", "duongDanPhanCongGoc", "nguonDongBo"];
function clean(obj) {
  const out = first(obj, fieldNames);
  for (const [key, value] of Object.entries(out)) if (/thoiGian|hanPhanHoi/.test(key)) out[key] = fmt(value);
  return out;
}
async function main() {
  const snap = await db.collection("YeuCauCuuHo").doc(ca).get();
  if (!snap.exists) throw new Error(`Không tìm thấy YeuCauCuuHo/${ca}`);
  const data = snap.data();
  const map = data.danhSachPhanCongVien && typeof data.danhSachPhanCongVien === "object"
    ? data.danhSachPhanCongVien : {};
  console.log(`\nDỰ ÁN: ${projectId}; CA: ${ca}`);
  console.log("CA ĐƯỢC TẠO:", fmt(snap.createTime), "| CẬP NHẬT LẦN CUỐI:", fmt(snap.updateTime));
  console.log("Trạng thái:", data.maTinhTrangYeuCau, "| Số người cần:", data.soNguoiCanCuuHo);
  console.log("MAP danhSachPhanCongVien:", JSON.stringify(map, null, 2));
  console.log("\nĐang tìm bản ghi phân công gốc và bản ghi phẳng...");
  const [nested, flat] = await Promise.all([
    db.collectionGroup("DanhSachPhanCong").where("maYeuCau", "==", ca).limit(200).get(),
    db.collection("ChiTietPhanCongCuuHo").where("maYeuCau", "==", ca).limit(200).get(),
  ]);
  console.log(`\nPHÂN CÔNG GỐC: ${nested.size} bản ghi${nested.size===200?" (có thể còn nữa)":""}`);
  for (const d of nested.docs) {
    console.log("\n", d.ref.path);
    console.log("   Tạo:", fmt(d.createTime), "| Sau khi tạo ca:", offset(d.createTime,snap.createTime), "| Sửa:",fmt(d.updateTime));
    console.log("   Dữ liệu:", JSON.stringify(clean(d.data())));
  }
  console.log(`\nBẢN GHI PHẲNG: ${flat.size} bản ghi${flat.size===200?" (có thể còn nữa)":""}`);
  for (const d of flat.docs) {
    console.log("\n", d.ref.path);
    console.log("   Tạo:", fmt(d.createTime), "| Sau khi tạo ca:", offset(d.createTime,snap.createTime));
    console.log("   Dữ liệu:", JSON.stringify(clean(d.data())));
  }
  console.log("\nĐỐI CHIẾU UID trong map:");
  for (const [uid,status] of Object.entries(map)) {
    const orig = nested.docs.filter(d => d.data().maNguoiCuuHo===uid);
    console.log(`- ${uid}: map=${status}; phân công gốc=${orig.length}; trạng thái gốc=${orig.map(d=>d.data().maTrangThaiTiepNhan).join(" / ")||"KHÔNG CÓ"}`);
  }
  console.log("\nGHI CHÚ: Tool này KHÔNG thể tự xác định người hoặc function đã ghi; để xác định tác nhân phải xem Cloud Logging / Firestore Data Access audit logs (nếu đã bật trước đó). Tool không thay đổi dữ liệu.");
}
main().catch(e => { console.error("LỖI:", e.message); process.exitCode = 1; });
