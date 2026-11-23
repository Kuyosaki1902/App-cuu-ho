const { HttpsError } = require("firebase-functions/v2/https");
const { Timestamp, FieldValue } = require("firebase-admin/firestore");

const CHO = [
  "da_gui_thong_bao",
  "cuuho_trangthai_chophanhoi",
  "cuuho_trangthai_phancong_chotiepnhan",
];
const DONG_Y = ["da_dong_y", "cuuho_trangthai_phancong_tiepnhan"];
// Cứu hộ viên có thể đã được chọn nhưng vẫn chưa nhận lời.
const DANG_NHAN_THUC_TE = [...DONG_Y,
  "cuuho_trangthai_phancong_daden",
  "cuuho_trangthai_phancong_dangcuuho",
];
const DA_THAM_GIA = [...DANG_NHAN_THUC_TE, "cuuho_trangthai_phancong_hoanthanh"];
const CHUA_DONG_Y = [...CHO,
  "duoc_chon", "cuuho_trangthai_phancong_daphancong"];
const DA_CHON = [
  "duoc_chon",
  "cuuho_trangthai_phancong_daphancong",
  "cuuho_trangthai_phancong_daden",
  "cuuho_trangthai_phancong_dangcuuho",
];
const MO = [
  "cho_tiep_nhan",
  "qua_han_dieu_phoi",
  "da_phan_cong",
  "dang_cuu_ho",
  "user_tinhtrang_chotiepnhan",
  "user_tinhtrang_quahandieuphoi",
  "user_tinhtrang_daphancong",
  "user_tinhtrang_dangcuuho",
];
const fail = (message, code = "failed-precondition") => {
  throw new HttpsError(code, message);
};
function id(value) {
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value.includes("/") ||
    value.length > 200
  ) {
    fail("Mã dữ liệu không hợp lệ.", "invalid-argument");
  }
  return value;
}
// Nếu biết giờ gửi, lời mời hết hạn sau 3 phút.
function invitationDeadline(data, created) {
  const sent = timeMillis(data.thoiGianGui);
  const explicit = timeMillis(data.hanPhanHoi);
  if (sent === null) {
    const start = timeMillis(created);
    return explicit ?? (start === null ? null : start + 180000);
  }
  return sent + 180000;
}
const expired = (data, now, created) => {
  const due = invitationDeadline(data, created);
  return due !== null && due <= now;
};
const stamp = () => FieldValue.serverTimestamp();

// Dùng mốc tạo của ca hiện tại. updateTime có thể đổi khi phân công cũ được sửa.
function belongsToRequest(assignment, request) {
  const created = timeMillis(request.createTime);
  const declared = timeMillis(request.data()?.thoiGianTao);
  const sent = timeMillis(assignment.data()?.thoiGianGui);
  const recorded = timeMillis(assignment.createTime);
  if (created === null && declared === null) return false;
  if (sent !== null && sent < (declared ?? created)) return false;
  if (recorded !== null && recorded < (created ?? declared)) {
    // Cùng UID, ngày và mã ca có thể dùng lại đường dẫn cho một lời mời mới.
    return sent !== null && sent >= (created ?? declared);
  }
  return recorded !== null || sent !== null;
}

// Chỉ gỡ UID khi mọi phân công theo ngày của người đó đều thuộc ca cũ.
async function removeHistoricalMembers(db, ref, changed) {
  if (!changed.length) return;
  await db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    const request = snap.data();
    const map = request?.danhSachPhanCongVien;
    if (!map || typeof map !== "object" || Array.isArray(map)) return;
    const candidates = changed.filter(([uid, status]) => map[uid] === status);
    if (!candidates.length) return;
    const start = timeMillis(request.thoiGianTao) ?? timeMillis(snap.createTime);
    if (start === null) return;
    const rows = await tx.get(db.collectionGroup("DanhSachPhanCong")
      .where("maYeuCau", "==", ref.id));
    const cleaned = {...map};
    for (const [uid, status] of candidates) {
      const assignments = rows.docs.filter(doc => doc.data().maNguoiCuuHo === uid);
      const allOld = assignments.every(doc => {
        const sent = timeMillis(doc.data().thoiGianGui);
        const created = timeMillis(doc.createTime);
        return sent !== null && sent < start && (created === null || created < start);
      });
      if (allOld && assignments.some(doc => doc.data().maTrangThaiTiepNhan === status)) {
        delete cleaned[uid];
      }
    }
    if (Object.keys(cleaned).length < Object.keys(map).length) {
      tx.update(ref, {danhSachPhanCongVien: cleaned});
    }
  });
}

