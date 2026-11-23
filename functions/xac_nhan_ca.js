"use strict";

const { Timestamp, FieldValue } = require("firebase-admin/firestore");
const { belongsToRequest, DANG_NHAN_THUC_TE, DA_THAM_GIA,
  CHUA_DONG_Y, CHO_HOAC_QUA_HAN, CHO_NGUOI, MO } = require("./dieu_phoi");

const TRANG_THAI_CA_HOAN_THANH = "user_tinhtrang_hoanthanh";
const TRANG_THAI_PHAN_CONG_HOAN_THANH = "cuuho_trangthai_phancong_hoanthanh";
const TRANG_THAI_DA_HUY = [
  "da_huy", "tu_choi", "cuuho_trangthai_phancong_dahuy",
  "cuuho_trangthai_phancong_tuchoi",
];
const XAC_NHAN = Object.freeze({
  CHO_NAN_NHAN: "cho_nan_nhan",
  QUA_HAN_CHO_ADMIN: "qua_han_cho_admin",
  CAN_CAN_THIEP: "can_can_thiep",
  DA_HOAN_THANH: "da_hoan_thanh",
});

function laCaDangMo(request) {
  return Boolean(request && MO.includes(request.maTinhTrangYeuCau));
}

function ketQuaDaDuDieuKien(phanCong) {
  return phanCong.daCoNguoiBaoXong && !phanCong.conNguoiDangLam && !phanCong.conLoiMoiCho;
}

function taoBanGhiChoXacNhan(request, gioCho, now = Timestamp.now()) {
  const state = request.trangThaiXacNhanHoanThanh;
  const patch = {
    thoiGianCuuHoBaoHoanThanh: request.thoiGianCuuHoBaoHoanThanh || now,
    canBoSungNhanLuc: false,
  };
  // Ca đã chuyển cho quản trị viên thì không bắt đầu lại thời gian chờ.
  if ([XAC_NHAN.QUA_HAN_CHO_ADMIN, XAC_NHAN.CAN_CAN_THIEP]
      .includes(state)) return patch;
  patch.trangThaiXacNhanHoanThanh = XAC_NHAN.CHO_NAN_NHAN;
  patch.hanXacNhanHoanThanh = request.hanXacNhanHoanThanh instanceof Timestamp
    ? request.hanXacNhanHoanThanh
    : Timestamp.fromMillis(now.toMillis() + gioCho * 60 * 60 * 1000);
  return patch;
}

function capNhatCaChoXacNhan(request, gioCho) {
  const patch = taoBanGhiChoXacNhan(request, gioCho);
  if (CHO_HOAC_QUA_HAN.includes(request.maTinhTrangYeuCau)) {
    patch.maTinhTrangYeuCau = "user_tinhtrang_daphancong";
  }
  return patch;
}

function taoBanGhiDongCa(request, nguon, nguoi, lyDo, now = Timestamp.now()) {
  return {
    maTinhTrangYeuCau: TRANG_THAI_CA_HOAN_THANH,
    trangThaiXacNhanHoanThanh: XAC_NHAN.DA_HOAN_THANH,
    thoiGianHoanThanh: now,
    nguonXacNhanHoanThanh: nguon,
    maNguoiXacNhanHoanThanh: nguoi || null,
    thoiGianXacNhanHoanThanh: now,
    lyDoXacNhanHoanThanh: lyDo || null,
    canKiemTra: false,
    canBoSungNhanLuc: false,
  };
}

async function docPhanCongCuaCa(tx, db, request) {
  const rows = await tx.get(db.collectionGroup("DanhSachPhanCong")
    .where("maYeuCau", "==", request.id));
  return rows.docs.filter(doc => belongsToRequest(doc, request)).map(doc => doc.data());
}

function tongQuan(rows) {
  const states = rows.map(row => row.maTrangThaiTiepNhan);
  return {
    conNguoiDangLam: states.some(s => DANG_NHAN_THUC_TE.includes(s)),
    conLoiMoiCho: states.some(s => CHUA_DONG_Y.includes(s)),
    daCoNguoiBaoXong: states.includes(TRANG_THAI_PHAN_CONG_HOAN_THANH),
  };
}

async function docTongQuanPhanCong(tx, db, request) {
  return tongQuan(await docPhanCongCuaCa(tx, db, request));
}

