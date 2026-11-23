const { test } = require("node:test");
const assert = require("node:assert/strict");
const { Timestamp } = require("firebase-admin/firestore");
const {
  invitationDeadline,
  expireInvitation,
  expired,
  CHO,
  DONG_Y,
  DA_CHON,
  DANG_NHAN,
  deadline,
  initializeDeadline,
  reconcileRequest,
  scanWaitingRequests,
} = require("./dieu_phoi");
const {
  intervention,
  replyNotice,
  notifyAdmins,
  sendNotice,
} = require("./thong_bao");

test("Trạng thái phân công của team được nhận diện là chờ/đang hỗ trợ", () => {
  assert.ok(CHO.includes("cuuho_trangthai_phancong_chotiepnhan"));
  assert.ok(DANG_NHAN.includes("cuuho_trangthai_phancong_tiepnhan"));
  assert.ok(DA_CHON.includes("cuuho_trangthai_phancong_daden"));
  assert.ok(DA_CHON.includes("cuuho_trangthai_phancong_dangcuuho"));
});

test("Thời hạn: thiếu dữ liệu không tự hết hạn, đúng mốc thì hết hạn", () => {
  assert.equal(expired({}, 1000), false);
  assert.equal(expired({ hanPhanHoi: Timestamp.fromMillis(1000) }, 999), false);
  assert.equal(expired({ hanPhanHoi: Timestamp.fromMillis(1000) }, 1000), true);
});
test("Mỗi lời mời có đúng 180 giây, cả dữ liệu cũ chỉ có thoiGianGui", () => {
  const row = {thoiGianGui:Timestamp.fromMillis(1000)};
  assert.equal(invitationDeadline(row), 181000);
  assert.equal(expired(row,180999),false);
  assert.equal(expired(row,181000),true);
  assert.equal(invitationDeadline({...row,hanPhanHoi:Timestamp.fromMillis(999999)}),181000);
  assert.equal(invitationDeadline({}),null);
});
test("Chỉ báo can thiệp khi chuyển sang cần xử lý, không báo từng GPS update", () => {
  const open = { maTinhTrangYeuCau: "user_tinhtrang_dangcuuho" };
  assert.equal(intervention(open, { ...open, canKiemTra: true }), true);
  assert.equal(
    intervention(
      { ...open, canKiemTra: true },
      { ...open, canKiemTra: true, viDo: 10 },
    ),
    false,
  );
  assert.equal(
    intervention(open, {
      maTinhTrangYeuCau: "user_tinhtrang_hoanthanh",
      canKiemTra: true,
    }),
    false,
  );
});
test("Không báo thao tác admin hủy hoặc các cập nhật không đổi trạng thái", () => {
  const pending = { maTrangThaiTiepNhan: CHO[2] };
  assert.equal(replyNotice(pending, { ...pending, viDo: 1 }), null);
  assert.equal(
    replyNotice(pending, {
      maTrangThaiTiepNhan: "cuuho_trangthai_phancong_dahuy",
    }),
    null,
  );
  assert.ok(replyNotice(pending, { maTrangThaiTiepNhan: DONG_Y[1] }));
  assert.ok(
    replyNotice(pending, {
      maTrangThaiTiepNhan: "cuuho_trangthai_phancong_dahuy",
      lyDoKetThuc: "het_han",
    }),
  );
});

test("Hạn ca lấy từ lúc tạo, ưu tiên hạn đã lưu và không đoán ngày sai", () => {
  const start = Timestamp.fromMillis(1000000);
  assert.equal(deadline({ thoiGianTao: start }, 180), 1180000);
  assert.equal(
    deadline(
      { thoiGianTao: start, hanTimNguoi: Timestamp.fromMillis(1200000) },
      180,
    ),
    1200000,
  );
  assert.equal(
    deadline({ thoiGianTao: "2026-10-30T09:00:00+07:00" }, 180),
    Date.parse("2026-10-30T02:03:00Z"),
  );
  assert.equal(deadline({ thoiGianTao: "30/10/2026" }, 180), null);
  assert.equal(deadline({ thoiGianTao: start, hanTimNguoi: "bad" }, 180), null);
});

