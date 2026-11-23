"use strict";
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { setGlobalOptions } = require("firebase-functions/v2");
const {
  onDocumentCreated, onDocumentUpdated, onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineInt, defineSecret } = require("firebase-functions/params");
const { createHash, createHmac, timingSafeEqual } = require("node:crypto");
const logger = require("firebase-functions/logger");
// Giữ nguyên trigger v1 đang được hai ứng dụng sử dụng để đồng bộ
// Realtime Database NguoiDung/{uid}/isOnline sang Firestore NguoiDung/{uid}.
// Không thay đổi schema hay quy trình online/offline của hai ứng dụng.
const functionsV1 = require("firebase-functions/v1");

const {
  removeHistoricalMembers, belongsToRequest, expireInvitation, invitationDeadline, CHO_HOAC_QUA_HAN, CHO, DONG_Y, DANG_NHAN_THUC_TE, MO, initializeDeadline, timeMillis,
  scanWaitingRequests, reconcileRequest,
} = require("./dieu_phoi");
const {
  NEW_REQUEST_NOTICE, notifyAdmins, interventionEvent, replyEvent, sendNotice,
} = require("./thong_bao");
const {
  TRANG_THAI_CA_HOAN_THANH, XAC_NHAN, ketQuaDaDuDieuKien,
  taoBanGhiDongCa, docTongQuanPhanCong, doiChieuCaSauPhanCong,
  kiemTraCaSauHetHanLoiMoi,
} = require("./xac_nhan_ca");
const {
  CONTACT_RESULTS, validRadius, normalizeCandidateUids, profileApproved,
  rescueReady, distanceKm, validCoordinates, validContactResult, adminMirror,
} = require("./dieu_phoi_moi");

initializeApp();
const db = getFirestore();
const GOOGLE_PLACES_API_KEY = defineSecret("GOOGLE_PLACES_API_KEY");

// Compatibility trigger: intentionally identical to the existing app-side
// Functions source. Keep this export when deploying the combined Functions
// package so the online/offline mirror is not accidentally removed.
exports.syncOnlineStatus = functionsV1.database
  .ref("/NguoiDung/{userId}/isOnline")
  .onWrite(async (change, context) => {
    const isOnline = change.after.val();
    const userId = context.params.userId;
    const userDocRef = db.collection("NguoiDung").doc(userId);
    try {
      await userDocRef.set({ isOnline: isOnline === true }, { merge: true });
      logger.info(`Updated ${userId} online status`, { isOnline: isOnline === true });
    } catch (error) {
      logger.error("Error syncing RTDB online status to Firestore", { userId, error });
    }
  });
setGlobalOptions({
  region: "asia-southeast1", minInstances: 0, maxInstances: 2,
  memory: "256MiB", timeoutSeconds: 300,
});

const ASSIGNMENT_PATH =
  "ChiTietPhanCongCuuHo/{uid}/DanhSachNgay/{ngay}/DanhSachPhanCong/{ca}";
const HAN_TIM_NGUOI = defineInt("HAN_TIM_NGUOI_GIAY", {
  default: 60,
  description: "Thời gian tìm cứu hộ viên từ lúc tạo ca, tính theo giây.",
});
const HAN_XAC_NHAN = defineInt("HAN_XAC_NHAN_HOAN_THANH_GIO", {
  default: 24,
  description: "Thời gian chờ nạn nhân xác nhận trước khi chuyển Admin (giờ).",
});

function thoiGianTimNguoi() {
  const value = HAN_TIM_NGUOI.value();
  if (!Number.isInteger(value) || value < 30 || value > 86400) {
    throw new Error("HAN_TIM_NGUOI_GIAY phải từ 30 đến 86400.");
  }
  return value;
}
function thoiGianChoXacNhan() {
  const value = HAN_XAC_NHAN.value();
  if (!Number.isInteger(value) || value < 1 || value > 720) {
    throw new Error("HAN_XAC_NHAN_HOAN_THANH_GIO phải từ 1 đến 720.");
  }
  return value;
}
function maYeuCauHopLe(value) {
  if (typeof value !== "string" || !value.trim() || value.includes("/") || value.length > 200) {
    throw new HttpsError("invalid-argument", "Mã yêu cầu cứu hộ không hợp lệ.");
  }
  return value;
}
async function kiemTraAdmin(auth) {
  if (!auth?.uid) throw new HttpsError("unauthenticated", "Vui lòng đăng nhập.");
  const admin = await db.collection("Admin").doc(auth.uid).get();
  if (admin.data()?.trangThai !== "hoat_dong") {
    throw new HttpsError("permission-denied", "Không có quyền Admin.");
  }
  return auth.uid;
}

const INVITE_PENDING_STATES = new Set([
  "da_gui_thong_bao",
  "cuuho_trangthai_chophanhoi",
  "cuuho_trangthai_phancong_chotiepnhan",
]);
const INVITE_ACTIVE_STATES = new Set([
  "da_dong_y",
  "duoc_chon",
  "cuuho_trangthai_phancong_tiepnhan",
  "cuuho_trangthai_phancong_daphancong",
  "cuuho_trangthai_phancong_daden",
  "cuuho_trangthai_phancong_dangcuuho",
]);
const INVITE_OPEN_STATES = [
  ...INVITE_PENDING_STATES,
  ...INVITE_ACTIVE_STATES,
];

