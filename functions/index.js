const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.syncOnlineStatus = functions.database
    .ref("/NguoiDung/{userId}/isOnline")
    .onWrite(async (change, context) => {
        const isOnline = change.after.val();
        const userId = context.params.userId;
        const userDocRef = admin.firestore().collection("NguoiDung").doc(userId);

        try {
            await userDocRef.set({isOnline: isOnline === true}, {merge: true});
            console.log(`Updated ${userId} to ${isOnline}`);
        } catch (error) {
            console.error("Error updating Firestore:", error);
        }
    });