const Module = require("node:module");
const originalLoad = Module._load;
class Timestamp {
  constructor(ms) { this._ms = ms; }
  toMillis() { return this._ms; }
  static fromMillis(ms) { return new Timestamp(ms); }
  static now() { return new Timestamp(Date.now()); }
}
class HttpsError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
Module._load = function(request, parent, isMain) {
  if (request === "firebase-admin/firestore") {
    return {
      FieldValue: {
        serverTimestamp: () => ({__serverTimestamp: true}),
        delete: () => ({__delete: true}),
      },
      Timestamp,
      FieldPath: {documentId: () => "__name__"},
    };
  }
  if (request === "firebase-admin/messaging") {
    return {getMessaging: () => ({send: async () => "mock-message-id"})};
  }
  if (request === "firebase-functions/v2/https") {
    return {HttpsError};
  }
  return originalLoad.call(this, request, parent, isMain);
};