function ngayDieuPhoiVietNam(now = Date.now()) {
  return new Date(now + 7 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

function loiLoiMoiCu(data) {
  const keys = [
    "maPhanCong",
    "maTrangThaiTiepNhan",
    "thoiGianGui",
    "thoiGianPhanHoi",
  ];
  return Object.fromEntries(keys
    .filter((key) => data?.[key] !== undefined)
    .map((key) => [key, data[key]]));
}

// Gửi tối đa ba lời mời độc lập trong cùng một transaction.
// Chỉ dùng các đường dẫn và trường phân công đã có; không ghi danhSachPhanCongVien.
exports.adminMoiTop3CuuHo = onCall(async ({ auth, data }) => {
  const maAdmin = await kiemTraAdmin(auth);
  const maYeuCau = maYeuCauHopLe(data?.maYeuCau);
  let uids;
  try {
    uids = normalizeCandidateUids(data?.uids);
  } catch (error) {
    throw new HttpsError("invalid-argument", error.message);
  }
  const radius = Number(data?.radius);
  const additional = data?.additional === true;
  if (!validRadius(radius)) {
    throw new HttpsError("invalid-argument", "Bán kính phải là 1, 3 hoặc 5 km.");
  }

  const requestRef = db.collection("YeuCauCuuHo").doc(maYeuCau);
  const now = Date.now();
  const day = ngayDieuPhoiVietNam(now);
  const deadline = Timestamp.fromMillis(now + 3 * 60 * 1000);

  return db.runTransaction(async (tx) => {
    const [adminSnap, requestSnap] = await Promise.all([
      tx.get(db.collection("Admin").doc(maAdmin)),
      tx.get(requestRef),
    ]);
    const request = requestSnap.data();
    if (adminSnap.data()?.trangThai !== "hoat_dong" || !request) {
      throw new HttpsError("permission-denied", "Không thể điều phối yêu cầu này.");
    }
    if (!MO.includes(request.maTinhTrangYeuCau)) {
      throw new HttpsError("failed-precondition", "Ca không còn đủ điều kiện điều phối.");
    }
    const owner = request.maAdminDieuPhoi;
    if (owner !== maAdmin) {
      throw new HttpsError(
        "failed-precondition",
        owner ? "Ca đã có Admin khác phụ trách." : "Hãy nhận điều phối ca này trước.",
      );
    }

    if (!validCoordinates(request.viDo, request.kinhDo)) {
      throw new HttpsError("failed-precondition", "Yêu cầu chưa có tọa độ hợp lệ.");
    }

    const requestRows = await tx.get(
      db.collectionGroup("DanhSachPhanCong")
        .where("maYeuCau", "==", maYeuCau)
        .where("maTrangThaiTiepNhan", "in", INVITE_OPEN_STATES)
        .limit(100),
    );
    if (requestRows.size >= 100) {
      throw new HttpsError("resource-exhausted", "Ca có quá nhiều bản ghi phân công đang mở.");
    }
    const currentRows = requestRows.docs.filter((row) =>
      belongsToRequest(row, requestSnap),
    );
    if (currentRows.some((row) =>
      INVITE_PENDING_STATES.has(row.data().maTrangThaiTiepNhan),
    )) {
      throw new HttpsError(
        "failed-precondition",
        "Ca vẫn còn lời mời đang chờ. Hãy chờ phản hồi hoặc hết hạn trước khi gửi lượt mới.",
      );
    }
    const activeRows = currentRows.filter((row) =>
      INVITE_ACTIVE_STATES.has(row.data().maTrangThaiTiepNhan),
    );
    if (!additional && activeRows.length > 0) {
      throw new HttpsError(
        "failed-precondition",
        "Ca đã có người nhận. Bật chế độ hỗ trợ bổ sung nếu cần mời thêm.",
      );
    }
    const assignedUids = new Set(activeRows.map((row) => row.data().maNguoiCuuHo));
    if (uids.some((uid) => assignedUids.has(uid))) {
      throw new HttpsError("failed-precondition", "Có người trong danh sách đã nhận ca.");
    }

    const victimUid = maNanNhanCuaCa(request);
    if (uids.includes(victimUid)) {
      throw new HttpsError("invalid-argument", "Không thể mời chính nạn nhân.");
    }

    const prepared = [];
    for (const uid of uids) {
      const personRef = db.collection("NguoiDung").doc(uid);
      const restrictionRef = db.collection("HanCheNguoiDung").doc(uid);
      const adminRef = db.collection("Admin").doc(uid);
      const professionalRef = db.collection("HoSoCuuHoCoCCHN").doc(uid);
      const volunteerRef = db.collection("HoSoCuuHoKhongCCHN").doc(uid);
      const targetRef = db.collection("ChiTietPhanCongCuuHo")
        .doc(uid).collection("DanhSachNgay").doc(day)
        .collection("DanhSachPhanCong").doc(maYeuCau);
      const [personSnap, restrictionSnap, targetAdminSnap, professionalSnap,
        volunteerSnap, priorSnap, targetRows] = await Promise.all([
        tx.get(personRef),
        tx.get(restrictionRef),
        tx.get(adminRef),
        tx.get(professionalRef),
        tx.get(volunteerRef),
        tx.get(targetRef),
        tx.get(
          db.collectionGroup("DanhSachPhanCong")
            .where("maNguoiCuuHo", "==", uid)
            .where("maTrangThaiTiepNhan", "in", INVITE_OPEN_STATES)
            .limit(100),
        ),
      ]);

      if (targetRows.size >= 100) {
        throw new HttpsError("resource-exhausted", "Không xác định được lịch phân công của một ứng viên.");
      }
      const person = personSnap.data();
      const restriction = restrictionSnap.data() || {};
      const professionalApproved = profileApproved(professionalSnap.data()?.maTrangThaiHoSo);
      const volunteerApproved = profileApproved(volunteerSnap.data()?.maTrangThaiHoSo);
      if (
        !personSnap.exists ||
        targetAdminSnap.exists ||
        (!professionalApproved && !volunteerApproved) ||
        !rescueReady(person, restriction)
      ) {
        throw new HttpsError(
          "failed-precondition",
          `Ứng viên ${uid} không còn đủ điều kiện (online, hồ sơ, trạng thái sẵn sàng).`,
        );
      }
      if (!validCoordinates(person.viDo, person.kinhDo)) {
        throw new HttpsError("failed-precondition", `Ứng viên ${uid} không có tọa độ hợp lệ.`);
      }
      const distance = distanceKm(
        Number(request.viDo), Number(request.kinhDo),
        Number(person.viDo), Number(person.kinhDo),
      );
      if (distance > radius) {
        throw new HttpsError("failed-precondition", `Ứng viên ${uid} đã ra ngoài bán kính ${radius} km.`);
      }

      if (priorSnap.exists && !TERMINAL_ASSIGNMENT_STATES.has(
        priorSnap.data()?.maTrangThaiTiepNhan,
      )) {
        throw new HttpsError("failed-precondition", `Ứng viên ${uid} vẫn còn lời mời/phân công của ca này.`);
      }

      for (const row of targetRows.docs) {
        if (row.ref.path === targetRef.path) continue;
        const linkedSnap = await tx.get(db.collection("YeuCauCuuHo").doc(row.id));
        if (!linkedSnap.exists) {
          throw new HttpsError("failed-precondition", `Không xác định được ca đang mở của ${uid}.`);
        }
        if (
          belongsToRequest(row, linkedSnap) &&
          !TERMINAL_REQUEST_STATES.has(linkedSnap.data()?.maTinhTrangYeuCau)
        ) {
          throw new HttpsError(
            "failed-precondition",
            `Ứng viên ${uid} đang có lời mời hoặc đang hỗ trợ ca khác.`,
          );
        }
      }

      const attempt = requestRef.collection("DanhSachPhanCong").doc().id;
      prepared.push({
        uid,
        targetRef,
        attempt,
        prior: priorSnap.exists ? priorSnap.data() : null,
      });
    }

    // Chỉ ghi sau khi mọi ứng viên đều vượt qua toàn bộ kiểm tra.
    for (const item of prepared) {
      const history = item.prior
        ? [
          ...(Array.isArray(item.prior.lichSuLoiMoi) ? item.prior.lichSuLoiMoi : []),
          loiLoiMoiCu(item.prior),
        ]
        : [];
      tx.set(item.targetRef, {
        ...(history.length ? { lichSuLoiMoi: history } : {}),
        maPhanCong: item.attempt,
        maYeuCau,
        maNguoiCuuHo: item.uid,
        maTrangThaiTiepNhan: "cuuho_trangthai_phancong_chotiepnhan",
        maLoaiPhanCong: "phancong_thucong",
        loaiPhanCong: "Điều phối thủ công",
        maAdmin,
        boSung: additional,
        thoiGianGui: FieldValue.serverTimestamp(),
        hanPhanHoi: deadline,
      });
    }

    const version = (Number(request.phienBanDieuPhoi) || 0) + 1;
    tx.update(requestRef, {
      maLoiMoiDieuPhoi: prepared[0].attempt,
      nguoiDuocMoi: prepared[0].uid,
      ngayGuiLoiMoi: day,
      phienBanDieuPhoi: version,
      ngayDieuPhoi: FieldValue.serverTimestamp(),
    });

    return {
      maYeuCau,
      soLoiMoi: prepared.length,
      loiMoi: prepared.map((item) => ({
        uid: item.uid,
        maPhanCong: item.attempt,
        duongDan: item.targetRef.path,
      })),
    };
  });
});

const GOOGLE_PLACES_NEARBY_URL =
  "https://places.googleapis.com/v1/places:searchNearby";
const GOOGLE_PLACES_TYPES = [
  "hospital",
  "general_hospital",
  "medical_center",
  "medical_clinic",
  "doctor",
];

function taoTokenLienHeCoSo(payload, secret) {
  const encoded = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const signature = createHmac("sha256", secret).update(encoded).digest("base64url");
  return `${encoded}.${signature}`;
}

function docTokenLienHeCoSo(token, secret) {
  if (typeof token !== "string" || token.length > 4096) {
    throw new HttpsError("invalid-argument", "Phiên liên hệ không hợp lệ.");
  }
  const parts = token.split(".");
  if (parts.length !== 2) {
    throw new HttpsError("invalid-argument", "Phiên liên hệ không hợp lệ.");
  }
  const expected = createHmac("sha256", secret).update(parts[0]).digest();
  let received;
  try {
    received = Buffer.from(parts[1], "base64url");
  } catch (_) {
    throw new HttpsError("invalid-argument", "Phiên liên hệ không hợp lệ.");
  }
  if (received.length !== expected.length || !timingSafeEqual(received, expected)) {
    throw new HttpsError("permission-denied", "Phiên liên hệ không hợp lệ.");
  }
  let payload;
  try {
    payload = JSON.parse(Buffer.from(parts[0], "base64url").toString("utf8"));
  } catch (_) {
    throw new HttpsError("invalid-argument", "Phiên liên hệ không hợp lệ.");
  }
  if (!payload || !Number.isFinite(payload.exp) || payload.exp < Date.now()) {
    throw new HttpsError("deadline-exceeded", "Phiên liên hệ đã hết hạn. Hãy mở liên hệ lại.");
  }
  return payload;
}

async function goiGooglePlaces(url, options, context) {
  let response;
  try {
    response = await fetch(url, {
      ...options,
      signal: AbortSignal.timeout(12000),
    });
  } catch (error) {
    logger.warn("Google Places không phản hồi", {
      context,
      error: error?.name || "network_error",
    });
    throw new HttpsError(
      "unavailable",
      "Google Places đang không phản hồi. Vui lòng thử lại.",
    );
  }

  const raw = await response.text();
  let body = {};
  try {
    body = raw ? JSON.parse(raw) : {};
  } catch (_) {
    body = {};
  }

  if (!response.ok) {
    const googleStatus = body?.error?.status || `HTTP_${response.status}`;
    logger.error("Google Places API trả lỗi", {
      context,
      status: response.status,
      googleStatus,
    });
    if (response.status === 403 || response.status === 401) {
      throw new HttpsError(
        "failed-precondition",
        "Google Places API chưa được bật, chưa có thanh toán hoặc API key chưa được cấp quyền.",
      );
    }
    if (response.status === 429) {
      throw new HttpsError(
        "resource-exhausted",
        "Google Places đang giới hạn số lượt tìm kiếm. Vui lòng thử lại sau.",
      );
    }
    throw new HttpsError(
      "unavailable",
      "Không lấy được dữ liệu Google Places. Vui lòng thử lại.",
    );
  }
  return body;
}

async function docYeuCauCoSoYTe(maAdmin, maYeuCau) {
  const snap = await db.collection("YeuCauCuuHo").doc(maYeuCau).get();
  const request = snap.data();
  if (!snap.exists || !request) {
    throw new HttpsError("not-found", "Không tìm thấy yêu cầu cứu hộ.");
  }
  if (!MO.includes(request.maTinhTrangYeuCau)) {
    throw new HttpsError("failed-precondition", "Ca không còn ở trạng thái điều phối.");
  }
  if (request.maAdminDieuPhoi && request.maAdminDieuPhoi !== maAdmin) {
    throw new HttpsError("failed-precondition", "Ca đang do Admin khác phụ trách.");
  }
  if (!validCoordinates(request.viDo, request.kinhDo)) {
    throw new HttpsError("failed-precondition", "Yêu cầu chưa có tọa độ hợp lệ.");
  }
  return {
    ref: snap.ref,
    data: request,
    latitude: Number(request.viDo),
    longitude: Number(request.kinhDo),
  };
}

exports.adminTimCoSoYTe = onCall(
  { secrets: [GOOGLE_PLACES_API_KEY], timeoutSeconds: 25 },
  async ({ auth, data }) => {
    const maAdmin = await kiemTraAdmin(auth);
    const maYeuCau = maYeuCauHopLe(data?.maYeuCau);
    const radiusKm = Number(data?.radiusKm);
    if (!validRadius(radiusKm)) {
      throw new HttpsError("invalid-argument", "Bán kính phải là 1, 3 hoặc 5 km.");
    }
    const request = await docYeuCauCoSoYTe(maAdmin, maYeuCau);
    const apiKey = GOOGLE_PLACES_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Chưa cấu hình GOOGLE_PLACES_API_KEY trong Firebase Secret Manager.",
      );
    }

    const body = await goiGooglePlaces(
      GOOGLE_PLACES_NEARBY_URL,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": [
            "places.id",
            "places.displayName",
            "places.formattedAddress",
            "places.location",
            "places.primaryType",
          ].join(","),
        },
        body: JSON.stringify({
          includedTypes: GOOGLE_PLACES_TYPES,
          maxResultCount: 20,
          rankPreference: "DISTANCE",
          languageCode: "vi",
          regionCode: "VN",
          locationRestriction: {
            circle: {
              center: {
                latitude: request.latitude,
                longitude: request.longitude,
              },
              radius: radiusKm * 1000,
            },
          },
        }),
      },
      "nearby_search",
    );

    const places = Array.isArray(body.places) ? body.places : [];
    const results = places
      .filter((place) =>
        typeof place.id === "string" &&
        place.id.length > 0 &&
        typeof place.displayName?.text === "string" &&
        Number.isFinite(place.location?.latitude) &&
        Number.isFinite(place.location?.longitude))
      .map((place) => ({
        placeId: place.id,
        name: place.displayName.text,
        address: place.formattedAddress || "",
        latitude: place.location.latitude,
        longitude: place.location.longitude,
        category: place.primaryType || "healthcare",
      }));

    return {
      places: results,
      radiusKm,
      source: "GooglePlaces",
    };
  },
);