test(
  "Firestore emulator: deadline, retry, notification targeting and token cleanup",
  {
    skip: !process.env.FIRESTORE_EMULATOR_HOST,
  },
  async (t) => {
    const { initializeApp, deleteApp } = require("firebase-admin/app");
    const { getFirestore } = require("firebase-admin/firestore");
    const app = initializeApp({ projectId: "demo-cuu-ho-push" }, "tests");
    const db = getFirestore(app);
    const suffix = Date.now().toString();
    const request = db.collection("YeuCauCuuHo").doc(`r${suffix}`);
    const invite = db.doc(`ChiTietPhanCongCuuHo/helper/DanhSachNgay/2026-11-02/DanhSachPhanCong/${request.id}`);
    const attempt = `i${suffix}`;
    await t.test("Hết hạn và chạy lặp không thay đổi lần hai", async () => {
      await request.set({ maLoiMoiDieuPhoi: attempt, phienBanDieuPhoi: 0 });
      await invite.set({
        maPhanCong: attempt, maAdmin: "a",
        maYeuCau: request.id,
        maTrangThaiTiepNhan: CHO[2],
        hanPhanHoi: Timestamp.fromMillis(0),
      });
      assert.equal(await expireInvitation(db, invite, attempt), true);
      assert.equal(await expireInvitation(db, invite, attempt), false);
      assert.equal((await request.get()).data().phienBanDieuPhoi, 1);
      assert.equal((await request.get()).data().maLoiMoiDieuPhoi, null);
    });
    await t.test("Không xóa lời mời mới khi tác vụ cũ tới muộn", async () => {
      await request.update({ maLoiMoiDieuPhoi: "new-invitation" });
      await invite.update({ maTrangThaiTiepNhan: CHO[2] });
      await expireInvitation(db, invite, attempt);
      assert.equal(
        (await request.get()).data().maLoiMoiDieuPhoi,
        "new-invitation",
      );
    });
    await t.test("Không hết hạn lời mời đã đồng ý", async () => {
      await invite.update({ maTrangThaiTiepNhan: DONG_Y[1] });
      assert.equal(await expireInvitation(db, invite, attempt), false);
      assert.equal((await invite.get()).data().maTrangThaiTiepNhan, DONG_Y[1]);
    });
    await t.test(
      "Hai tác vụ chạy cùng lúc chỉ tăng phiên bản một lần",
      async () => {
        await request.update({
          maLoiMoiDieuPhoi: attempt,
          phienBanDieuPhoi: 0,
        });
        await invite.update({ maTrangThaiTiepNhan: CHO[2] });
        const results = await Promise.all([
          expireInvitation(db, invite, attempt),
          expireInvitation(db, invite, attempt),
        ]);
        assert.equal(results.filter(Boolean).length, 1);
        assert.equal((await request.get()).data().phienBanDieuPhoi, 1);
      },
    );
    await t.test("Lời mời tự động cũ hết hạn, giữ nguyên map của app", async () => {
      await request.set({thoiGianTao:Timestamp.fromMillis(Date.now()-240000),
        danhSachPhanCongVien:{helper:CHO[2],other:DONG_Y[1]},
        maLoiMoiDieuPhoi:attempt, phienBanDieuPhoi:0});
      await invite.set({maPhanCong:attempt, maYeuCau:request.id, maNguoiCuuHo:"helper",
        maLoaiPhanCong:"phancong_hethongtudong", maTrangThaiTiepNhan:CHO[2],
        thoiGianGui:Timestamp.fromMillis(Date.now()-181000)});
      assert.equal(await expireInvitation(db,invite,attempt),true);
      assert.equal((await invite.get()).data().lyDoKetThuc,"het_han");
      const saved=(await request.get()).data();
      assert.equal(saved.maLoiMoiDieuPhoi,null);
      assert.equal(saved.danhSachPhanCongVien.helper,CHO[2]);
      assert.equal(saved.danhSachPhanCongVien.other,DONG_Y[1]);
      const waiting=await db.collectionGroup("DanhSachPhanCong")
        .where("maNguoiCuuHo","==","helper").where("maTrangThaiTiepNhan","in",CHO).get();
      assert.equal(waiting.docs.some(d=>d.ref.path===invite.path),false);
      const next=db.doc(`ChiTietPhanCongCuuHo/helper/DanhSachNgay/2026-11-03/DanhSachPhanCong/other-${suffix}`);
      await next.set({maPhanCong:"new-attempt",maYeuCau:next.id,maNguoiCuuHo:"helper",
        maTrangThaiTiepNhan:CHO[2],thoiGianGui:Timestamp.now()});
      assert.equal(await expireInvitation(db,next,"new-attempt"),false);
      assert.equal(await expireInvitation(db,invite,attempt),false);
      assert.equal((await next.get()).data().maTrangThaiTiepNhan,CHO[2]);
    });
    const active = db.collection("Admin").doc(`a${suffix}`);
    const disabled = db.collection("Admin").doc(`b${suffix}`);
    await active.set({ trangThai: "hoat_dong" });
    await disabled.set({ trangThai: "khoa" });
    await t.test(
      "Sự kiện lặp chỉ tạo một thông báo cho admin hoạt động",
      async () => {
        for (let i = 0; i < 2; i++)
          await notifyAdmins(
            db,
            suffix,
            request.id,
            "Ca mới",
            "Nội dung",
            "ca_moi",
          );
        const notices = await db
          .collection("ThongBao")
          .where("maYeuCau", "==", request.id)
          .get();
        assert.equal(notices.size, 1);
        const notice = notices.docs[0];
        assert.equal(notice.data().maNguoiDung, active.id);
        await active.collection("ThietBi").doc("good").set({ token: "valid" });
        await active.collection("ThietBi").doc("bad").set({ token: "invalid" });
        const sent = [];
        const messaging = {
          send: async (message) => {
            if (message.token === "invalid")
              throw { code: "messaging/registration-token-not-registered" };
            sent.push(message);
          },
        };
        await sendNotice(db, notice.ref, messaging);
        await sendNotice(db, notice.ref, messaging);
        assert.equal(sent.length, 1);
        assert.equal(sent[0].data.maYeuCau, request.id);
        assert.equal(
          (await active.collection("ThietBi").doc("bad").get()).exists,
          false,
        );
      },
    );
    await t.test(
      "Admin phụ trách không có thiết bị thì chuyển Push đến Admin hoạt động khác",
      async () => {
        const ownerNoDevice = db.collection("Admin").doc(`owner-no-device-${suffix}`);
        const backup = db.collection("Admin").doc(`backup-${suffix}`);
        await ownerNoDevice.set({ trangThai: "hoat_dong" });
        await backup.set({ trangThai: "hoat_dong" });
        await backup.collection("ThietBi").doc("good").set({ token: "backup-token" });

        const eventId = `${suffix}-owner-fallback`;
        await notifyAdmins(
          db,
          eventId,
          request.id,
          "Cứu hộ viên từ chối lời mời",
          "Admin cần xem xét mời người khác.",
          "phan_hoi_dieu_phoi",
          ownerNoDevice.id,
          { maSuKien: "loi_moi_tu_choi", mucDoUuTien: "quan_trong" },
        );

        const notices = await db.collection("ThongBao")
          .where("maSuKienNguon", "==", eventId).get();
        const ownerNotice = notices.docs.find(
          (row) => row.data().maNguoiDung === ownerNoDevice.id,
        );
        assert.ok(ownerNotice);

        await sendNotice(db, ownerNotice.ref, {
          send: async () => "unused",
        });
        assert.equal(
          (await ownerNotice.ref.get()).data().trangThaiDay,
          "khong_co_thiet_bi",
        );

        const fallbackRows = await db.collection("ThongBao")
          .where("maSuKienNguon", "==", eventId).get();
        const backupNotice = fallbackRows.docs.find(
          (row) => row.data().maNguoiDung === backup.id,
        );
        assert.ok(backupNotice, "Phải tạo thông báo cho Admin dự phòng.");

        const sent = [];
        for (const fallbackNotice of fallbackRows.docs) {
          if (fallbackNotice.data().maNguoiDung === ownerNoDevice.id) continue;
          await sendNotice(db, fallbackNotice.ref, {
            send: async (message) => {
              sent.push(message);
              return "mock-message-id";
            },
          });
        }
        assert.ok(sent.some((message) => message.data.maAdmin === backup.id));
        assert.equal(
          (await backupNotice.ref.get()).data().trangThaiDay,
          "da_gui",
        );
      },
    );

    await t.test(
      "Không gửi nếu admin bị khóa sau khi tạo thông báo",
      async () => {
        await notifyAdmins(
          db,
          `${suffix}-2`,
          request.id,
          "Ca mới",
          "Nội dung",
          "ca_moi",
          active.id,
        );
        const pending = await db
          .collection("ThongBao")
          .where("trangThaiDay", "==", "cho_gui")
          .get();
        await active.update({ trangThai: "khoa" });
        let sent = 0;
        for (const row of pending.docs)
          await sendNotice(db, row.ref, {
            send: async () => {
              sent++;
            },
          });
        assert.equal(sent, 0);
      },
    );
    const now = Date.now();
    let sequence = 0;
    async function fixture(extra = {}) {
      const ref = db
        .collection("YeuCauCuuHo")
        .doc(`auto-${suffix}-${sequence++}`);
      await ref.set({
        maTinhTrangYeuCau: "user_tinhtrang_chotiepnhan",
        thoiGianTao: Timestamp.fromMillis(now - 180000),
        ...extra,
      });
      return ref;
    }
    await t.test(
      "Quá hạn đúng mốc và không ghi lại khi tác vụ lặp",
      async () => {
        const ref = await fixture();
        assert.equal(await reconcileRequest(db, ref, 180, now - 1), "waiting");
        assert.equal(await reconcileRequest(db, ref, 180, now), "overdue");
        const first = await ref.get();
        assert.equal(
          first.data().maTinhTrangYeuCau,
          "user_tinhtrang_quahandieuphoi",
        );
        assert.equal(
          await reconcileRequest(db, ref, 180, now + 60000),
          "ignored",
        );
        assert.ok(first.updateTime.isEqual((await ref.get()).updateTime));
      },
    );
    await t.test(
      "Không đổi ca đã đóng, đã phân công hoặc chưa rõ trạng thái",
      async () => {
        for (const state of [
          "user_tinhtrang_hoanthanh",
          "user_tinhtrang_dahuy",
          "cho_dong",
          "user_tinhtrang_daphancong",
          "cuuho_trangthai_chophanhoi",
        ]) {
          const ref = await fixture({ maTinhTrangYeuCau: state });
          assert.equal(await reconcileRequest(db, ref, 180, now), "ignored");
          assert.equal((await ref.get()).data().maTinhTrangYeuCau, state);
        }
      },
    );
    await t.test(
      "Tiếp nhận chính thức: cập nhật ca, bỏ lời mời, không xóa nhu cầu bổ sung",
      async () => {
        const ref = await fixture({
          maLoiMoiDieuPhoi: "accepted-auto",
          canBoSungNhanLuc: true,
        });
        await db
          .collection("ChiTietPhanCongCuuHo")
          .doc("helper").collection("DanhSachNgay").doc("2026-11-02").collection("DanhSachPhanCong").doc(ref.id)
          .set({
            maPhanCong: "accepted-auto",
            maYeuCau: ref.id,
            maNguoiCuuHo: "helper",
            maTrangThaiTiepNhan: DONG_Y[1],
          });
        assert.equal(await reconcileRequest(db, ref, 180, now), "accepted");
        const data = (await ref.get()).data();
        assert.equal(data.maTinhTrangYeuCau, "user_tinhtrang_daphancong");
        assert.equal(data.maLoiMoiDieuPhoi, null);
        assert.equal(data.canBoSungNhanLuc, true);
        assert.equal(await reconcileRequest(db, ref, 180, now), "unchanged");
      },
    );
    await t.test(
      "Từ chối lời mời không đặt lại hạn tìm người của cả ca",
      async () => {
        const ref = await fixture();
        await db
          .collection("ChiTietPhanCongCuuHo")
          .doc("helper").collection("DanhSachNgay").doc("2026-11-02").collection("DanhSachPhanCong").doc(ref.id)
          .set({
            maYeuCau: ref.id,
            maNguoiCuuHo: "helper",
            maTrangThaiTiepNhan: "cuuho_trangthai_phancong_tuchoi",
          });
        assert.equal(await reconcileRequest(db, ref, 180, now), "overdue");
      },
    );
    await t.test(
      "Tôn trọng hạn riêng, giữ nguyên khi trigger tạo ca chạy lại",
      async () => {
        const ref = await fixture();
        await initializeDeadline(db, ref, 180);
        await initializeDeadline(db, ref, 600);
        assert.equal((await ref.get()).data().hanTimNguoi.toMillis(), now);
        await ref.update({ hanTimNguoi: Timestamp.fromMillis(now + 60000) });
        assert.equal(await reconcileRequest(db, ref, 180, now), "waiting");
      },
    );
    await t.test("Không đoán schema phân công tổng hợp của team", async () => {
      for (const aggregate of [
        { soNguoiCuuHo: 1 },
        { danhSachPhanCongVien: { helper: DONG_Y[1] } },
      ]) {
        const ref = await fixture(aggregate);
        assert.equal(await reconcileRequest(db, ref, 180, now), "conflict");
      }
    });
    await t.test(
      "Map chỉ chứa lời mời đã hủy/đã chọn không ngăn ca quá hạn",
      async () => {
        for (const state of [
          "cuuho_trangthai_phancong_dahuy",
          "cuuho_trangthai_phancong_chotiepnhan",
          "cuuho_trangthai_phancong_daphancong",
        ]) {
          const ref = await fixture({danhSachPhanCongVien: {helper: state}});
          assert.equal(await reconcileRequest(db, ref, 180, now), "overdue");
        }
      },
    );
    await t.test(
      "Được chọn nhưng chưa xác nhận không được tính là đã nhận",
      async () => {
        const ref = await fixture();
        await db.doc(`ChiTietPhanCongCuuHo/helper/DanhSachNgay/2026-11-02/DanhSachPhanCong/${ref.id}`)
          .set({maPhanCong: `selected-${ref.id}`, maYeuCau: ref.id,
            maNguoiCuuHo: "helper",
            maTrangThaiTiepNhan: "cuuho_trangthai_phancong_daphancong"});
        assert.equal(await reconcileRequest(db, ref, 180, now), "overdue");
      },
    );
    await t.test(
      "Scheduler tìm ca Timestamp, ISO và ca chỉ có hạn server",
      async () => {
        const timestamp = await fixture();
        const iso = await fixture({
          thoiGianTao: new Date(now - 180000).toISOString(),
        });
        const missingTime = await fixture({
          thoiGianTao: null,
          hanTimNguoi: Timestamp.fromMillis(now),
        });
        await scanWaitingRequests(db, 180, now);
        for (const ref of [timestamp, iso, missingTime])
          assert.equal(
            (await ref.get()).data().maTinhTrangYeuCau,
            "user_tinhtrang_quahandieuphoi",
          );
      },
    );
    await t.test(
      "Tiếp nhận đồng thời tác vụ quá hạn cuối cùng phải về đã phân công",
      async () => {
        const ref = await fixture();
        const assignment = db
          .collection("ChiTietPhanCongCuuHo")
          .doc("helper").collection("DanhSachNgay").doc("2026-11-02").collection("DanhSachPhanCong").doc(ref.id);
        await assignment.set({
          maYeuCau: ref.id,
          maNguoiCuuHo: "helper",
          maTrangThaiTiepNhan: CHO[2],
        });
        await Promise.all([
          reconcileRequest(db, ref, 180, now),
          assignment
            .update({ maTrangThaiTiepNhan: DONG_Y[1] })
            .then(() => reconcileRequest(db, ref, 180, now)),
        ]);
        assert.equal(
          (await ref.get()).data().maTinhTrangYeuCau,
          "user_tinhtrang_daphancong",
        );
      },
    );
    await db.terminate();
    await deleteApp(app);
  },
);

