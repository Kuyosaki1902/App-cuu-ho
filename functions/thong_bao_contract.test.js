const { test } = require("node:test");
const assert = require("node:assert/strict");
const {
  NEW_REQUEST_NOTICE,
  intervention,
  interventionEvent,
  replyEvent,
  replyNotice,
  notifyAdmins,
  sendNotice,
  MAX_SEND_ATTEMPTS,
} = require("./thong_bao");
const { CHO, DONG_Y } = require("./dieu_phoi");

test("Thông báo ca mới nói rõ đang chờ Admin tiếp nhận, không khẳng định đã điều phối", () => {
  assert.equal(NEW_REQUEST_NOTICE.title, "Yêu cầu cứu hộ mới");
  assert.match(NEW_REQUEST_NOTICE.body, /đang chờ Admin tiếp nhận/);
  assert.doesNotMatch(NEW_REQUEST_NOTICE.body, /đã điều phối|đã phân công/i);
  assert.equal(NEW_REQUEST_NOTICE.kind, "ca_moi");
  assert.equal(NEW_REQUEST_NOTICE.eventCode, "yeu_cau_moi");
});

test("Sự kiện cần can thiệp được phân loại cụ thể, không báo ở GPS update", () => {
  const open = { maTinhTrangYeuCau: "user_tinhtrang_dangcuuho" };

  const staff = interventionEvent(open, {
    ...open,
    canBoSungNhanLuc: true,
  });
  assert.equal(staff.eventCode, "can_bo_sung_nhan_luc");
  assert.equal(staff.title, "Ca cứu hộ cần bổ sung nhân lực");

  const review = interventionEvent(open, {
    ...open,
    canKiemTra: true,
  });
  assert.equal(review.eventCode, "can_kiem_tra");

  assert.equal(
    interventionEvent(
      { ...open, canKiemTra: true },
      { ...open, canKiemTra: true, viDo: 10 },
    ),
    null,
  );
  assert.equal(
    intervention(open, {
      ...open,
      trangThaiXacNhanHoanThanh: "qua_han_cho_admin",
    }),
    true,
  );
});

test("Phản hồi lời mời có mã sự kiện và tiêu đề riêng cho từng kết quả", () => {
  const pending = { maTrangThaiTiepNhan: CHO[2] };

  const accepted = replyEvent(pending, {
    maTrangThaiTiepNhan: DONG_Y[1],
  });
  assert.equal(accepted.eventCode, "loi_moi_da_nhan");
  assert.equal(accepted.title, "Cứu hộ viên đã nhận ca");

  const declined = replyEvent(pending, {
    maTrangThaiTiepNhan: "cuuho_trangthai_phancong_tuchoi",
  });
  assert.equal(declined.eventCode, "loi_moi_tu_choi");
  assert.equal(declined.title, "Cứu hộ viên từ chối lời mời");

  const expired = replyEvent(pending, {
    maTrangThaiTiepNhan: "cuuho_trangthai_phancong_dahuy",
    lyDoKetThuc: "het_han",
  });
  assert.equal(expired.eventCode, "loi_moi_het_han");
  assert.equal(expired.title, "Lời mời cứu hộ đã hết hạn");

  assert.equal(replyNotice(pending, {
    maTrangThaiTiepNhan: DONG_Y[1],
  }), accepted.body);
});


function createMockNoticeStore(admins, devicesByAdmin = {}) {
  const noticeDocs = new Map();

  function query(rows) {
    const result = {
      where() { return result; },
      orderBy() { return result; },
      limit() { return result; },
      startAfter() { return result; },
      get: async () => ({
        docs: rows.map((row) => ({
          id: row.id,
          data: () => row.data,
          ref: row.ref,
        })),
        size: rows.length,
      }),
    };
    return result;
  }

  const db = {
    collection(name) {
      if (name === "Admin") {
        return {
          doc(uid) {
            return {
              get: async () => ({ data: () => admins[uid] }),
              collection(subcollection) {
                assert.equal(subcollection, "ThietBi");
                const rows = devicesByAdmin[uid] || [];
                return query(rows);
              },
            };
          },
          where() {
            const active = Object.entries(admins)
              .filter(([, data]) => data.trangThai === "hoat_dong")
              .map(([id, data]) => ({ id, data }));
            return query(active);
          },
        };
      }

      if (name === "ThongBao") {
        return {
          doc(id) {
            return {
              id,
              create: async (data) => {
                if (noticeDocs.has(id)) {
                  const error = new Error("already exists");
                  error.code = 6;
                  throw error;
                }
                noticeDocs.set(id, data);
              },
            };
          },
        };
      }

      throw new Error(`Unexpected collection ${name}`);
    },
    runTransaction: async (callback) => callback({
      get: async (ref) => ({ data: () => ref.data }),
      update: (ref, patch) => {
        for (const [key, value] of Object.entries(patch)) {
          if (value && value.__delete === true) {
            delete ref.data[key];
          } else {
            ref.data[key] = value;
          }
        }
      },
      delete: async () => {},
    }),
  };

  return { db, noticeDocs };
}