exports.adminLayThongTinLienHeCoSoYTe = onCall(
  { secrets: [GOOGLE_PLACES_API_KEY], timeoutSeconds: 20 },
  async ({ auth, data }) => {
    const maAdmin = await kiemTraAdmin(auth);
    const maYeuCau = maYeuCauHopLe(data?.maYeuCau);
    const placeId = typeof data?.placeId === "string" ? data.placeId.trim() : "";
    const radiusKm = Number(data?.radiusKm);
    if (!placeId || placeId.length > 300 || placeId.includes("/") ||
      !validRadius(radiusKm)) {
      throw new HttpsError("invalid-argument", "Thông tin cơ sở y tế không hợp lệ.");
    }

    const request = await docYeuCauCoSoYTe(maAdmin, maYeuCau);
    const apiKey = GOOGLE_PLACES_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Chưa cấu hình GOOGLE_PLACES_API_KEY trong Firebase Secret Manager.",
      );
    }

    const details = await goiGooglePlaces(
      `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`,
      {
        method: "GET",
        headers: {
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": [
            "id",
            "nationalPhoneNumber",
            "internationalPhoneNumber",
            "location",
          ].join(","),
        },
      },
      "place_details_contact",
    );

    if (details.id !== placeId ||
      !validCoordinates(details.location?.latitude, details.location?.longitude)) {
      throw new HttpsError("not-found", "Không xác minh được cơ sở y tế trên Google Maps.");
    }
    const actualDistance = distanceKm(
      request.latitude,
      request.longitude,
      details.location.latitude,
      details.location.longitude,
    );
    if (actualDistance > radiusKm) {
      throw new HttpsError(
        "failed-precondition",
        "Cơ sở y tế không nằm trong bán kính tìm kiếm của ca.",
      );
    }

    const contactToken = taoTokenLienHeCoSo({
      version: 1,
      maAdmin,
      maYeuCau,
      placeId,
      radiusKm,
      latitude: details.location.latitude,
      longitude: details.location.longitude,
      exp: Date.now() + 10 * 60 * 1000,
    }, apiKey);

    return {
      placeId,
      phone: details.nationalPhoneNumber ||
        details.internationalPhoneNumber || "",
      contactToken,
    };
  },
);

