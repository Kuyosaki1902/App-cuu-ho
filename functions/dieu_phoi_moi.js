"use strict";

const CONTACT_RESULTS = Object.freeze({
  da_tiep_nhan: "Đã liên hệ – cơ sở đồng ý tiếp nhận",
  khong_tiep_nhan: "Đã liên hệ – cơ sở không tiếp nhận",
  khong_nghe_may: "Không nghe máy",
  khong_lien_lac_duoc: "Số điện thoại không liên lạc được",
  hen_goi_lai: "Hẹn gọi lại",
  khac: "Kết quả khác",
});

const RESCUE_ROLES = new Set([
  "vaitro_cuuhococc",
  "vaitro_cuuhochuacocc",
]);

function validRadius(value) {
  return [1, 3, 5].includes(Number(value));
}

function normalizeCandidateUids(value) {
  if (!Array.isArray(value) || value.length < 1 || value.length > 3) {
    throw new TypeError("Chỉ được gửi lời mời cho tối đa 3 người cứu hộ.");
  }
  const ids = value.map((raw) => {
    if (
      typeof raw !== "string" ||
      !raw.trim() ||
      raw.includes("/") ||
      raw.length > 200
    ) {
      throw new TypeError("Mã người cứu hộ không hợp lệ.");
    }
    return raw.trim();
  });
  if (new Set(ids).size !== ids.length) {
    throw new TypeError("Danh sách người cứu hộ bị trùng.");
  }
  return ids;
}

function profileApproved(value) {
  return [
    "da_duyet",
    "cuuho_trangthai_hoso_daduyet",
    "cuuho_trangthai_daduyet",
  ].includes(typeof value === "string" ? value.trim() : "");
}

function rescueReady(user, restriction = {}) {
  return Boolean(
    user &&
    RESCUE_ROLES.has(user.maVaiTro) &&
    user.isOnline === true &&
    user.nhanCaCuuHo !== true &&
    restriction.khoa !== true &&
    restriction.tamNgungHoTro !== true
  );
}

function distanceKm(lat1, lon1, lat2, lon2) {
  const radians = Math.PI / 180;
  const a =
    Math.sin(((lat2 - lat1) * radians) / 2) ** 2 +
    Math.cos(lat1 * radians) *
      Math.cos(lat2 * radians) *
      Math.sin(((lon2 - lon1) * radians) / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(Math.max(0, Math.min(1, a))));
}

function validCoordinates(lat, lon) {
  const number = (value) =>
    typeof value === "number"
      ? value
      : typeof value === "string" && value.trim()
        ? Number(value)
        : Number.NaN;
  const latitude = number(lat);
  const longitude = number(lon);
  return Number.isFinite(latitude) &&
    Number.isFinite(longitude) &&
    Math.abs(latitude) <= 90 &&
    Math.abs(longitude) <= 180;
}

function validContactResult(value) {
  return Object.hasOwn(CONTACT_RESULTS, value);
}

function adminMirror() {
  return { maNguoiDung: "admin", hoTen: "admin" };
}

function isAdminMirrorCompatible(value = {}) {
  const name = typeof value.hoTen === "string"
    ? value.hoTen.trim().toLowerCase()
    : "";
  return (!value.maNguoiDung || value.maNguoiDung === "admin") &&
    (!value.maVaiTro || value.maVaiTro === "vaitro_admin") &&
    (!name || name === "admin");
}

module.exports = {
  CONTACT_RESULTS,
  validRadius,
  normalizeCandidateUids,
  profileApproved,
  rescueReady,
  distanceKm,
  validCoordinates,
  validContactResult,
  adminMirror,
  isAdminMirrorCompatible,
};
