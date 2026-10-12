import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Optional development setup; invoke AFTER Firebase.initializeApp and BEFORE
/// Firestore/Auth are used anywhere else. Do not invoke in production.
Future<void> connectAdminEmulators({String host = '127.0.0.1'}) async {
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instanceFor(region: 'asia-southeast1')
      .useFunctionsEmulator(host, 5001);
}