async function expireInvitation(db, ref, expectedId) {
  return db.runTransaction(async tx => {
    const snapshot = await tx.get(ref);
    const p = snapshot.data();
    if (!p || p.maPhanCong !== expectedId || p.maYeuCau !== ref.id ||
        !CHO.includes(p.maTrangThaiTiepNhan) || !expired(p, Date.now(), snapshot.createTime)) return false;
    const request = db.collection("YeuCauCuuHo").doc(id(p.maYeuCau));
    const requestSnap = await tx.get(request);
    const data = requestSnap.data();
    const current = data && belongsToRequest(snapshot, requestSnap);

    tx.update(ref, {maTrangThaiTiepNhan: "cuuho_trangthai_phancong_dahuy",
      lyDoKetThuc: "het_han", thoiGianPhanHoi: stamp()});
    if (current && data.maLoiMoiDieuPhoi === expectedId) {
      tx.update(request, {maLoiMoiDieuPhoi: null, phienBanDieuPhoi: (data.phienBanDieuPhoi || 0) + 1,
        ngayDieuPhoi: stamp()});
    }
    return true;
  });
}

const CHO_NGUOI = ["cho_tiep_nhan", "user_tinhtrang_chotiepnhan"];
const QUA_HAN = ["qua_han_dieu_phoi", "user_tinhtrang_quahandieuphoi"];
const CHO_HOAC_QUA_HAN = [...CHO_NGUOI, ...QUA_HAN];
const DANG_NHAN = [...DONG_Y, ...DA_CHON];

function timeMillis(value) {
  if (value instanceof Timestamp) return value.toMillis();
  // Một số ca cũ lưu ngày dưới dạng chữ. Chỉ đọc được giờ chính xác khi có múi giờ.
  if (
    typeof value === "string" &&
    /^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})$/.test(value)
  ) {
    const time = Date.parse(value);
    if (Number.isFinite(time)) return time;
  }
  return null;
}
function deadline(data, seconds) {
  if (Object.hasOwn(data, "hanTimNguoi")) return timeMillis(data.hanTimNguoi);
  const created = timeMillis(data.thoiGianTao);
  return created === null ? null : created + seconds * 1000;
}
async function initializeDeadline(db, ref, seconds) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref),
      data = snap.data();
    if (
      !data ||
      !CHO_NGUOI.includes(data.maTinhTrangYeuCau) ||
      Object.hasOwn(data, "hanTimNguoi")
    )
      return;
    const created = timeMillis(data.thoiGianTao) ?? snap.createTime.toMillis();
    tx.update(ref, {
      hanTimNguoi: Timestamp.fromMillis(created + seconds * 1000),
    });
  });
}

