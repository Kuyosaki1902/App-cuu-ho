const { test } = require("node:test");
const fs = require("node:fs");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  Timestamp,
} = require("firebase/firestore");

test(
  "Rules: quyền token, thông báo và phản hồi lời mời",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST },
  async (t) => {
    const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(":");
    const env = await initializeTestEnvironment({
      projectId: "demo-cuu-ho-rules",
      firestore: {
        host,
        port: Number(port),
        rules: fs.readFileSync(
          require("node:path").join(__dirname, "../firestore.admin.rules"),
          "utf8",
        ),
      },
    });
    try {
      await env.clearFirestore();
      await env.withSecurityRulesDisabled(async (ctx) => {
        const db = ctx.firestore();
        await setDoc(doc(db, "Admin/a"), { trangThai: "hoat_dong" });
        await setDoc(doc(db, "Admin/b"), { trangThai: "khoa" });
        await setDoc(doc(db, "YeuCauCuuHo/r"), {
          maTinhTrangYeuCau: "user_tinhtrang_chotiepnhan",
          maLoiMoiDieuPhoi: "i",
        });
        await setDoc(doc(db, "ChiTietPhanCongCuuHo/u/DanhSachNgay/2026-11-02/DanhSachPhanCong/r"), {
          maPhanCong: "i",
          maYeuCau: "r",
          maNguoiCuuHo: "u",
          maTrangThaiTiepNhan: "cuuho_trangthai_phancong_chotiepnhan",
          hanPhanHoi: Timestamp.fromMillis(Date.now() + 120000),
        });
        await setDoc(doc(db, "ThongBao/n"), { maNguoiDung: "a", daDoc: false });
      });
      const admin = env.authenticatedContext("a").firestore();
      const other = env.authenticatedContext("x").firestore();
      const user = env.authenticatedContext("u").firestore();
      const disabled = env.authenticatedContext("b").firestore();
      await t.test("Đánh giá: lọc 1 sao toàn bộ dữ liệu và phân trang", async () => {
        const { collection, query, where, orderBy, documentId, limit, startAfter, getDocs } = require("firebase/firestore");
        const assert = require("node:assert/strict");
        await env.withSecurityRulesDisabled(async ctx => {
          const store = ctx.firestore();
          await setDoc(doc(store, "Admin/c"), {trangThai: "hoat_dong"});
          for(let i=0;i<24;i++) await setDoc(doc(store, "DanhGia/r"+String(i).padStart(2,"0")), {
            diemDanhGia: i<2 ? 5 : i===23 ? "1" : 1, nhanXet:"Nhận xét ban đầu"
          });
        });
        const base = query(collection(admin,"DanhGia"),where("diemDanhGia","in",[1,"1"]),orderBy(documentId()));
        const first = await getDocs(query(base,limit(20)));
        const next = await getDocs(query(base,startAfter(first.docs.at(-1)),limit(20)));
        assert.equal(first.size,20); assert.equal(next.size,2);
        assert.equal(new Set([...first.docs,...next.docs].map(d=>d.id)).size,22);
        assert.equal((await getDocs(collection(admin,"DanhGia"))).size,24);
      });
      await t.test("Xử lý 1 sao: đúng người phụ trách, giữ nguyên điểm và nhận xét", async () => {
        const c = env.authenticatedContext("c").firestore();
        const claim = {trangThaiXuLy:"dang_xu_ly",maAdminXuLy:"a",ngayCapNhatXuLy:serverTimestamp()};
        const finish = {trangThaiXuLy:"da_xu_ly",ketQuaXuLy:"Đã kiểm tra với khách.",ngayCapNhatXuLy:serverTimestamp()};
        const ref = doc(admin,"DanhGia/r02");
        await assertFails(updateDoc(doc(admin,"DanhGia/r00"),claim));
        await assertFails(updateDoc(doc(user,"DanhGia/r02"),claim));
        await assertFails(updateDoc(ref,{...claim,diemDanhGia:3}));
        await assertFails(updateDoc(ref,{...claim,nhanXet:"Đã sửa"}));
        await assertFails(updateDoc(ref,{...finish,maAdminXuLy:"a"}));
        await assertSucceeds(updateDoc(ref,claim));
        await assertFails(updateDoc(doc(c,"DanhGia/r02"),{...claim,maAdminXuLy:"c"}));
        await assertFails(updateDoc(doc(c,"DanhGia/r02"),finish));
        await assertFails(updateDoc(ref,{...finish,ketQuaXuLy:"     "}));
        await assertSucceeds(updateDoc(ref,finish));
        await assertFails(updateDoc(ref,claim));
      });
      const token = {
        token: "example-token",
        nenTang: "android",
        ngayCapNhat: serverTimestamp(),
      };
      await t.test(
        "Chỉ admin hoạt động đăng ký thiết bị chính mình",
        async () => {
          await assertSucceeds(setDoc(doc(admin, "Admin/a/ThietBi/t"), token));
          await assertFails(setDoc(doc(other, "Admin/a/ThietBi/t2"), token));
          await assertFails(setDoc(doc(disabled, "Admin/b/ThietBi/t"), token));
          await assertSucceeds(deleteDoc(doc(admin, "Admin/a/ThietBi/t")));
        },
      );
      await t.test(
        "Client không giả mạo thông báo, chỉ đánh dấu đọc của mình",
        async () => {
          await assertFails(
            setDoc(doc(admin, "ThongBao/forged"), { nguon: "cloud_function" }),
          );
          await assertSucceeds(
            updateDoc(doc(admin, "ThongBao/n"), { daDoc: true }),
          );
          await assertFails(
            updateDoc(doc(other, "ThongBao/n"), { daDoc: true }),
          );
          await assertFails(
            updateDoc(doc(admin, "ThongBao/n"), { noiDung: "changed" }),
          );
        },
      );
      await t.test(
        "Chỉ người được mời phản hồi, không tự phân công",
        async () => {
          const reply = {
            maTrangThaiTiepNhan: "cuuho_trangthai_phancong_tiepnhan",
            thoiGianPhanHoi: serverTimestamp(),
          };
          await assertFails(
            updateDoc(doc(other, "ChiTietPhanCongCuuHo/u/DanhSachNgay/2026-11-02/DanhSachPhanCong/r"), reply),
          );
          await assertFails(
            updateDoc(doc(user, "ChiTietPhanCongCuuHo/u/DanhSachNgay/2026-11-02/DanhSachPhanCong/r"), {
              ...reply,
              maTrangThaiTiepNhan: "cuuho_trangthai_phancong_daphancong",
            }),
          );
          await assertSucceeds(
            updateDoc(doc(user, "ChiTietPhanCongCuuHo/u/DanhSachNgay/2026-11-02/DanhSachPhanCong/r"), reply),
          );
        },
      );
      await t.test(
        "Đã hết hạn thì không thể đồng ý dù scheduler chưa chạy",
        async () => {
          await env.withSecurityRulesDisabled(async (ctx) => {
            await updateDoc(doc(ctx.firestore(), "ChiTietPhanCongCuuHo/u/DanhSachNgay/2026-11-02/DanhSachPhanCong/r"), {
              maTrangThaiTiepNhan: "cuuho_trangthai_phancong_chotiepnhan",
              hanPhanHoi: Timestamp.fromMillis(0),
            });
          });
          await assertFails(
            updateDoc(doc(user, "ChiTietPhanCongCuuHo/u/DanhSachNgay/2026-11-02/DanhSachPhanCong/r"), {
              maTrangThaiTiepNhan: "cuuho_trangthai_phancong_tiepnhan",
              thoiGianPhanHoi: serverTimestamp(),
            }),
          );
        },
      );
    } finally {
      await env.cleanup();
    }
  },
);