// Lịch sử chỉ lưu Place ID và kết quả thao tác do Admin ghi nhận.
// Thông tin địa điểm được lấy mới từ Google khi Admin mở chức năng liên hệ.
exports.adminGhiNhanLienHeCoSoYTe = onCall(
  { secrets: [GOOGLE_PLACES_API_KEY] },
  async ({ auth, data }) => {
    const maAdmin = await kiemTraAdmin(auth);
    const maYeuCau = maYeuCauHopLe(data?.maYeuCau);
    const placeId = typeof data?.placeId === "string" ? data.placeId.trim() : "";
    const ketQuaLienHe = data?.ketQuaLienHe;
    const ghiChu = typeof data?.ghiChu === "string" ? data.ghiChu.trim() : "";
    const apiKey = GOOGLE_PLACES_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Chưa cấu hình GOOGLE_PLACES_API_KEY trong Firebase Secret Manager.",
      );
    }
    const token = docTokenLienHeCoSo(data?.contactToken, apiKey);
    if (
      !placeId || placeId.length > 300 || placeId.includes("/") ||
      token.version !== 1 ||
      token.maAdmin !== maAdmin || token.maYeuCau !== maYeuCau ||
      token.placeId !== placeId || !validRadius(token.radiusKm) ||
      !validCoordinates(token.latitude, token.longitude) ||
      !validContactResult(ketQuaLienHe) || ghiChu.length > 1000
    ) {
      throw new HttpsError("invalid-argument", "Thông tin kết quả liên hệ chưa hợp lệ.");
    }

    const requestRef = db.collection("YeuCauCuuHo").doc(maYeuCau);
    const createdAt = Date.now();
    const suffix = createHash("sha256")
      .update(`${maAdmin}|${maYeuCau}|${placeId}|${createdAt}`)
      .digest("hex")
      .slice(0, 16);
    const logRef = requestRef.collection("LichSuLienHeCoSoYTe")
      .doc(`lienhe_${createdAt}_${suffix}`);

    await db.runTransaction(async (tx) => {
      const [adminSnap, requestSnap] = await Promise.all([
        tx.get(db.collection("Admin").doc(maAdmin)),
        tx.get(requestRef),
      ]);
      const request = requestSnap.data();
      if (adminSnap.data()?.trangThai !== "hoat_dong" || !request) {
        throw new HttpsError("permission-denied", "Không thể ghi lịch sử liên hệ.");
      }
      if (!MO.includes(request.maTinhTrangYeuCau)) {
        throw new HttpsError("failed-precondition", "Ca đã đóng, không thể ghi thêm liên hệ.");
      }
      if (request.maAdminDieuPhoi && request.maAdminDieuPhoi !== maAdmin) {
        throw new HttpsError("failed-precondition", "Ca đang do Admin khác phụ trách.");
      }
      if (!validCoordinates(request.viDo, request.kinhDo)) {
        throw new HttpsError("failed-precondition", "Yêu cầu chưa có tọa độ hợp lệ.");
      }
      const actualDistance = distanceKm(
        Number(request.viDo),
        Number(request.kinhDo),
        token.latitude,
        token.longitude,
      );
      if (actualDistance > token.radiusKm) {
        throw new HttpsError(
          "failed-precondition",
          "Cơ sở y tế không còn nằm trong bán kính tìm kiếm của ca.",
        );
      }
      tx.create(logRef, {
        maYeuCau,
        maAdmin,
        maCoSoYTe: placeId,
        tenCoSoYTe: null,
        soDienThoai: null,
        diaChi: null,
        viDo: null,
        kinhDo: null,
        khoangCachKm: null,
        ketQuaLienHe,
        tenKetQuaLienHe: CONTACT_RESULTS[ketQuaLienHe],
        ghiChu,
        nguonDuLieu: "GooglePlaces",
        thoiGian: FieldValue.serverTimestamp(),
      });
    });
    return { id: logRef.id, ketQuaLienHe };
  },
);

// Mirror tối thiểu để các màn hình phía người dùng đọc được tên Admin.
// Không thêm vai trò, GPS, số điện thoại hoặc trạng thái cứu hộ.
exports.dongBoHoSoAdmin = onCall(async ({ auth }) => {
  const uid = await kiemTraAdmin(auth);
  const userRef = db.collection("NguoiDung").doc(uid);
  await db.runTransaction(async (tx) => {
    const [adminSnap, userSnap] = await Promise.all([
      tx.get(db.collection("Admin").doc(uid)),
      tx.get(userRef),
    ]);
    if (adminSnap.data()?.trangThai !== "hoat_dong") {
      throw new HttpsError("permission-denied", "Tài khoản Admin không hoạt động.");
    }
    const existing = userSnap.data() || {};
    if (existing.maVaiTro && existing.maVaiTro !== "vaitro_admin") {
      throw new HttpsError(
        "already-exists",
        "UID Admin đang trùng với một hồ sơ người dùng khác; không ghi đè.",
      );
    }
    tx.set(userRef, adminMirror(uid), { merge: true });
  });
  return { synced: true, uid };
});

exports.khiCoCaMoi = onDocumentCreated(
  { document: "YeuCauCuuHo/{id}", retry: true },
  async (event) => {
    if (!event.data) return;
    await initializeDeadline(db, event.data.ref, thoiGianTimNguoi());
    await notifyAdmins(
      db,
      event.id,
      event.params.id,
      NEW_REQUEST_NOTICE.title,
      `${NEW_REQUEST_NOTICE.body} Mã yêu cầu: ${event.params.id}.`,
      NEW_REQUEST_NOTICE.kind,
      null,
      {
        maSuKien: NEW_REQUEST_NOTICE.eventCode,
        mucDoUuTien: NEW_REQUEST_NOTICE.priority,
      },
    );
    logger.info("Đã tạo thông báo ca mới", { maYeuCau: event.params.id });
  },
);

exports.khiCaCanCanThiep = onDocumentUpdated(
  { document: "YeuCauCuuHo/{id}", retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const current = (await event.data.after.ref.get()).data();
    if (!current) return;
    const notice = interventionEvent(before, current);
    if (!notice) return;
    await notifyAdmins(
      db,
      event.id,
      event.params.id,
      notice.title,
      `Mã yêu cầu: ${event.params.id}. ${notice.body}`,
      notice.kind,
      current.maAdminDieuPhoi,
      {
        maSuKien: notice.eventCode,
        mucDoUuTien: notice.priority,
      },
    );
  },
);

