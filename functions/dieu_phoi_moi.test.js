const { test } = require("node:test");
const assert = require("node:assert/strict");
const {
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
} = require("./dieu_phoi_moi");

test("Bán kính điều phối chỉ nhận các mốc đang có trong App Admin", () => {
  assert.equal(validRadius(1), true);
  assert.equal(validRadius(3), true);
  assert.equal(validRadius(5), true);
  assert.equal(validRadius(2), false);
  assert.equal(validRadius("5"), true);
});

test("Danh sách mời đồng thời phải có từ 1 đến 3 UID hợp lệ, không trùng", () => {
  assert.deepEqual(normalizeCandidateUids(["u1", "u2", "u3"]), ["u1", "u2", "u3"]);
  assert.throws(() => normalizeCandidateUids([]));
  assert.throws(() => normalizeCandidateUids(["u1", "u2", "u3", "u4"]));
  assert.throws(() => normalizeCandidateUids(["u1", "u1"]));
  assert.throws(() => normalizeCandidateUids(["bad/uid"]));
});

test("Hồ sơ cứu hộ chỉ được xem là đã duyệt với mã trạng thái hiện hành/alias", () => {
  assert.equal(profileApproved("cuuho_trangthai_hoso_daduyet"), true);
  assert.equal(profileApproved("da_duyet"), true);
  assert.equal(profileApproved("cuuho_trangthai_hoso_tiepnhan"), false);
});

test("Điều kiện online, vai trò, cờ nhận ca và hạn chế được giữ nguyên", () => {
  const user = {
    maVaiTro: "vaitro_cuuhococc",
    isOnline: true,
    nhanCaCuuHo: false,
  };
  assert.equal(rescueReady(user, {}), true);
  assert.equal(rescueReady({ ...user, isOnline: false }, {}), false);
  assert.equal(rescueReady({ ...user, nhanCaCuuHo: true }, {}), false);
  assert.equal(rescueReady({ ...user, maVaiTro: "vaitro_nguoidung" }, {}), false);
  assert.equal(rescueReady(user, { khoa: true }), false);
  assert.equal(rescueReady(user, { tamNgungHoTro: true }), false);
});

test("Tính khoảng cách và tọa độ dùng được cho lọc bán kính", () => {
  assert.equal(validCoordinates(10.7, 106.6), true);
  assert.equal(validCoordinates(100, 106.6), false);
  assert.equal(validCoordinates("x", 106.6), false);
  assert.equal(validCoordinates(null, 106.6), false);
  assert.equal(validCoordinates("", 106.6), false);
  assert.ok(distanceKm(10, 106, 10, 106) < 0.001);
  assert.ok(distanceKm(10, 106, 10.009, 106) > 0.9);
  assert.ok(distanceKm(10, 106, 10.009, 106) < 1.1);
});

test("Chỉ chấp nhận các kết quả liên hệ đã định nghĩa", () => {
  for (const key of Object.keys(CONTACT_RESULTS)) {
    assert.equal(validContactResult(key), true);
  }
  assert.equal(validContactResult("success"), false);
});

test("Mirror NguoiDung của Admin dùng Document ID cố định admin", () => {
  assert.deepEqual(adminMirror(), {
    maNguoiDung: "admin",
    hoTen: "admin",
  });
  assert.equal(isAdminMirrorCompatible({}), true);
  assert.equal(isAdminMirrorCompatible({ hoTen: "Admin" }), true);
  assert.equal(isAdminMirrorCompatible({ maNguoiDung: "other" }), false);
  assert.equal(isAdminMirrorCompatible({ maVaiTro: "vaitro_nguoidung" }), false);
  assert.equal(isAdminMirrorCompatible({ hoTen: "Nguyễn Văn A" }), false);
});
