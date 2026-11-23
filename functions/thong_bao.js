const { createHash, randomUUID } = require("node:crypto");
const {
  FieldValue,
  Timestamp,
  FieldPath,
} = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { MO, CHO, DONG_Y, QUA_HAN } = require("./dieu_phoi");

const NEW_REQUEST_NOTICE = Object.freeze({
  title: "Yêu cầu cứu hộ mới",
  body: "Có yêu cầu cứu hộ mới đang chờ Admin tiếp nhận và quyết định phương án hỗ trợ.",
  kind: "ca_moi",
  eventCode: "yeu_cau_moi",
  priority: "khan_cap",
});

const PRIORITY = Object.freeze({
  KHAN_CAP: "khan_cap",
  QUAN_TRONG: "quan_trong",
});

const MAX_SEND_ATTEMPTS = 5;
const hash = (value) => createHash("sha256").update(value).digest("hex");

async function createNotice(
  db,
  uid,
  eventId,
  requestId,
  title,
  body,
  kind,
  options = {},
) {
  const ref = db.collection("ThongBao").doc(
    hash(`${eventId}:${kind}:${requestId}:${uid}`),
  );
  try {
    await ref.create({
      maNguoiDung: uid,
      maYeuCau: requestId,
      tieuDe: title,
      noiDung: body,
      loai: kind,
      maSuKien: options.maSuKien || kind,
      maSuKienNguon: eventId,
      mucDoUuTien: options.mucDoUuTien || PRIORITY.QUAN_TRONG,
      cheDoNhan: options.cheDoNhan || "all_active",
      maAdminPhuTrach: options.maAdminPhuTrach || null,
      phienBanDuLieu: 1,
      daDoc: false,
      ngayTao: FieldValue.serverTimestamp(),
      nguon: "cloud_function",
      trangThaiDay: "cho_gui",
      soLanThu: 0,
    });
  } catch (error) {
    if (error.code !== 6 && error.code !== "already-exists") throw error;
  }
  return ref;
}

async function forEachActiveAdmin(db, callback, excludedUid = null) {
  let cursor;
  let count = 0;
  while (true) {
    let query = db
      .collection("Admin")
      .where("trangThai", "==", "hoat_dong")
      .orderBy(FieldPath.documentId())
      .limit(100);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    for (let index = 0; index < page.docs.length; index += 10) {
      const group = page.docs.slice(index, index + 10);
      await Promise.all(group.map(async (admin) => {
        if (admin.id === excludedUid) return;
        await callback(admin);
        count++;
      }));
    }
    if (page.size < 100) break;
    cursor = page.docs.at(-1);
  }
  return count;
}

async function fanoutToOtherActiveAdmins(db, notice, excludedUid) {
  const eventId = notice.maSuKienNguon || notice.id;
  if (!eventId) throw new Error("Thiếu mã sự kiện để chuyển tiếp thông báo.");
  return forEachActiveAdmin(db, (admin) => createNotice(
    db,
    admin.id,
    eventId,
    notice.maYeuCau || "",
    notice.tieuDe || "Thông báo cứu hộ",
    notice.noiDung || "",
    notice.loai || "can_can_thiep",
    {
      maSuKien: notice.maSuKien || notice.loai,
      mucDoUuTien: notice.mucDoUuTien || PRIORITY.QUAN_TRONG,
      maAdminPhuTrach: notice.maAdminPhuTrach || excludedUid || null,
      cheDoNhan: "all_active",
    },
  ), excludedUid);
}

