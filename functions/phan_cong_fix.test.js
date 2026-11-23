"use strict";
const {test} = require("node:test");
const assert = require("node:assert/strict");
const {Timestamp} = require("firebase-admin/firestore");
const {CHO, DONG_Y, DA_THAM_GIA, expireInvitation, reconcileRequest} = require("./dieu_phoi");
const {doiChieuCaSauPhanCong} = require("./xac_nhan_ca");

// Dùng dữ liệu trong bộ nhớ để kiểm tra các thay đổi của từng ca.
function fakeFirestore(seed, allowCleanup = false) {
  const docs = new Map(Object.entries(seed));
  const ref = (path) => ({path, id: path.split("/").at(-1)});
  class Query {
    constructor(filters=[], limitVal=10000) {this.filters=filters; this.limitVal=limitVal;}
    where(k, op, value) {return new Query([...this.filters,[k,op,value]],this.limitVal);}
    limit(n) {return new Query(this.filters,n);}
    matches(item) {return this.filters.every(([k,op,val]) =>
      op==="==" ? item[k]===val : op==="in" ? val.includes(item[k]) : false);}
  }
  const db = {
    collection: name => ({doc: id => ref(`${name}/${id}`)}),
    collectionGroup: name => {
      assert.equal(name, "DanhSachPhanCong");
      return new Query();
    },
    runTransaction: fn => fn({
      get: async target => {
        if (target instanceof Query) {
          const matches = [...docs].filter(([path,data]) =>
            path.includes("/DanhSachPhanCong/") && target.matches(data))
            .slice(0,target.limitVal).map(([path,data]) => ({
              ref:ref(path), data:()=>({...data}),
            }));
          return {docs:matches, empty:matches.length===0, size:matches.length};
        }
        const data = docs.get(target.path);
        return {id:target.id, ref:target, data:()=>data ? {...data}:undefined,
          createTime:Timestamp.fromMillis(Date.now()-240000)};
      },
      update:(r,patch)=>{
        assert.ok(allowCleanup || !Object.keys(patch).some(k =>
          k === "danhSachPhanCongVien" || k.startsWith("danhSachPhanCongVien.")));
        docs.set(r.path,{...(docs.get(r.path)||{}), ...patch});
      },
    }),
  };
  return {db, docs, ref};
}

const requestPath = "YeuCauCuuHo/yeucau4";
const onePath = "ChiTietPhanCongCuuHo/nguoidung3/DanhSachNgay/2026-11-18/DanhSachPhanCong/yeucau4";
const twoPath = "ChiTietPhanCongCuuHo/nguoidung7/DanhSachNgay/2026-11-18/DanhSachPhanCong/yeucau4";
function assignment(uid, status, maPhanCong) {
  return {maYeuCau:"yeucau4", maNguoiCuuHo:uid,
    maPhanCong, maTrangThaiTiepNhan: status,
    thoiGianGui: Timestamp.fromMillis(Date.now()-200000)};
}

test("Tạo ca ảo, 2 lời mời tự hết hạn => không tự thêm 2 người",async () => {
  const {db,docs,ref}=fakeFirestore({
    [requestPath]: {maTinhTrangYeuCau:"user_tinhtrang_dahuy",maLoiMoiDieuPhoi:"loi1"},
    [onePath]:assignment("nguoidung3",CHO[2],"loi1"),
    [twoPath]:assignment("nguoidung7",CHO[2],"loi2"),
  });
  assert.equal(await expireInvitation(db,ref(onePath),"loi1"),true);
  assert.equal(await expireInvitation(db,ref(twoPath),"loi2"),true);
  assert.deepEqual(docs.get(requestPath).danhSachPhanCongVien,undefined);
  assert.equal(docs.get(onePath).lyDoKetThuc,"het_han");
  assert.equal(docs.get(twoPath).maTrangThaiTiepNhan,"cuuho_trangthai_phancong_dahuy");
});

test("Hết hạn giữ nguyên cả hai UID trong map",async()=>{
  const {db,docs,ref}=fakeFirestore({
    [requestPath]:{maTinhTrangYeuCau:"user_tinhtrang_chotiepnhan",
      danhSachPhanCongVien:{nguoidung3:CHO[2],nguoidung7:DONG_Y[1]}},
    [onePath]:assignment("nguoidung3",CHO[2],"old1"),
    [twoPath]:assignment("nguoidung7",DONG_Y[1],"old2"),
  });
  await expireInvitation(db,ref(onePath),"old1");
  assert.deepEqual(docs.get(requestPath).danhSachPhanCongVien,{nguoidung3:CHO[2],nguoidung7:DONG_Y[1]});
});