exports.datHanLoiMoi = onDocumentWritten(
  { document: ASSIGNMENT_PATH, retry: true },
  async (event) => {
    const ref = event.data?.after.ref;
    if (!ref || !event.data.after.exists) return;
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const row = snap.data();
      if (!row || !CHO.includes(row.maTrangThaiTiepNhan) ||
        row.maYeuCau !== event.params.ca || row.maNguoiCuuHo !== event.params.uid) return;
      const due = invitationDeadline(row, snap.createTime);
      if (due === null ||
        (row.hanPhanHoi instanceof Timestamp && row.hanPhanHoi.toMillis() === due)) return;
      tx.update(ref, { hanPhanHoi: Timestamp.fromMillis(due) });
    });
  },
);

const CHO_PHAN_HOI = Object.freeze([
  "da_gui_thong_bao", "cuuho_trangthai_chophanhoi",
  "cuuho_trangthai_phancong_chotiepnhan",
  "duoc_chon", "cuuho_trangthai_phancong_daphancong",
]);
const DA_NHAN_THUC_TE = Object.freeze([
  "da_dong_y", "cuuho_trangthai_phancong_tiepnhan",
  "cuuho_trangthai_phancong_daden", "cuuho_trangthai_phancong_dangcuuho",
]);
const CON_DANG_MO = Object.freeze([...CHO_PHAN_HOI, ...DA_NHAN_THUC_TE]);
const DA_KET_THUC = new Set([
  "da_huy", "tu_choi", "hoan_thanh", "cuuho_trangthai_phancong_dahuy",
  "cuuho_trangthai_phancong_tuchoi", "cuuho_trangthai_phancong_hoanthanh",
]);
const choSet = new Set(CHO_PHAN_HOI);
const nhanSet = new Set(DA_NHAN_THUC_TE);

function soNguoiCanCuuHo(request) {
  // App Cứu hộ đang có giới hạn cứng là 3.
  // Không suy đoán chỉ tiêu cho ca cũ thiếu dữ liệu hoặc ca >3.
  const value = request?.soNguoiCanCuuHo;
  if (typeof value !== "number" || !Number.isInteger(value) || value < 1 || value > 3) return null;
  return value;
}

function keHoachHuyLoiMoi(rows, request, belongsToRequest, requestSnap) {
  const quota = soNguoiCanCuuHo(request);
  if (quota === null) return { quota: null, accepted: 0, targets: [] };
  const current = rows.filter((row) => belongsToRequest(row, requestSnap));
  const accepted = new Set(current
    .filter((row) => nhanSet.has(row.data().maTrangThaiTiepNhan))
    .map((row) => row.data().maNguoiCuuHo)
    .filter((uid) => typeof uid === "string" && uid.length > 0));
  if (accepted.size < quota) return { quota, accepted: accepted.size, targets: [] };
  return {
    quota,
    accepted: accepted.size,
    targets: current.filter((row) => choSet.has(row.data().maTrangThaiTiepNhan) &&
      !accepted.has(row.data().maNguoiCuuHo)),
  };
}

async function huyLoiMoiKhiDuNguoi(db, maYeuCau, belongsToRequest, FieldValue, MO) {
  const requestRef = db.collection("YeuCauCuuHo").doc(maYeuCau);
  return db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    const request = requestSnap.data();
    if (!requestSnap.exists || !request || !MO.includes(request.maTinhTrangYeuCau)) {
      return { trangThai: "khong_con_mo", huy: 0 };
    }
    const rows = await tx.get(db.collectionGroup("DanhSachPhanCong")
      .where("maYeuCau", "==", maYeuCau)
      .where("maTrangThaiTiepNhan", "in", CON_DANG_MO)
      .limit(100));
    // Không hủy thiếu dữ liệu nếu ca có >=100 phân công đang mở.
    if (rows.size >= 100) return { trangThai: "qua_gioi_han", huy: 0 };
    const plan = keHoachHuyLoiMoi(rows.docs, request, belongsToRequest, requestSnap);
    if (plan.quota === null) return { trangThai: "chua_ro_so_nguoi_can", huy: 0 };
    if (plan.accepted < plan.quota) {
      return { trangThai: "chua_du_nguoi", daNhan: plan.accepted, can: plan.quota, huy: 0 };
    }
    for (const row of plan.targets) {
      tx.update(row.ref, {
        maTrangThaiTiepNhan: "cuuho_trangthai_phancong_dahuy",
        lyDoKetThuc: "da_du_nguoi",
        thoiGianPhanHoi: FieldValue.serverTimestamp(),
      });
    }
    return { trangThai: "da_du_nguoi", daNhan: plan.accepted, can: plan.quota, huy: plan.targets.length };
  });
}

// Trigger gọi lúc phân công kết thúc; KHÔNG tạo trigger trên toàn bộ NguoiDung (GPS cập nhật liên tục).
// Đọc lại dữ liệu ngay trong transaction để tránh kết quả cũ ghi đè lần mời mới.
async function dongBoRanhCuuHoVien(db, uid, options = {}) {
  const { ref, maPhanCong, terminalOnly = false } = options;
  if (typeof uid !== "string" || !uid.trim() || uid.includes("/")) return "uid_khong_hop_le";
  return db.runTransaction(async (tx) => {
    if (ref) {
      const source = await tx.get(ref);
      if (!source.exists || source.data()?.maNguoiCuuHo !== uid ||
        source.data()?.maPhanCong !== maPhanCong ||
        (terminalOnly && !DA_KET_THUC.has(source.data()?.maTrangThaiTiepNhan))) {
        return "phan_cong_da_thay_doi";
      }
    }
    const open = await tx.get(db.collectionGroup("DanhSachPhanCong")
      .where("maNguoiCuuHo", "==", uid)
      .where("maTrangThaiTiepNhan", "in", CON_DANG_MO)
      .limit(1));
    if (!open.empty) return "van_con_phan_cong";
    const userRef = db.collection("NguoiDung").doc(uid);
    const user = await tx.get(userRef);
    if (!user.exists || user.data()?.nhanCaCuuHo !== true) return "da_ranh";
    tx.update(userRef, { nhanCaCuuHo: false });
    return "da_giai_phong";
  });
}