async function reconcileRequest(db, ref, seconds, now = Date.now()) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref),
      data = snap.data();
    if (!data || !MO.includes(data.maTinhTrangYeuCau)) return "ignored";
    const assignments = await tx.get(
      db
        .collectionGroup("DanhSachPhanCong")
        .where("maYeuCau", "==", ref.id)
        .where("maTrangThaiTiepNhan", "in", DANG_NHAN_THUC_TE),
    );
    const active = assignments.docs.filter(
      (d) =>
        belongsToRequest(d, snap) &&
        typeof d.data().maNguoiCuuHo === "string" &&
        d.data().maNguoiCuuHo.length > 0,
    );
    if (active.length) {
      const patch = {};
      if (CHO_HOAC_QUA_HAN.includes(data.maTinhTrangYeuCau)) {
        patch.maTinhTrangYeuCau = "user_tinhtrang_daphancong";
        if (!data.thoiGianPhanCong) patch.thoiGianPhanCong = stamp();
      }
      if (active.some((d) => d.data().maPhanCong && d.data().maPhanCong === data.maLoiMoiDieuPhoi))
        patch.maLoiMoiDieuPhoi = null;
      if (!Object.keys(patch).length) return "unchanged";
      tx.update(ref, {
        ...patch,
        ngayDieuPhoi: stamp(),
        phienBanDieuPhoi: (data.phienBanDieuPhoi || 0) + 1,
      });
      return "accepted";
    }
    if (!CHO_NGUOI.includes(data.maTinhTrangYeuCau)) return "ignored";
    const due = deadline(data, seconds);
    if (due === null || due > now) return "waiting";
    // Ca từng có người nhận cần được kiểm tra trước khi đánh dấu quá hạn.
    if (
      Number(data.soNguoiCuuHo) > 0 ||
      data.thoiGianPhanCong ||
      (data.danhSachPhanCongVien &&
        Object.values(data.danhSachPhanCongVien).some(status =>
          DA_THAM_GIA.includes(status)))
    )
      return "conflict";
    tx.update(ref, {
      maTinhTrangYeuCau: "user_tinhtrang_quahandieuphoi",
      hanTimNguoi: Timestamp.fromMillis(due),
      ngayQuaHanDieuPhoi: stamp(),
      lyDoCanDieuPhoi: "qua_han_chua_co_nguoi_tiep_nhan",
    });
    return "overdue";
  });
}

async function scanWaitingRequests(db, seconds, now = Date.now()) {
  const counts = {};
  // Ca cũ có thể lưu ngày tạo dưới dạng chữ, còn ca mới thường dùng Timestamp.
  const cutoff = Timestamp.fromMillis(now);
  const nextDay = new Date(now + 86400000).toISOString().slice(0, 10);
  const scans = [
    { field: "thoiGianTao", upper: cutoff, batchSize: 10 },
    { field: "thoiGianTao", upper: nextDay, batchSize: 10 },
    // Một số ca chỉ có hạn tìm người do máy chủ đặt.
    { field: "hanTimNguoi", upper: cutoff, batchSize: 1 },
  ];
  for (const { field, upper, batchSize } of scans) {
    const base = db.collection("YeuCauCuuHo")
      .where("maTinhTrangYeuCau", "in", CHO_NGUOI)
      .where(field, "<=", upper)
      .orderBy(field)
      .limit(100);
    let query = base;
    for (let page = 0; page < 10; page++) {
      const rows = await query.get();
      for (let i = 0; i < rows.size; i += batchSize) {
        const group = rows.docs.slice(i, i + batchSize);
        const statuses = await Promise.all(
          group.map(row => reconcileRequest(db, row.ref, seconds, now)),
        );
        for (const status of statuses) counts[status] = (counts[status] || 0) + 1;
      }
      if (rows.size < 100) break;
      if (page === 9) counts.remaining = true;
      else query = base.startAfter(rows.docs.at(-1));
    }
  }
  return counts;
}
module.exports = {
  removeHistoricalMembers,
  belongsToRequest,
  invitationDeadline, expireInvitation, expired, CHO, DONG_Y, DA_CHON,
  DANG_NHAN_THUC_TE, DA_THAM_GIA, CHUA_DONG_Y, MO, id, QUA_HAN, CHO_HOAC_QUA_HAN,
  CHO_NGUOI,
  DANG_NHAN,
  timeMillis,
  deadline,
  initializeDeadline,
  reconcileRequest,
  scanWaitingRequests,
};
