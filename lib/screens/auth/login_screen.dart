import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/primary_nav_bar.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context
          .read<AuthState>()
          .login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginDemo() async {
    final demo = MockAuthApi.accounts.first;
    _emailCtrl.text = demo.email;
    _passwordCtrl.text = demo.password;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().login(demo.email, demo.password);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppLogo(size: 36),
                ),
                const SizedBox(height: 48),
                const GradientHeadline(
                  'Welcome\nback.',
                  fontSize: 80,
                  height: 0.9,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to fuel your pet\'s happiest life.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                ),
                const SizedBox(height: 36),
                Text('Email', style: AppTypography.captionMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                  cursorColor: AppColors.ink,
                  decoration: InputDecoration(
                    hintText: 'you@petlovers.com',
                    hintStyle: AppTypography.bodyMd
                        .copyWith(color: AppColors.stone),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Password', style: AppTypography.captionMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                  cursorColor: AppColors.ink,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTypography.bodyMd
                        .copyWith(color: AppColors.stone),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.mute,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot password?',
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.ink,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTypography.captionMd.copyWith(color: AppColors.sale),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: _loading ? 'Signing in...' : 'Sign In',
                  expand: true,
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.hairline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: AppTypography.utilityXs.copyWith(
                          color: AppColors.mute,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.hairline)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _DemoAccountCard(onTap: _loading ? null : _loginDemo),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "New to PawFuel? ",
                      style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Join Us',
                        style: AppTypography.linkMd.copyWith(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

class _DemoAccountCard extends StatelessWidget {
  const _DemoAccountCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: AppColors.softCloud,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hairline),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.bolt,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in with demo account',
                      style: AppTypography.bodyStrong.copyWith(
                        color: disabled ? AppColors.mute : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'trieu@gmail.com  •  123456',
                      style: AppTypography.captionSm.copyWith(
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: disabled ? AppColors.stone : AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
