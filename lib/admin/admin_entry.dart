import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'account/account_screens.dart';

/// Open this widget inside the existing MaterialApp after Firebase.initializeApp.
/// Auth gate is UI only; Firestore Rules and Cloud Functions enforce permissions.
class AdminEntry extends StatelessWidget {
  const AdminEntry({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      return user == null
          ? const LoginScreen()
          : AdminGate(key: ValueKey(user.uid), user: user);
    },
  );
}

class AdminGate extends StatelessWidget {
  final User user;
  const AdminGate({super.key, required this.user});
  Future<bool> check() async {
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: check(),
    builder: (context, token) {
      if (token.connectionState != ConnectionState.done)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (token.hasError || token.data != true) return denied();
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('Admin')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          if (snapshot.hasError ||
              snapshot.data?.data()?['trangThai'] != 'hoat_dong')
            return denied();
          return const AccountsScreen();
        },
      );
    },
  );
  Widget denied() => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tài khoản chưa có quyền Admin đang hoạt động.'),
          TextButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted)
        setState(
          () => error = e.code == 'network-request-failed'
              ? 'Kiểm tra kết nối mạng.'
              : 'Đăng nhập không thành công. Kiểm tra tài khoản và mật khẩu.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              Text(
                'Quản trị cứu hộ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Admin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                onSubmitted: (_) => login(),
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              FilledButton(
                onPressed: busy ? null : login,
                child: Text(busy ? 'Đang đăng nhập…' : 'Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