test("Tác vụ hết hạn chỉ tác động đúng lần mời trong bản theo ngày", async () => {
  const daily = {id:"ca", path:"ChiTietPhanCongCuuHo/u/DanhSachNgay/2026-11-02/DanhSachPhanCong/ca"};
  const request = {path:"YeuCauCuuHo/ca"};
  const rows = new Map([[daily.path,{maYeuCau:"ca", maPhanCong:"second", maAdmin:"a",
    hanPhanHoi:Timestamp.fromMillis(0), maTrangThaiTiepNhan:CHO[2]}],
    [request.path,{maLoiMoiDieuPhoi:"second"}]]);
  const db = {collection:n=>({doc:()=>{assert.equal(n,"YeuCauCuuHo"); return request;}}),
    runTransaction:fn=>fn({get:async r=>({data:()=>rows.get(r.path), createTime:Timestamp.fromMillis(0)}),
      update:(r,p)=>rows.set(r.path,{...rows.get(r.path),...p})})};
  assert.equal(await expireInvitation(db,daily,"first"),false);
  assert.equal(rows.get(daily.path).maTrangThaiTiepNhan,CHO[2]);
  assert.equal(await expireInvitation(db,daily,"second"),true);
  assert.equal(rows.get(request.path).maLoiMoiDieuPhoi,null);
  assert.equal(await expireInvitation(db,daily,"second"),false);
});