// Có Admin phụ trách thì gửi riêng cho người đó trước.
// Nếu Admin không hoạt động/không có thiết bị hợp lệ, sendNotice sẽ chuyển tiếp
// đến các Admin đang hoạt động khác. Sự kiện không có người phụ trách gửi all-active.
async function notifyAdmins(
  db,
  eventId,
  requestId,
  title,
  body,
  kind,
  owner,
  options = {},
) {
  const metadata = {
    maSuKien: options.maSuKien || kind,
    mucDoUuTien: options.mucDoUuTien || PRIORITY.QUAN_TRONG,
    maAdminPhuTrach: owner || null,
  };

  if (owner) {
    const admin = await db.collection("Admin").doc(owner).get();
    if (admin.data()?.trangThai === "hoat_dong") {
      await createNotice(db, owner, eventId, requestId, title, body, kind, {
        ...metadata,
        cheDoNhan: "admin_phu_trach",
      });
      return;
    }
  }

  await forEachActiveAdmin(db, (admin) => createNotice(
    db,
    admin.id,
    eventId,
    requestId,
    title,
    body,
    kind,
    { ...metadata, cheDoNhan: "all_active" },
  ));
}

function interventionEvent(before, after) {
  if (!MO.includes(after.maTinhTrangYeuCau)) return null;

  if (
    after.trangThaiXacNhanHoanThanh === "qua_han_cho_admin" &&
    before.trangThaiXacNhanHoanThanh !== "qua_han_cho_admin"
  ) {
    return {
      title: "Quá hạn xác nhận hoàn thành",
      body: "Cứu hộ viên đã báo hoàn thành nhưng nạn nhân chưa xác nhận. Admin cần liên hệ và xác minh trước khi đóng ca.",
      kind: "qua_han_xac_nhan",
      eventCode: "xac_nhan_qua_han",
      priority: PRIORITY.KHAN_CAP,
    };
  }

  if (
    after.trangThaiXacNhanHoanThanh === "can_can_thiep" &&
    before.trangThaiXacNhanHoanThanh !== "can_can_thiep"
  ) {
    return {
      title: "Ca cứu hộ cần Admin xác minh",
      body: "Ca cứu hộ đã phát sinh tình huống cần Admin kiểm tra trước khi xác nhận hoàn thành.",
      kind: "can_can_thiep",
      eventCode: "can_xac_minh_hoan_thanh",
      priority: PRIORITY.KHAN_CAP,
    };
  }

  if (
    QUA_HAN.includes(after.maTinhTrangYeuCau) &&
    !QUA_HAN.includes(before.maTinhTrangYeuCau)
  ) {
    return {
      title: "Ca cứu hộ chưa có người tiếp nhận",
      body: "Ca đã quá thời gian tìm người cứu hộ nhưng chưa có người nhận. Admin cần xem xét phương án điều phối.",
      kind: "can_can_thiep",
      eventCode: "qua_han_dieu_phoi",
      priority: PRIORITY.KHAN_CAP,
    };
  }



  if (after.canKiemTra === true && before.canKiemTra !== true) {
    return {
      title: "Ca cứu hộ cần kiểm tra",
      body: "Ca cứu hộ phát sinh trạng thái cần Admin kiểm tra và xử lý.",
      kind: "can_can_thiep",
      eventCode: "can_kiem_tra",
      priority: PRIORITY.KHAN_CAP,
    };
  }

  if (after.canBoSungNhanLuc === true && before.canBoSungNhanLuc !== true) {
    return {
      title: "Ca cứu hộ cần bổ sung nhân lực",
      body: "Ca cứu hộ đang thiếu người hỗ trợ. Admin cần kiểm tra và điều phối bổ sung nếu cần.",
      kind: "can_can_thiep",
      eventCode: "can_bo_sung_nhan_luc",
      priority: PRIORITY.KHAN_CAP,
    };
  }

  return null;
}

function intervention(before, after) {
  return interventionEvent(before, after) !== null;
}