test("Hết hạn lượt mời cũ không xóa lượt đã đồng ý của cùng UID",async()=>{
  const newerPath="ChiTietPhanCongCuuHo/nguoidung3/DanhSachNgay/2026-11-19/DanhSachPhanCong/yeucau4";
  const {db,docs,ref}=fakeFirestore({
    [requestPath]:{maTinhTrangYeuCau:"user_tinhtrang_daphancong",
      danhSachPhanCongVien:{nguoidung3:CHO[2]}},
    [onePath]:assignment("nguoidung3",CHO[2],"old"),
    [newerPath]:assignment("nguoidung3",DONG_Y[1],"new"),
  });
  assert.equal(await expireInvitation(db,ref(onePath),"old"),true);
  assert.equal(docs.get(requestPath).danhSachPhanCongVien.nguoidung3,CHO[2]);
});

test("Trigger hủy giữ nguyên map và không báo thiếu người", async()=>{
  const {db,docs,ref}=fakeFirestore({
    [requestPath]:{maTinhTrangYeuCau:"user_tinhtrang_quahandieuphoi",
      danhSachPhanCongVien:{nguoidung3:"cuuho_trangthai_phancong_dahuy"}},
    [onePath]:assignment("nguoidung3","cuuho_trangthai_phancong_dahuy","cancel"),
  });
  assert.equal(await doiChieuCaSauPhanCong(db,"yeucau4","nguoidung3",ref(onePath),24),"khong_thay_doi");
  assert.deepEqual(docs.get(requestPath).danhSachPhanCongVien,{nguoidung3:"cuuho_trangthai_phancong_dahuy"});
  assert.equal(docs.get(requestPath).canBoSungNhanLuc,undefined);
});

test("Trigger hết hạn lời mời cũ không xóa lần tham gia mới của cùng UID",async()=>{
  const newerPath="ChiTietPhanCongCuuHo/nguoidung3/DanhSachNgay/2026-11-19/DanhSachPhanCong/yeucau4";
  const {db,docs,ref}=fakeFirestore({
    [requestPath]:{maTinhTrangYeuCau:"user_tinhtrang_daphancong",
      danhSachPhanCongVien:{nguoidung3:CHO[2]}},
    [onePath]:assignment("nguoidung3","cuuho_trangthai_phancong_dahuy","old"),
    [newerPath]:assignment("nguoidung3",DONG_Y[1],"new"),
  });
  await doiChieuCaSauPhanCong(db,"yeucau4","nguoidung3",ref(onePath),24);
  assert.equal(docs.get(requestPath).danhSachPhanCongVien.nguoidung3,CHO[2]);
});

test("Trigger tạo phân công ở trạng thái ĐƯỢC CHỌN không tự nhận ca",async()=>{
  const {db,docs,ref}=fakeFirestore({
    [requestPath]:{maTinhTrangYeuCau:"user_tinhtrang_chotiepnhan",
      maLoiMoiDieuPhoi:"selected-1"},
    [onePath]:assignment("nguoidung3","cuuho_trangthai_phancong_daphancong","selected-1"),
  });
  assert.equal(await doiChieuCaSauPhanCong(db,"yeucau4","nguoidung3",ref(onePath),24),
    "khong_thay_doi");
  assert.equal(docs.get(requestPath).maTinhTrangYeuCau,"user_tinhtrang_chotiepnhan");
  assert.equal(docs.get(requestPath).danhSachPhanCongVien,undefined);
  assert.equal(docs.get(requestPath).maLoiMoiDieuPhoi,"selected-1");
});

test("Chọn cứu hộ viên nhưng chưa nhận không làm ca chuyển sang đã phân công",async()=>{
  const now=Date.now();
  const {db,docs,ref}=fakeFirestore({
    [requestPath]:{maTinhTrangYeuCau:"user_tinhtrang_chotiepnhan",
      thoiGianTao:Timestamp.fromMillis(now-181000)},
    [onePath]:assignment("nguoidung3","cuuho_trangthai_phancong_daphancong","selected"),
  });
  assert.equal(await reconcileRequest(db,ref(requestPath),180,now),"overdue");
  assert.equal(docs.get(requestPath).maTinhTrangYeuCau,"user_tinhtrang_quahandieuphoi");
});