async function doiChieuCaSauPhanCong(db, maYeuCau, uid, sourceRef, gioCho, eventSnapshot) {
  const requestRef = db.collection("YeuCauCuuHo").doc(maYeuCau);
  return db.runTransaction(async (tx) => {
    const [source, snap] = await Promise.all([
      tx.get(sourceRef), tx.get(requestRef),
    ]);
    const request = snap.data();
    if (!laCaDangMo(request)) return "bo_qua";

    const row = source.data();
    if (row && (row.maYeuCau !== maYeuCau || row.maNguoiCuuHo !== uid)) {
      return "du_lieu_phan_cong_sai";
    }
    if (!belongsToRequest(row ? source : eventSnapshot || source, snap) ||
        (eventSnapshot && !belongsToRequest(eventSnapshot, snap))) return "khac_lan_tao_ca";
    const rows = await docPhanCongCuaCa(tx, db, snap);
    const state = tongQuan(rows);
    const patch = {};
    const status = row?.maTrangThaiTiepNhan;
    const beforeSummary = request.danhSachPhanCongVien;
    const old = beforeSummary && typeof beforeSummary === "object" &&
      !Array.isArray(beforeSummary) ? beforeSummary[uid] : undefined;
    if (request.maLoiMoiDieuPhoi &&
      row?.maPhanCong === request.maLoiMoiDieuPhoi &&
      (DA_THAM_GIA.includes(status) || TRANG_THAI_DA_HUY.includes(status))) {
      patch.maLoiMoiDieuPhoi = null;
      patch.phienBanDieuPhoi = (request.phienBanDieuPhoi || 0) + 1;
      patch.ngayDieuPhoi = FieldValue.serverTimestamp();
    }

    const choXacNhan = ketQuaDaDuDieuKien(state);
    if (choXacNhan) {
      Object.assign(patch, capNhatCaChoXacNhan(request, gioCho));
    } else if (state.conNguoiDangLam || state.conLoiMoiCho) {
      if (state.conNguoiDangLam && CHO_HOAC_QUA_HAN.includes(request.maTinhTrangYeuCau)) {
        patch.maTinhTrangYeuCau = "user_tinhtrang_daphancong";
        if (!request.thoiGianPhanCong) patch.thoiGianPhanCong = FieldValue.serverTimestamp();
      }
      if (request.trangThaiXacNhanHoanThanh === XAC_NHAN.CHO_NAN_NHAN) {
        patch.trangThaiXacNhanHoanThanh = null;
        patch.hanXacNhanHoanThanh = null;
      }
    } else if (!state.daCoNguoiBaoXong &&
        DA_THAM_GIA.includes(old) &&
        !CHO_NGUOI.includes(request.maTinhTrangYeuCau)) {
      // Người từng nhận ca đã rút và chưa ai báo xong.
      patch.canBoSungNhanLuc = true;
      patch.maTinhTrangYeuCau = "user_tinhtrang_quahandieuphoi";
    }
    if (Object.keys(patch).length === 0) return "khong_thay_doi";
    tx.update(requestRef, patch);
    return choXacNhan ? "cho_nan_nhan" : "da_doi_chieu";
  });
}

async function kiemTraCaSauHetHanLoiMoi(db, maYeuCau, gioCho) {
  const requestRef = db.collection("YeuCauCuuHo").doc(maYeuCau);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(requestRef);
    const request = snap.data();
    if (!laCaDangMo(request)) return "bo_qua";
    const state = await docTongQuanPhanCong(tx, db, snap);
    if (!ketQuaDaDuDieuKien(state)) return "chua_du_dieu_kien";
    const patch = capNhatCaChoXacNhan(request, gioCho);
    tx.update(requestRef, patch);
    return "cho_nan_nhan";
  });
}

module.exports = {
  TRANG_THAI_CA_HOAN_THANH, TRANG_THAI_PHAN_CONG_HOAN_THANH,
  XAC_NHAN, laCaDangMo, ketQuaDaDuDieuKien,
  taoBanGhiChoXacNhan, taoBanGhiDongCa, docTongQuanPhanCong,
  doiChieuCaSauPhanCong, kiemTraCaSauHetHanLoiMoi,
};