function replyEvent(before, after) {
  if (before.maTrangThaiTiepNhan === after.maTrangThaiTiepNhan) return null;
  if (![...CHO, ...DONG_Y].includes(before.maTrangThaiTiepNhan)) return null;

  if (DONG_Y.includes(after.maTrangThaiTiepNhan)) {
    return {
      title: "Cứu hộ viên đã nhận ca",
      body: "Cứu hộ viên đã chấp nhận lời mời điều phối và xác nhận tham gia ca cứu hộ.",
      eventCode: "loi_moi_da_nhan",
      priority: PRIORITY.QUAN_TRONG,
    };
  }

  if ([
    "tu_choi",
    "cuuho_trangthai_phancong_tuchoi",
  ].includes(after.maTrangThaiTiepNhan)) {
    return {
      title: "Cứu hộ viên từ chối lời mời",
      body: "Cứu hộ viên đã từ chối lời mời. Admin có thể xem xét mời người khác nếu ca vẫn cần hỗ trợ.",
      eventCode: "loi_moi_tu_choi",
      priority: PRIORITY.QUAN_TRONG,
    };
  }

  if (after.lyDoKetThuc === "het_han") {
    return {
      title: "Lời mời cứu hộ đã hết hạn",
      body: "Cứu hộ viên chưa phản hồi trong thời hạn quy định. Admin có thể xem xét mời người khác.",
      eventCode: "loi_moi_het_han",
      priority: PRIORITY.QUAN_TRONG,
    };
  }

  return null;
}

// Giữ hàm cũ để các kiểm thử/module hiện tại không bị gãy tương thích.
function replyNotice(before, after) {
  return replyEvent(before, after)?.body || null;
}

async function removeStaleDevice(db, deviceRef, token) {
  await db.runTransaction(async (tx) => {
    const current = await tx.get(deviceRef);
    if (current.data()?.token === token) tx.delete(deviceRef);
  });
}