exports.khiCuuHoVienPhanHoi = onDocumentWritten(
  { document: ASSIGNMENT_PATH, retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const currentStatus = after?.maTrangThaiTiepNhan;
    const beforeStatus = before?.maTrangThaiTiepNhan;
    if (beforeStatus === currentStatus) return;
    const pathRef = event.data?.after.ref || event.data?.before.ref;
    if (!pathRef) return;

    if (after && (after.maYeuCau !== event.params.ca ||
      after.maNguoiCuuHo !== event.params.uid || !after.maPhanCong)) {
      logger.warn("Phân công thiếu hoặc sai định danh; không đồng bộ hoàn thành", {
        path: pathRef.path, maYeuCau: event.params.ca,
      });
      return;
    }

    const result = await doiChieuCaSauPhanCong(db, event.params.ca,
      event.params.uid, pathRef, thoiGianChoXacNhan(),
      after ? event.data.after : event.data.before);
    if (result === "khac_lan_tao_ca") return;
    if (result === "du_lieu_phan_cong_sai") {
      logger.warn("Phân công có mã người/ca không nhất quán", { path: pathRef.path });
      return;
    }
    // App Người dùng có thể đặt nhanCaCuuHo=true ngay khi gửi lời mời.
    // Khi lời mời hủy/từ chối/hết hạn, chỉ giải phóng nếu KHÔNG có ca mở khác.
    if (after && beforeStatus !== currentStatus && DA_KET_THUC.has(currentStatus)) {
      await dongBoRanhCuuHoVien(db, event.params.uid, {
        ref: pathRef, maPhanCong: after.maPhanCong, terminalOnly: true,
      });
    }
    if (!before || !after) return;
    const notice = replyEvent(before, after);
    if (!notice) return;
    const latest = (await pathRef.get()).data();
    if (latest?.maTrangThaiTiepNhan !== after.maTrangThaiTiepNhan ||
      latest?.maPhanCong !== after.maPhanCong) return;
    const requestSnap = await db.collection("YeuCauCuuHo").doc(event.params.ca).get();
    const request = requestSnap.data();
    if (!belongsToRequest(event.data.after, requestSnap)) return;
    if (!request || !MO.includes(request.maTinhTrangYeuCau)) return;
    // Không được hủy người vừa nhận thứ hai; chỉ hủy lời mời còn chờ
    // khi số UID đã nhận thực tế >= soNguoiCanCuuHo (tối đa 3).
    if (DONG_Y.includes(after.maTrangThaiTiepNhan)) {
      const result = await huyLoiMoiKhiDuNguoi(
        db, event.params.ca, belongsToRequest, FieldValue, MO,
      );
      if (result.trangThai === "qua_gioi_han" ||
          result.trangThai === "chua_ro_so_nguoi_can") {
        logger.warn("Không hủy lời mời vì cần kiểm tra dữ liệu ca", {
          maYeuCau: event.params.ca, ...result,
        });
      }
    }
    // Mỗi lời mời đồng thời có một bản ghi phân công riêng.
    // Không lọc phản hồi theo con trỏ tương thích maLoiMoiDieuPhoi (chỉ trỏ lời mời đầu tiên).
    await notifyAdmins(
      db,
      event.id,
      event.params.ca,
      notice.title,
      `Mã yêu cầu: ${event.params.ca}. ${notice.body}`,
      "phan_hoi_dieu_phoi",
      request.maAdminDieuPhoi || after.maAdmin,
      {
        maSuKien: notice.eventCode,
        mucDoUuTien: notice.priority,
      },
    );
  },
);

// App cũ đôi khi gửi cập nhật trễ, đưa ca đã có người nhận về trạng thái chờ.
exports.suaTrangThaiDieuPhoiGhiTre = onDocumentUpdated(
  { document: "YeuCauCuuHo/{id}", retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const changed = Object.entries(after.danhSachPhanCongVien || {})
      .filter(([uid, status]) => typeof status === "string" &&
        before.danhSachPhanCongVien?.[uid] !== status);
    await removeHistoricalMembers(db, event.data.after.ref, changed);
    if (before.maTinhTrangYeuCau === after.maTinhTrangYeuCau ||
      !CHO_HOAC_QUA_HAN.includes(after.maTinhTrangYeuCau)) return;
    await reconcileRequest(db, event.data.after.ref, thoiGianTimNguoi());
    await kiemTraCaSauHetHanLoiMoi(db, event.params.id, thoiGianChoXacNhan());
  },
);

exports.adminXacMinhHoanThanhCa = onCall(async ({ auth, data }) => {
  const maAdmin = await kiemTraAdmin(auth);
  const maYeuCau = maYeuCauHopLe(data?.maYeuCau);
  const quyetDinh = data?.quyetDinh;
  const lyDo = typeof data?.lyDo === "string" ? data.lyDo.trim() : "";
  if (!["hoan_thanh", "can_can_thiep"].includes(quyetDinh) ||
    lyDo.length < 10 || lyDo.length > 1000) {
    throw new HttpsError("invalid-argument", "Cần quyết định hợp lệ và lý do 10–1000 ký tự.");
  }
  const requestRef = db.collection("YeuCauCuuHo").doc(maYeuCau);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(requestRef);
    const request = snap.data();
    if (!request) throw new HttpsError("not-found", "Không tìm thấy ca cứu hộ.");
    if (request.maTinhTrangYeuCau === TRANG_THAI_CA_HOAN_THANH &&
      request.trangThaiXacNhanHoanThanh === XAC_NHAN.DA_HOAN_THANH) {
      return { ketQua: "da_hoan_thanh", maYeuCau };
    }
    if (!MO.includes(request.maTinhTrangYeuCau)) {
      throw new HttpsError("failed-precondition", "Ca không còn ở trạng thái đang xử lý.");
    }
    const state = await docTongQuanPhanCong(tx, db, snap);
    if (quyetDinh === "hoan_thanh" && !ketQuaDaDuDieuKien(state)) {
      throw new HttpsError("failed-precondition",
        "Chưa đủ điều kiện: vẫn còn cứu hộ đang làm/lời mời chờ, hoặc chưa ai báo hoàn thành.");
    }
    tx.update(requestRef, quyetDinh === "hoan_thanh"
      ? taoBanGhiDongCa(request, "admin", maAdmin, lyDo)
      : {
        trangThaiXacNhanHoanThanh: XAC_NHAN.CAN_CAN_THIEP,
        canKiemTra: true, lyDoCanKiemTra: lyDo
      });
    tx.create(requestRef.collection("LichSuXacNhanCa").doc(), {
      maAdmin, quyetDinh, lyDo, ngayXuLy: FieldValue.serverTimestamp(),
      trangThaiCu: request.maTinhTrangYeuCau,
    });
    return { ketQua: quyetDinh, maYeuCau };
  });
});

async function xuLyLoiMoiHetHan(ref, maPhanCong) {
  const changed = await expireInvitation(db, ref, maPhanCong);
  if (changed) await kiemTraCaSauHetHanLoiMoi(db, ref.id, thoiGianChoXacNhan());
  return changed;
}

// Callable riêng cho Admin: khóa/tạm ngừng tài khoản chỉ khi không còn
// lời mời chờ hoặc ca cứu hộ đang mở. Không được gọi bởi hai ứng dụng client.
const PENDING_ASSIGNMENT_STATES = new Set([
  "da_gui_thong_bao",
  "cuuho_trangthai_chophanhoi",
  "cuuho_trangthai_phancong_chotiepnhan",
]);
const ACTIVE_ASSIGNMENT_STATES = new Set([
  "da_dong_y",
  "duoc_chon",
  "cuuho_trangthai_phancong_tiepnhan",
  "cuuho_trangthai_phancong_daphancong",
  "cuuho_trangthai_phancong_daden",
  "cuuho_trangthai_phancong_dangcuuho",
]);
const TERMINAL_ASSIGNMENT_STATES = new Set([
  "da_huy",
  "tu_choi",
  "hoan_thanh",
  "cuuho_trangthai_phancong_dahuy",
  "cuuho_trangthai_phancong_tuchoi",
  "cuuho_trangthai_phancong_hoanthanh",
]);
const TERMINAL_REQUEST_STATES = new Set([
  "hoan_thanh",
  "da_huy",
  "user_tinhtrang_hoanthanh",
  "user_tinhtrang_dahuy",
]);
function maNanNhanCuaCa(data) {
  for (const key of ["maNguoiYeuCau", "maNguoiDung"]) {
    if (typeof data?.[key] === "string" && data[key].trim()) return data[key].trim();
  }
  return "";
}
function trangThaiYeuCauChuan(value) {
  const aliases = {
    user_tinhtrang_hoanthanh: "hoan_thanh",
    user_tinhtrang_dahuy: "da_huy",
    user_tinhtrang_chotiepnhan: "cho_tiep_nhan",
    user_tinhtrang_quahandieuphoi: "qua_han_dieu_phoi",
    user_tinhtrang_daphancong: "da_phan_cong",
    user_tinhtrang_dangcuuho: "dang_cuu_ho",
  };
  return aliases[typeof value === "string" ? value.trim() : ""] ||
    (typeof value === "string" ? value.trim() : "");
}