test("Admin phụ trách không có thiết bị thì fan-out đến Admin hoạt động khác", async () => {
  const { db, noticeDocs } = createMockNoticeStore({
    owner: { trangThai: "hoat_dong" },
    admin2: { trangThai: "hoat_dong" },
    admin3: { trangThai: "hoat_dong" },
    disabled: { trangThai: "khoa" },
  });

  const ownerNotice = {
    id: "notice-owner",
    path: "ThongBao/notice-owner",
    data: {
      maNguoiDung: "owner",
      maYeuCau: "yeucau-100",
      maSuKien: "loi_moi_da_nhan",
      maSuKienNguon: "firestore-event-100",
      loai: "phan_hoi_dieu_phoi",
      mucDoUuTien: "quan_trong",
      tieuDe: "Cứu hộ viên đã nhận ca",
      noiDung: "Mã yêu cầu: yeucau-100.",
      cheDoNhan: "admin_phu_trach",
      maAdminPhuTrach: "owner",
      nguon: "cloud_function",
      trangThaiDay: "cho_gui",
      soLanThu: 0,
    },
    async update(patch) { Object.assign(this.data, patch); },
    collection(name) {
      assert.equal(name, "DaGui");
      return { get: async () => ({ docs: [], size: 0 }) };
    },
  };

  const result = await sendNotice(db, ownerNotice, {
    send: async () => {
      throw new Error("Không được gửi khi Admin không có thiết bị.");
    },
  });

  assert.equal(result.trangThaiDay, "khong_co_thiet_bi");
  assert.equal(ownerNotice.data.soAdminChuyenTiep, 2);
  assert.equal(noticeDocs.size, 2);

  const recipients = [...noticeDocs.values()]
    .map((notice) => notice.maNguoiDung)
    .sort();
  assert.deepEqual(recipients, ["admin2", "admin3"]);
  for (const notice of noticeDocs.values()) {
    assert.equal(notice.cheDoNhan, "all_active");
    assert.equal(notice.maAdminPhuTrach, "owner");
    assert.equal(notice.maSuKien, "loi_moi_da_nhan");
  }
});

test("Admin phụ trách không hoạt động thì vẫn chuyển tiếp all-active", async () => {
  const { db, noticeDocs } = createMockNoticeStore({
    owner: { trangThai: "khoa" },
    admin2: { trangThai: "hoat_dong" },
  });
  const ownerNotice = {
    id: "notice-owner-inactive",
    path: "ThongBao/notice-owner-inactive",
    data: {
      maNguoiDung: "owner",
      maYeuCau: "yeucau-101",
      maSuKien: "can_kiem_tra",
      maSuKienNguon: "firestore-event-101",
      loai: "can_can_thiep",
      mucDoUuTien: "khan_cap",
      tieuDe: "Ca cần kiểm tra",
      noiDung: "Mã yêu cầu: yeucau-101.",
      cheDoNhan: "admin_phu_trach",
      maAdminPhuTrach: "owner",
      nguon: "cloud_function",
      trangThaiDay: "cho_gui",
      soLanThu: 0,
    },
    async update(patch) { Object.assign(this.data, patch); },
    collection(name) {
      assert.equal(name, "DaGui");
      return { get: async () => ({ docs: [], size: 0 }) };
    },
  };

  const result = await sendNotice(db, ownerNotice, {
    send: async () => {
      throw new Error("Không có thiết bị người nhận.");
    },
  });

  assert.equal(result.trangThaiDay, "nguoi_nhan_khong_hoat_dong");
  assert.equal(noticeDocs.size, 1);
  assert.equal([...noticeDocs.values()][0].maNguoiDung, "admin2");
});

test("Lỗi FCM lặp lại được chặn sau số lần thử tối đa", async () => {
  const deviceRef = {
    async get() { return { data: () => ({ token: "token-admin" }) }; },
  };
  const device = {
    id: "device-1",
    data: { token: "token-admin" },
    ref: deviceRef,
  };
  const { db } = createMockNoticeStore(
    { owner: { trangThai: "hoat_dong" } },
    { owner: [device] },
  );
  const notice = {
    id: "notice-retry",
    path: "ThongBao/notice-retry",
    data: {
      maNguoiDung: "owner",
      maYeuCau: "yeucau-102",
      maSuKien: "yeu_cau_moi",
      loai: "ca_moi",
      mucDoUuTien: "khan_cap",
      tieuDe: "Yêu cầu cứu hộ mới",
      noiDung: "Mã yêu cầu: yeucau-102.",
      cheDoNhan: "all_active",
      nguon: "cloud_function",
      trangThaiDay: "cho_gui",
      soLanThu: 0,
    },
    async update(patch) { Object.assign(this.data, patch); },
    collection(name) {
      assert.equal(name, "DaGui");
      return { get: async () => ({ docs: [], size: 0 }) };
    },
  };

  const messaging = {
    send: async () => {
      const error = new Error("FCM temporarily unavailable");
      error.code = "messaging/internal-error";
      throw error;
    },
  };

  for (let attempt = 1; attempt < MAX_SEND_ATTEMPTS; attempt++) {
    await assert.rejects(sendNotice(db, notice, messaging));
    assert.equal(notice.data.soLanThu, attempt);
    assert.equal(notice.data.trangThaiDay, "cho_gui");
  }

  const final = await sendNotice(db, notice, messaging);
  assert.equal(final.trangThaiDay, "gui_loi");
  assert.equal(notice.data.soLanThu, MAX_SEND_ATTEMPTS);
  assert.equal(notice.data.trangThaiDay, "gui_loi");
});
