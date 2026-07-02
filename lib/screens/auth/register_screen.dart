import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/primary_button.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;
  bool _agree = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Please agree to the Terms to continue.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().register(
        fullName: _nameCtrl.text,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(email: _emailCtrl.text.trim()),
          ),
        );
      }
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
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const GradientHeadline(
                    'Join the\npack.',
                    fontSize: 80,
                    height: 0.9,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create an account to unlock member-only pricing and faster checkout.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                  ),
                  const SizedBox(height: 36),
                  Text('Full Name', style: AppTypography.captionMd),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    cursorColor: AppColors.ink,
                    decoration: InputDecoration(
                      hintText: 'Jane Doe',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.stone,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.stone,
                      ),
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
                    obscureText: _obscure1,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    cursorColor: AppColors.ink,
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.stone,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure1 ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.mute,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Confirm Password', style: AppTypography.captionMd),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure2,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    cursorColor: AppColors.ink,
                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.stone,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure2 ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.mute,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agree,
                          activeColor: AppColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) => setState(() => _agree = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy.',
                          style: AppTypography.captionMd.copyWith(
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTypography.captionMd.copyWith(
                        color: AppColors.sale,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: _loading ? 'Creating account...' : 'Join Us',
                    expand: true,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already a member? ',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.mute,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Sign In',
                          style: AppTypography.linkMd.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
