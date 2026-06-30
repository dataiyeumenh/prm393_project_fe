import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/api_service.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const PawFuelApp());
}

class PawFuelApp extends StatelessWidget {
  const PawFuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => CartState()),
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
    return const HomeScreen(key: ValueKey('home'));
  }
}
