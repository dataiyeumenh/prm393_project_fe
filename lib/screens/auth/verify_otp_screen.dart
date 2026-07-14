import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/primary_button.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const int _resendCooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  String? _error;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
        return;
      }
      setState(() => _cooldown--);
    });
  }

  Future<void> _resendOtp() async {
    if (_resending || _cooldown > 0) return;

    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      await context.read<AuthState>().resendOtp(email: widget.email);
      _startCooldown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi mã OTP đến ${widget.email}',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthState>().verifyOtp(
        email: widget.email,
        otpCode: _otpCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
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
                  const SizedBox(height: 24),
                  const GradientHeadline(
                    'Xác minh\nmã của bạn.',
                    fontSize: 72,
                    height: 0.9,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chúng tôi đã gửi mã OTP đến ${widget.email}. Nhập mã để kích hoạt tài khoản nhé.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                  ),
                  const SizedBox(height: 32),
                  Text('Mã OTP', style: AppTypography.captionMd),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    cursorColor: AppColors.ink,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã OTP',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.stone,
                      ),
                    ),
                    validator: (v) {
                      final code = v?.trim() ?? '';
                      if (code.isEmpty) return 'Vui lòng nhập mã';
                      if (code.length < 4) return 'Mã OTP quá ngắn';
                      return null;
                    },
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
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
                    label: _loading ? 'Đang xác minh...' : 'Xác minh OTP',
                    expand: true,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: (_resending || _cooldown > 0)
                        ? null
                        : _resendOtp,
                    child: Text(
                      _resending
                          ? 'Đang gửi OTP...'
                          : _cooldown > 0
                          ? 'Gửi lại OTP sau ${_cooldown}s'
                          : 'Gửi lại OTP qua email',
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.ink,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(
                      'Quay lại đăng nhập',
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.ink,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
