import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/api/auth_dto.dart';
import '../../services/user_profile_service.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/primary_nav_bar.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserProfileDTO? _profile;
  bool _loading = true;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final result = await UserProfileService.getProfile();
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final p = result.data!;
      setState(() {
        _profile = p;
        _loading = false;
      });
      context.read<AuthState>().updateProfile(
        fullName: p.fullName,
        phone: p.phone,
        address: p.address,
        avatarUrl: p.avatarUrl,
      );
      return;
    }

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sale,
        content: Text(
          result.error ?? 'Không tải được hồ sơ',
          style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

  Future<void> _openEditProfileSheet() async {
    final current = _profile;
    final value = await showModalBottomSheet<_ProfileFormValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditSheet(
        initialFullName: current?.fullName ?? '',
        initialPhone: current?.phone ?? '',
        initialAddress: current?.address ?? '',
      ),
    );
    if (value == null) return;

    final result = await UserProfileService.updateProfile(
      UpdateProfileRequest(
        fullName: value.fullName,
        phone: value.phone.isEmpty ? null : value.phone,
        address: value.address.isEmpty ? null : value.address,
      ),
    );

    if (!mounted) return;
    if (result.isSuccess) {
      await _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(
            'Cập nhật thông tin thành công',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sale,
        content: Text(
          result.error ?? 'Cập nhật thông tin thất bại',
          style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    final bytes = await picked.readAsBytes();
    final result = await UserProfileService.updateAvatar(
      bytes: bytes,
      fileName: picked.name,
    );

    if (!mounted) return;
    setState(() => _uploadingAvatar = false);

    if (result.isSuccess) {
      await _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(
            'Cập nhật ảnh đại diện thành công',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sale,
        content: Text(
          result.error ?? 'Cập nhật ảnh đại diện thất bại',
          style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final fullName = _profile?.fullName ?? user?.fullName ?? 'Khách';
    final email = _profile?.email ?? user?.email ?? '—';
    final phone = _profile?.phone;
    final address = _profile?.address;
    final avatarUrl = _profile?.avatarUrl ?? user?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: const PrimaryNavBar(title: 'Tài khoản'),
      ),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const SizedBox(height: 8),
                  _ProfileHeader(
                    name: fullName,
                    email: email,
                    avatarUrl: avatarUrl,
                    loadingAvatar: _uploadingAvatar,
                    onAvatarTap: _pickAndUploadAvatar,
                  ),
                  const SizedBox(height: 20),
                  _ProfileSection(
                    title: 'Hồ sơ',
                    children: [
                      _ProfileTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Thông tin cá nhân',
                        subtitle: phone?.isNotEmpty == true ? phone : null,
                        onTap: _openEditProfileSheet,
                      ),
                      _ProfileTile(
                        icon: Icons.location_on_outlined,
                        label: 'Địa chỉ',
                        subtitle: address?.isNotEmpty == true
                            ? address
                            : 'Chưa cập nhật',
                        onTap: _openEditProfileSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: 'Hoạt động',
                    children: [
                      _ProfileTile(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Đơn hàng của tôi',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng đang phát triển'),
                            ),
                          );
                        },
                      ),
                      _CartSummaryTile(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: 'Hỗ trợ',
                    children: [
                      _ProfileTile(
                        icon: Icons.help_outline_rounded,
                        label: 'Trung tâm trợ giúp',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng đang phát triển'),
                            ),
                          );
                        },
                      ),
                      _ProfileTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Liên hệ',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng đang phát triển'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _LogoutButton(),
                ],
              ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.onAvatarTap,
    this.avatarUrl,
    this.loadingAvatar = false,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onAvatarTap;
  final bool loadingAvatar;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((s) => s.isEmpty ? '' : s[0].toUpperCase())
              .join();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.accentPinkDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: InkWell(
              onTap: loadingAvatar ? null : onAvatarTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ClipOval(
                  child: loadingAvatar
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        )
                      : avatarUrl != null && avatarUrl!.isNotEmpty
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              initials,
                              style: AppTypography.headingLg.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: AppTypography.headingLg.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.headingMd.copyWith(
                    color: AppColors.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.utilityXs.copyWith(
              color: AppColors.mute,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.hairlineSoft),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.hairlineSoft,
                    indent: 56,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.softCloud,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyMd),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSm.copyWith(
                          color: AppColors.mute,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.stone),
          ],
        ),
      ),
    );
  }
}

class _CartSummaryTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chuyển sang tab Giỏ hàng ở thanh dưới nhé'),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.softCloud,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Giỏ hàng hiện tại', style: AppTypography.bodyMd),
            ),
            Text(
              '${cart.itemCount} sản phẩm',
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          final authState = context.read<AuthState>();
          final cartState = context.read<CartState>();
          await authState.logout();
          cartState.clear();
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.sale),
        label: Text(
          'Đăng xuất',
          style: AppTypography.buttonMd.copyWith(color: AppColors.sale),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.softCloud,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({
    required this.initialFullName,
    required this.initialPhone,
    required this.initialAddress,
  });

  final String initialFullName;
  final String initialPhone;
  final String initialAddress;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialFullName);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _addressCtrl = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cập nhật thông tin cá nhân',
                      style: AppTypography.headingMd.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.of(context).pop(
                      _ProfileFormValue(
                        fullName: _nameCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim(),
                        address: _addressCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileFormValue {
  const _ProfileFormValue({
    required this.fullName,
    required this.phone,
    required this.address,
  });

  final String fullName;
  final String phone;
  final String address;
}
