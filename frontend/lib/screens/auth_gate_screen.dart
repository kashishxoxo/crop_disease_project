import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key, required this.messengerKey});

  final GlobalKey<ScaffoldMessengerState> messengerKey;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return _AuthenticatedHome(
            uid: user.uid,
            messengerKey: messengerKey,
          );
        }
        return const LoginScreen();
      },
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome({
    required this.uid,
    required this.messengerKey,
  });

  final String uid;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.initializeForUser(
        uid: widget.uid,
        messengerKey: widget.messengerKey,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfileModel?>(
      stream: UserService.profileStream(widget.uid),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = profileSnapshot.data;
        if (profile == null) {
          return ProfileSetupScreen(uid: widget.uid);
        }
        return const DashboardScreen();
      },
    );
  }
}