test("Mã ca tái sử dụng: lượt nhận và hoàn thành cũ không tác động ca mới", async () => {
  const old = assignment("nguoidung3", DONG_Y[1], "previous");
  old.thoiGianGui = Timestamp.fromMillis(Date.now() - 7 * 86400000);
  const finished = {...old, maNguoiCuuHo: "nguoidung7",
    maTrangThaiTiepNhan: "cuuho_trangthai_phancong_hoanthanh"};
  const {db, docs, ref} = fakeFirestore({
    [requestPath]: {maTinhTrangYeuCau: "user_tinhtrang_chotiepnhan",
      thoiGianTao: Timestamp.fromMillis(Date.now() - 240000)},
    [onePath]: old, [twoPath]: finished,
  });
  assert.equal(await doiChieuCaSauPhanCong(db, "yeucau4", "nguoidung3", ref(onePath), 24),
    "khac_lan_tao_ca");
  assert.equal(await reconcileRequest(db, ref(requestPath), 180), "overdue");
  const {kiemTraCaSauHetHanLoiMoi} = require("./xac_nhan_ca");
  docs.delete(onePath);
  assert.equal(await kiemTraCaSauHetHanLoiMoi(db, "yeucau4", 24), "chua_du_dieu_kien");
  assert.equal(docs.get(requestPath).danhSachPhanCongVien, undefined);
  docs.set(onePath, assignment("nguoidung3", DONG_Y[1], "current"));
  assert.equal(await reconcileRequest(db, ref(requestPath), 180), "accepted");
});

test("Hết hạn không khôi phục trạng thái nhận từ lần tạo ca trước của cùng UID", async () => {
  const previous = onePath.replace("11-18", "11-11");
  const old = assignment("nguoidung3", DONG_Y[1], "old");
  old.thoiGianGui = Timestamp.fromMillis(Date.now() - 7 * 86400000);
  const {db, docs, ref} = fakeFirestore({
    [requestPath]: {danhSachPhanCongVien: {nguoidung3: CHO[2]}},
    [onePath]: assignment("nguoidung3", CHO[2], "current"),
    [previous]: old,
  });
  assert.equal(await expireInvitation(db, ref(onePath), "current"), true);
  assert.deepEqual(docs.get(requestPath).danhSachPhanCongVien, {nguoidung3:CHO[2]});
});

test("Phản hồi, báo xong và sự kiện xóa chạy lại không tạo danh sách trên ca", async () => {
  for (const status of [DONG_Y[1], "cuuho_trangthai_phancong_hoanthanh"]) {
    const row = assignment("nguoidung3",status,"current");
    const {db,docs,ref} = fakeFirestore({
      [requestPath]: {maTinhTrangYeuCau:"user_tinhtrang_chotiepnhan"},
      [onePath]: row,
    });
    const event = {data:()=>row};
    await doiChieuCaSauPhanCong(db,"yeucau4","nguoidung3",ref(onePath),24,event);
    assert.ok(!Object.hasOwn(docs.get(requestPath),"danhSachPhanCongVien"));
    docs.delete(onePath);
    await doiChieuCaSauPhanCong(db,"yeucau4","nguoidung3",ref(onePath),24,event);
    assert.ok(!Object.hasOwn(docs.get(requestPath),"danhSachPhanCongVien"));
  }
});

test("Gỡ đúng UID cũ, giữ UID có lượt hiện tại và UID thiếu chứng cứ", async () => {
  const {removeHistoricalMembers} = require("./dieu_phoi");
  const done = "cuuho_trangthai_phancong_hoanthanh";
  const map = {nguoidung3:done, nguoidung7:done, unknown:done};
  const old = {...assignment("nguoidung3",done,"old"), thoiGianGui:Timestamp.fromMillis(1)};
  const {db,docs,ref} = fakeFirestore({
    [requestPath]: {danhSachPhanCongVien:map},
    [onePath]:old,
    [twoPath]:{...old,maNguoiCuuHo:"nguoidung7"},
    [twoPath.replace("11-18","11-19")]:assignment("nguoidung7",DONG_Y[1],"current"),
  },true);
  const changed = Object.entries(map);
  await removeHistoricalMembers(db,ref(requestPath),[["nguoidung3",DONG_Y[1]]]);
  assert.deepEqual(docs.get(requestPath).danhSachPhanCongVien,map);
  for (let retry = 0; retry < 2; retry++) {
    await removeHistoricalMembers(db,ref(requestPath),changed);
    assert.deepEqual(docs.get(requestPath).danhSachPhanCongVien,{nguoidung7:done,unknown:done});
  }
});
