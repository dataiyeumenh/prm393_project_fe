import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/api/admin_dto.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../admin_shell.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<AdminUserDTO> _users = [];
  bool _loading = true;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  String _search = '';

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 100 &&
        !_loading &&
        _hasMore) {
      _fetch();
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (!reset && (!_hasMore || _loading)) return;
    setState(() {
      _loading = true;
      if (reset) _error = null;
    });

    final page = reset ? 0 : _page;
    final result = await AdminService.getUsers(
      page: page,
      size: _pageSize,
      search: _search.isEmpty ? null : _search,
    );

    if (!mounted) return;
    setState(() {
      if (result.isSuccess && result.data != null) {
        final items = result.data!.content;
        _users = reset ? items : [..._users, ...items];
        _hasMore = !result.data!.last;
        _page = page + 1;
        _error = null;
      } else {
        _error = result.error;
        if (reset) _users = [];
      }
      _loading = false;
    });
  }

  void _onSearchSubmit(String val) {
    _search = val.trim();
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AdminAppBar(subtitle: 'Trang quản trị', title: 'Khách hàng'),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: _onSearchSubmit,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Tìm khách hàng…',
                prefixIcon: const Icon(Icons.search, color: AppColors.mute),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.mute),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search = '';
                          _fetch(reset: true);
                        },
                      )
                    : null,
              ),
            ),
          ),
          const Divider(height: 1),
          // User count
          if (!_loading && _users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Hiển thị ${_users.length} người${_hasMore ? '+' : ''}',
                    style: AppTypography.captionSm.copyWith(
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _users.isEmpty
                ? _UsersError(
                    message: _error!,
                    onRetry: () => _fetch(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetch(reset: true),
                    color: AppColors.accentPinkDeep,
                    child: _users.isEmpty
                        ? const _EmptyUsers()
                        : ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _users.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              if (i == _users.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              return _UserCard(user: _users[i]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final AdminUserDTO user;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _avatarColor(String id) {
    final colors = [
      AppColors.dogAccentSolid,
      AppColors.catAccentSolid,
      AppColors.birdAccentSolid,
      AppColors.fishAccentSolid,
      AppColors.treatsAccentSolid,
      AppColors.toysAccentSolid,
    ];
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final avatarColor = _avatarColor(user.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(user.fullName),
              style: AppTypography.captionMd.copyWith(
                color: avatarColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: AppTypography.captionMd.copyWith(
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: user.isAdmin
                            ? AppColors.accentPinkDeep.withValues(alpha: 0.12)
                            : AppColors.info.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        user.isAdmin ? 'Quản trị' : 'Khách',
                        style: AppTypography.utilityXs.copyWith(
                          color: user.isAdmin
                              ? AppColors.accentPinkDeep
                              : AppColors.info,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: AppTypography.utilityXs.copyWith(
                    color: AppColors.mute,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.createdAt != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (user.phone != null) ...[
                        const Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: AppColors.stone,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          user.phone!,
                          style: AppTypography.utilityXs.copyWith(
                            color: AppColors.stone,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.stone,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Tham gia ${dateFmt.format(user.createdAt!)}',
                        style: AppTypography.utilityXs.copyWith(
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Active indicator
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: user.active ? AppColors.success : AppColors.stone,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Column(
          children: [
            const Icon(
              Icons.group_outlined,
              size: 64,
              color: AppColors.hairline,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa tìm thấy khách hàng',
              style: AppTypography.headingMd.copyWith(color: AppColors.ash),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  bool get _isEndpointMissing =>
      message.contains('404') ||
      message.contains('not found') ||
      message.contains('not available');

  bool get _isAccessDenied =>
      message.contains('403') ||
      message.contains('denied') ||
      message.contains('401') ||
      message.contains('Unauthorized');

  @override
  Widget build(BuildContext context) {
    final icon = _isAccessDenied
        ? Icons.lock_outline_rounded
        : _isEndpointMissing
        ? Icons.cloud_off_rounded
        : Icons.error_outline_rounded;

    final hint = _isAccessDenied
        ? 'Tài khoản của bạn có thể chưa có quyền truy cập endpoint này.'
        : _isEndpointMissing
        ? 'Endpoint khách hàng chưa sẵn trên backend.'
        : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.sale),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: AppTypography.captionSm.copyWith(color: AppColors.stone),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
