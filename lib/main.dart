import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/user_shell.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("FCM: Background message ID: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase và FCM
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService.setupFCM();

  await ApiService.init();
  // Restore any cart from a previous run before the first frame, so a
  // process kill before checkout doesn't silently drop it.
  final cartState = CartState();
  await cartState.loadFromLocal();
  runApp(PawFuelApp(cartState: cartState));
}

class PawFuelApp extends StatelessWidget {
  const PawFuelApp({super.key, required this.cartState});

  final CartState cartState;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider.value(value: cartState),
      ],
      child: MaterialApp(
        title: 'PawFuel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isAuthenticated) {
      return const LoginScreen(key: ValueKey('login'));
    }
    if (auth.isAdmin) {
      return const AdminShell(key: ValueKey('admin'));
    }
    return const UserShell(key: ValueKey('user'));
  }
}