exports.adminCapNhatHanCheNguoiDung = onCall(async ({ auth, data }) => {
  const maAdmin = await kiemTraAdmin(auth);
  const uid = maYeuCauHopLe(data?.uid);
  const action = data?.action;
  const lyDo = typeof data?.lyDo === "string" ? data.lyDo.trim() : "";
  const expectedVersion = data?.expectedVersion;
  if (uid === maAdmin) {
    throw new HttpsError("failed-precondition", "Không thao tác trên chính tài khoản Admin.");
  }
  if (!["khoa", "mo_khoa", "tam_ngung", "khoi_phuc"].includes(action) ||
      lyDo.length < 5 || lyDo.length > 500 ||
      !Number.isInteger(expectedVersion) || expectedVersion < 0) {
    throw new HttpsError("invalid-argument", "Thao tác, lý do hoặc phiên bản tài khoản không hợp lệ.");
  }

  const userRef = db.collection("NguoiDung").doc(uid);
  const restrictionRef = db.collection("HanCheNguoiDung").doc(uid);
  const adminRef = db.collection("Admin").doc(maAdmin);
  const targetAdminRef = db.collection("Admin").doc(uid);
  const logRef = userRef.collection("NhatKyQuanTri").doc();

  return db.runTransaction(async (tx) => {
    const [adminSnap, targetAdminSnap, userSnap, restrictionSnap] = await Promise.all([
      tx.get(adminRef), tx.get(targetAdminRef), tx.get(userRef), tx.get(restrictionRef),
    ]);
    if (adminSnap.data()?.trangThai !== "hoat_dong" || targetAdminSnap.exists) {
      throw new HttpsError("permission-denied", "Không có quyền xử lý tài khoản này.");
    }
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "Tài khoản không còn tồn tại.");
    }
    const current = restrictionSnap.data() || {};
    const version = Number.isInteger(current.phienBan) ? current.phienBan : 0;
    if (version !== expectedVersion) {
      throw new HttpsError("aborted", "Dữ liệu tài khoản đã thay đổi. Hãy tải lại trước khi xử lý.");
    }
    const locked = current.khoa === true;
    const suspended = current.tamNgungHoTro === true;

    if (action === "khoa" || action === "tam_ngung") {
      // Query được thực hiện bên trong transaction để tránh khóa tài khoản
      // đồng thời với lúc Admin gửi lời mời cứu hộ.
      const assignments = await tx.get(
        db.collectionGroup("DanhSachPhanCong").where("maNguoiCuuHo", "==", uid),
      );
      const sosIds = new Set();
      let hasPendingInvitation = false;
      for (const row of assignments.docs) {
        const status = row.data().maTrangThaiTiepNhan;
        if (PENDING_ASSIGNMENT_STATES.has(status)) {
          hasPendingInvitation = true;
          continue;
        }
        if (ACTIVE_ASSIGNMENT_STATES.has(status)) {
          const id = row.data().maYeuCau;
          if (typeof id !== "string" || !id.trim() || id.includes("/")) {
            throw new HttpsError("failed-precondition", "Phân công có mã yêu cầu không hợp lệ.");
          }
          sosIds.add(id);
          continue;
        }
        if (!TERMINAL_ASSIGNMENT_STATES.has(status)) {
          throw new HttpsError("failed-precondition", "Có phân công chưa xác định trạng thái. Hãy kiểm tra trước khi khóa/tạm ngừng.");
        }
      }
      if (hasPendingInvitation) {
        throw new HttpsError("failed-precondition", "Người cứu hộ còn lời mời đang chờ phản hồi. Hãy hủy hoặc chờ lời mời kết thúc trước khi khóa/tạm ngừng tài khoản.");
      }
      if (userSnap.data()?.nhanCaCuuHo === true) {
        throw new HttpsError("failed-precondition", "Tài khoản vẫn đang bật trạng thái nhận ca. Hãy chờ ứng dụng cập nhật trạng thái rảnh và kiểm tra lại trước khi khóa/tạm ngừng.");
      }

      if (action === "khoa") {
        const [byRequester, byUser] = await Promise.all([
          tx.get(db.collection("YeuCauCuuHo").where("maNguoiYeuCau", "==", uid)),
          tx.get(db.collection("YeuCauCuuHo").where("maNguoiDung", "==", uid)),
        ]);
        for (const row of [...byRequester.docs, ...byUser.docs]) {
          if (maNanNhanCuaCa(row.data()) === uid) sosIds.add(row.id);
        }
      }

      for (const id of sosIds) {
        const sosSnap = await tx.get(db.collection("YeuCauCuuHo").doc(id));
        if (!sosSnap.exists) {
          throw new HttpsError("failed-precondition", `Không tìm thấy yêu cầu ${id} đang liên kết với tài khoản.`);
        }
        const status = trangThaiYeuCauChuan(sosSnap.data()?.maTinhTrangYeuCau);
        if (![
          "cho_tiep_nhan", "qua_han_dieu_phoi", "da_phan_cong", "dang_cuu_ho",
          "cho_dong", "hoan_thanh", "da_huy",
        ].includes(status)) {
          throw new HttpsError("failed-precondition", `Yêu cầu ${id} chưa xác định trạng thái. Cần kiểm tra trước khi khóa/tạm ngừng.`);
        }
        if (!TERMINAL_REQUEST_STATES.has(status)) {
          throw new HttpsError("failed-precondition", "Còn yêu cầu cứu hộ chưa giải quyết; không thể khóa hoặc tạm ngừng.");
        }
      }
    }

    const patch = {};
    if (action === "khoa" || action === "mo_khoa") {
      if ((action === "khoa" && locked) || (action === "mo_khoa" && !locked)) {
        throw new HttpsError("failed-precondition", "Trạng thái khóa tài khoản đã thay đổi.");
      }
      patch.khoa = action === "khoa";
    } else {
      if ((action === "tam_ngung") === suspended) {
        throw new HttpsError("failed-precondition", "Trạng thái quyền hỗ trợ không phù hợp.");
      }
      patch.tamNgungHoTro = action === "tam_ngung";
    }
    tx.set(restrictionRef, {
      khoa: locked,
      tamNgungHoTro: suspended,
      ...patch,
      phienBan: version + 1,
      ngayCapNhat: FieldValue.serverTimestamp(),
      maAdmin,
      lyDo,
    });
    tx.set(logRef, {
      hanhDong: action,
      maAdmin,
      lyDo,
      thoiGian: FieldValue.serverTimestamp(),
      trangThai: "thanh_cong",
      thayDoi: patch,
      phienBan: version + 1,
      phamVi: "ung_dung",
    });
    return { uid, action, phienBan: version + 1 };
  });
});