async function sendNotice(db, ref, messaging = getMessaging()) {
  const leaseId = randomUUID();
  const claim = await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const data = snapshot.data();
    if (
      !data ||
      data.nguon !== "cloud_function" ||
      [
        "da_gui",
        "khong_co_thiet_bi",
        "nguoi_nhan_khong_hoat_dong",
        "gui_loi",
      ].includes(data.trangThaiDay)
    ) {
      return null;
    }
    if (data.khoaGuiDen?.toMillis() > Date.now()) {
      throw new Error("Thông báo đang được gửi.");
    }
    const attempts = Number(data.soLanThu || 0) + 1;
    tx.update(ref, {
      khoaGui: leaseId,
      khoaGuiDen: Timestamp.fromMillis(Date.now() + 300000),
      soLanThu: attempts,
    });
    return { notice: data, attempts };
  });
  if (!claim) return null;

  const notice = claim.notice;
  let fallbackCount = 0;
  try {
    const adminSnapshot = await db.collection("Admin").doc(notice.maNguoiDung).get();
    const adminActive = adminSnapshot.data()?.trangThai === "hoat_dong";
    const sentSnapshot = await ref.collection("DaGui").get();
    const sentDeviceIds = new Set(sentSnapshot.docs.map((doc) => doc.id));
    let sentCount = sentDeviceIds.size;
    let invalidTokenCount = 0;

    if (adminActive) {

      let cursor;
      while (true) {
        let query = db
          .collection("Admin")
          .doc(notice.maNguoiDung)
          .collection("ThietBi")
          .orderBy(FieldPath.documentId())
          .limit(100);
        if (cursor) query = query.startAfter(cursor);
        const page = await query.get();

        for (const device of page.docs) {
          if (sentDeviceIds.has(device.id)) continue;
          const token = device.data().token;
          if (typeof token !== "string" || !token.trim()) continue;

          // Người dùng có thể đã đăng xuất hoặc token đã được thay trong lúc gửi.
          const current = await device.ref.get();
          if (current.data()?.token !== token) continue;

          const urgent = notice.mucDoUuTien === PRIORITY.KHAN_CAP;
          const channelId = urgent
            ? "admin_cuuho_khan_cap"
            : "admin_cuuho_dieu_phoi";

          try {
            const messageId = await messaging.send({
              token,
              notification: {
                title: notice.tieuDe || "Thông báo cứu hộ",
                body: notice.noiDung || "",
              },
              data: {
                schemaVersion: String(notice.phienBanDuLieu || 1),
                maThongBao: ref.id,
                maAdmin: notice.maNguoiDung || "",
                maYeuCau: notice.maYeuCau || "",
                loai: notice.loai || "",
                maSuKien: notice.maSuKien || notice.loai || "",
                mucDoUuTien: notice.mucDoUuTien || PRIORITY.QUAN_TRONG,
                dichDen: "chi_tiet_yeu_cau",
              },
              android: {
                priority: urgent ? "high" : "normal",
                ttl: 3600000,
                notification: {
                  channelId,
                  tag: ref.id,
                  sound: "default",
                },
              },
              apns: {
                headers: { "apns-collapse-id": ref.id },
                payload: { aps: { sound: "default" } },
              },
            });

            await ref.collection("DaGui").doc(device.id).set({
              ngayGui: FieldValue.serverTimestamp(),
              messageId: messageId || null,
            });
            sentDeviceIds.add(device.id);
            sentCount++;
          } catch (error) {
            if ([
              "messaging/registration-token-not-registered",
              "messaging/invalid-registration-token",
            ].includes(error.code)) {
              await removeStaleDevice(db, device.ref, token);
              invalidTokenCount++;
              continue;
            }
            throw error;
          }
        }

        if (page.size < 100) break;
        cursor = page.docs.at(-1);
      }
    }

    // Nếu Admin phụ trách không còn thiết bị gửi được, chuyển sang các Admin khác.
    // Fan-out phải hoàn tất trước khi đóng trạng thái notice để trigger có thể retry.
    if (sentCount === 0 && notice.cheDoNhan === "admin_phu_trach") {
      fallbackCount = await fanoutToOtherActiveAdmins(
        db,
        notice,
        notice.maNguoiDung,
      );
    }

    const deliveryStatus = sentCount > 0
      ? "da_gui"
      : adminActive
        ? "khong_co_thiet_bi"
        : "nguoi_nhan_khong_hoat_dong";

    await ref.update({
      trangThaiDay: deliveryStatus,
      ngayXuLyDay: FieldValue.serverTimestamp(),
      ...(sentCount > 0
        ? { ngayGui: FieldValue.serverTimestamp() }
        : {}),
      soThietBiGuiThanhCong: sentCount,
      soTokenKhongHopLe: invalidTokenCount,
      soAdminChuyenTiep: fallbackCount,
      khoaGuiDen: FieldValue.delete(),
      khoaGui: FieldValue.delete(),
    });

    return { trangThaiDay: deliveryStatus, sentCount, invalidTokenCount };
  } catch (error) {
    const sentSnapshot = await ref.collection("DaGui").get();
    const sentCount = sentSnapshot.size;
    const exhausted = claim.attempts >= MAX_SEND_ATTEMPTS;

    await db.runTransaction(async (tx) => {
      const current = await tx.get(ref);
      if (current.data()?.khoaGui !== leaseId) return;

      const patch = {
        loiGuiGanNhat: String(error.code || error.message || "unknown").slice(0, 160),
        ngayLoiGui: FieldValue.serverTimestamp(),
        khoaGuiDen: FieldValue.delete(),
        khoaGui: FieldValue.delete(),
      };

      if (exhausted) {
        patch.trangThaiDay = sentCount > 0 ? "da_gui" : "gui_loi";
        patch.soThietBiGuiThanhCong = sentCount;
        if (sentCount > 0) patch.ngayGui = FieldValue.serverTimestamp();
      }

      tx.update(ref, patch);
    });

    if (!exhausted) throw error;
    return {
      trangThaiDay: sentCount > 0 ? "da_gui" : "gui_loi",
      sentCount,
      soLanThu: claim.attempts,
    };
  }
}

module.exports = {
  NEW_REQUEST_NOTICE,
  MAX_SEND_ATTEMPTS,
  PRIORITY,
  notifyAdmins,
  intervention,
  interventionEvent,
  replyNotice,
  replyEvent,
  sendNotice,
};