exports.ketThucLoiMoiHetHan = onCall(async ({ auth, data }) => {
  await kiemTraAdmin(auth);
  if (!Array.isArray(data?.invitations) || data.invitations.length > 20) {
    throw new HttpsError("invalid-argument", "Danh sách lời mời không hợp lệ.");
  }
  const results = await Promise.all(data.invitations.map(async (item) => {
    if (typeof item?.path !== "string" ||
      !/^ChiTietPhanCongCuuHo\/[^/]+\/DanhSachNgay\/\d{4}-\d{2}-\d{2}\/DanhSachPhanCong\/[^/]+$/.test(item.path) ||
      typeof item.id !== "string" || !item.id || item.id.includes("/")) {
      throw new HttpsError("invalid-argument", "Đường dẫn lời mời không hợp lệ.");
    }
    const ref = db.doc(item.path);
    const changed = await xuLyLoiMoiHetHan(ref, item.id);
    const latest = (await ref.get()).data();
    return {
      path: item.path, id: item.id, changed,
      finished: !latest || latest.maPhanCong !== item.id ||
        !CHO.includes(latest.maTrangThaiTiepNhan)
    };
  }));
  return {
    expired: results.filter((row) => row.changed).length,
    finished: results.filter((row) => row.finished)
  };
});

exports.hetHanLoiMoi = onSchedule({
  schedule: "every 1 minutes", timeZone: "Asia/Ho_Chi_Minh",
  maxInstances: 1, retryCount: 3,
}, async () => {
  let count = 0;
  let cursor;
  for (let page = 0; page < 10; page++) {
    let query = db.collectionGroup("DanhSachPhanCong")
      .where("maTrangThaiTiepNhan", "in", CHO).limit(100);
    if (cursor) query = query.startAfter(cursor);
    const rows = await query.get();
    if (rows.empty) break;
    cursor = rows.docs.at(-1);
    for (let i = 0; i < rows.size; i += 10) {
      const group = rows.docs.slice(i, i + 10);
      const results = await Promise.all(group.map(doc =>
        xuLyLoiMoiHetHan(doc.ref, doc.data().maPhanCong)
      ));
      count += results.filter(Boolean).length;
    }
    if (rows.size < 100) break;
  }
  if (count) logger.info("Đã xử lý lời mời hết hạn", { soLuong: count });
  const requests = await scanWaitingRequests(db, thoiGianTimNguoi());
  if (requests.overdue || requests.accepted) logger.info("Đã đối chiếu yêu cầu chờ", requests);
  if (requests.conflict || requests.remaining) logger.warn("Yêu cầu còn xung đột/chờ lượt xử lý sau", requests);
});

// Khi hết hạn, quản trị viên cần liên hệ với nạn nhân trước khi đóng ca.
exports.quetCaQuaHanXacNhan = onSchedule({
  schedule: "every 5 minutes", timeZone: "Asia/Ho_Chi_Minh",
  maxInstances: 1, retryCount: 3,
}, async () => {
  let count = 0;
  const now = Timestamp.now();
  let cursor;
  for (let page = 0; page < 10; page++) {
    let query = db.collection("YeuCauCuuHo")
      .where("trangThaiXacNhanHoanThanh", "==", XAC_NHAN.CHO_NAN_NHAN)
      .where("hanXacNhanHoanThanh", "<=", now)
      .orderBy("hanXacNhanHoanThanh").limit(100);
    if (cursor) query = query.startAfter(cursor);
    const rows = await query.get();
    if (rows.empty) break;
    cursor = rows.docs.at(-1);
    for (const doc of rows.docs) {
      const changed = await db.runTransaction(async (tx) => {
        const snap = await tx.get(doc.ref);
        const r = snap.data();
        if (!r || !MO.includes(r.maTinhTrangYeuCau) ||
          r.trangThaiXacNhanHoanThanh !== XAC_NHAN.CHO_NAN_NHAN ||
          !(r.hanXacNhanHoanThanh instanceof Timestamp) ||
          r.hanXacNhanHoanThanh.toMillis() > Date.now()) return false;
        tx.update(doc.ref, {
          trangThaiXacNhanHoanThanh: XAC_NHAN.QUA_HAN_CHO_ADMIN,
          canKiemTra: true,
          lyDoCanKiemTra: "qua_han_nhan_xac_nhan_hoan_thanh",
          ngayChuyenAdminXacMinh: FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (changed) count++;
    }
    if (rows.size < 100) break;
  }
  if (count) logger.info("Đã chuyển ca quá hạn xác nhận cho Admin", { soCa: count });
});

exports.guiThongBaoDay = onDocumentCreated(
  { document: "ThongBao/{id}", retry: true },
  async (event) => {
    if (event.data?.data().nguon !== "cloud_function") return;
    await sendNotice(db, event.data.ref);
  },
);

exports.taoTaiKhoanAdmin = onCall(async ({ auth, data }) => {
  if (!auth) throw new HttpsError("unauthenticated", "Vui lòng đăng nhập lại.");
  const admins = db.collection("Admin");
  if ((await admins.doc(auth.uid).get()).data()?.trangThai !== "hoat_dong") {
    throw new HttpsError(
      "permission-denied",
      "Chỉ quản trị viên đang hoạt động được tạo tài khoản.",
    );
  }
  function field(key, max, required = false) {
    const raw = data?.[key];
    if (
      typeof raw !== "string" ||
      raw.trim().length > max ||
      (required && !raw.trim())
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Thông tin tài khoản chưa hợp lệ.",
      );
    }
    return raw.trim();
  }
  const email = field("email", 254, true);
  const hoTen = field("hoTen", 80, true);
  const soDienThoai = field("soDienThoai", 16);
  const password = data.password;
  if (
    !/^([^\s@]+)@([^\s@]+)\.([^\s@]+)$/.test(email) ||
    !/^([+]?[0-9]{8,15})?$/.test(soDienThoai) ||
    typeof password !== "string" ||
    password.length < 8 ||
    password.length > 128
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Kiểm tra email, điện thoại và mật khẩu (8–128 ký tự).",
    );
  }
  const identity = getAuth();
  let user;
  try {
    user = await identity.createUser({ email, password });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Email đã có tài khoản.");
    }
    throw new HttpsError(
      "failed-precondition",
      "Không tạo được tài khoản đăng nhập.",
    );
  }
  const adminRef = admins.doc(user.uid);
  const mirrorRef = db.collection("NguoiDung").doc(user.uid);
  const existingMirror = await mirrorRef.get();
  if (
    existingMirror.exists &&
    existingMirror.data()?.maVaiTro &&
    existingMirror.data().maVaiTro !== "vaitro_admin"
  ) {
    await identity.deleteUser(user.uid);
    throw new HttpsError(
      "already-exists",
      "UID mới trùng với hồ sơ người dùng hiện có; không ghi đè.",
    );
  }
  try {
    const batch = db.batch();
    batch.create(adminRef, {
      email: user.email,
      hoTen,
      soDienThoai,
      trangThai: "hoat_dong",
      ngayTao: Timestamp.now(),
      maAdminTao: auth.uid,
    });
    batch.set(mirrorRef, adminMirror(user.uid), { merge: true });
    await batch.commit();
  } catch (error) {
    // Nếu batch chưa lưu Admin, có thể xóa Auth. Nếu kết quả commit chưa rõ,
    // giữ tài khoản để tránh xóa nhầm; callable dongBoHoSoAdmin sẽ đối chiếu lại.
    if (!(await adminRef.get()).exists) {
      await identity.deleteUser(user.uid);
      throw new HttpsError("internal", "Không lưu được hồ sơ quản trị viên.");
    }
  }
  return { uid: user.uid };
});
