import 'package:flutter/material.dart';

import '../../../models/api/brand_dto.dart';
import '../../../models/api/category_dto.dart';
import '../../../services/brand_service.dart';
import '../../../services/category_service.dart';
import '../../../theme/app_theme.dart';
import '../admin_shell.dart';

enum _CatalogTab { categories, brands }

enum _CatalogDetailAction { edit, delete }

class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  _CatalogTab _currentTab = _CatalogTab.categories;

  List<CategoryDTO> _categories = [];
  List<BrandDTO> _brands = [];

  bool _loading = true;
  bool _submitting = false;
  String? _categoryError;
  String? _brandError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  bool get _isCategoryTab => _currentTab == _CatalogTab.categories;

  List<dynamic> get _currentItems => _isCategoryTab ? _categories : _brands;

  String? get _currentError => _isCategoryTab ? _categoryError : _brandError;

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
    });

    final results = await Future.wait([
      CategoryService.getAllCategories(),
      BrandService.getAllBrands(),
    ]);

    final catResult = results[0] as dynamic;
    final brandResult = results[1] as dynamic;

    if (!mounted) return;
    setState(() {
      _categories = catResult.isSuccess && catResult.data != null
          ? (catResult.data as List<CategoryDTO>)
          : <CategoryDTO>[];
      _brands = brandResult.isSuccess && brandResult.data != null
          ? (brandResult.data as List<BrandDTO>)
          : <BrandDTO>[];

      _categoryError = catResult.isSuccess ? null : catResult.error;
      _brandError = brandResult.isSuccess ? null : brandResult.error;
      _loading = false;
    });
  }

  Future<void> _refreshCurrent() async {
    if (_isCategoryTab) {
      final result = await CategoryService.getAllCategories();
      if (!mounted) return;
      setState(() {
        if (result.isSuccess && result.data != null) {
          _categories = result.data!;
          _categoryError = null;
        } else {
          _categoryError = result.error;
        }
      });
      return;
    }

    final result = await BrandService.getAllBrands();
    if (!mounted) return;
    setState(() {
      if (result.isSuccess && result.data != null) {
        _brands = result.data!;
        _brandError = null;
      } else {
        _brandError = result.error;
      }
    });
  }

  Future<void> _openCreate() async {
    if (_isCategoryTab) {
      await _openCategoryEditor();
      return;
    }
    await _openBrandEditor();
  }

  Future<void> _openDetail(dynamic item) async {
    final isCategory = item is CategoryDTO;
    final action = await Navigator.of(context).push<_CatalogDetailAction>(
      MaterialPageRoute(
        builder: (_) => _CatalogDetailScreen(
          isCategory: isCategory,
          name: isCategory ? item.name : (item as BrandDTO).name,
          description: isCategory
              ? (item as CategoryDTO).description
              : (item as BrandDTO).description,
          url: isCategory
              ? (item as CategoryDTO).imageUrl
              : (item as BrandDTO).logoUrl,
        ),
      ),
    );

    if (action == null || !mounted) return;
    if (action == _CatalogDetailAction.edit) {
      if (isCategory) {
        await _openCategoryEditor(initial: item as CategoryDTO);
      } else {
        await _openBrandEditor(initial: item as BrandDTO);
      }
      return;
    }

    await _confirmDelete(item);
  }

  Future<void> _openCategoryEditor({CategoryDTO? initial}) async {
    final value = await showModalBottomSheet<_EntityFormValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntityFormSheet(
        title: initial == null ? 'Tạo danh mục' : 'Cập nhật danh mục',
        submitLabel: initial == null ? 'Tạo' : 'Lưu',
        nameLabel: 'Tên danh mục',
        urlLabel: 'Ảnh URL',
        initialName: initial?.name,
        initialDescription: initial?.description,
        initialUrl: initial?.imageUrl,
      ),
    );
    if (value == null) return;

    setState(() => _submitting = true);
    final result = initial == null
        ? await CategoryService.createCategory(
            name: value.name,
            description: value.description,
            imageUrl: value.url,
          )
        : await CategoryService.updateCategory(
            initial.id,
            name: value.name,
            description: value.description,
            imageUrl: value.url,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      _showSnack('Lưu danh mục thành công', success: true);
      await _refreshCurrent();
    } else {
      _showSnack(result.error ?? 'Lưu danh mục thất bại');
    }
  }

  Future<void> _openBrandEditor({BrandDTO? initial}) async {
    final value = await showModalBottomSheet<_EntityFormValue>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntityFormSheet(
        title: initial == null ? 'Tạo thương hiệu' : 'Cập nhật thương hiệu',
        submitLabel: initial == null ? 'Tạo' : 'Lưu',
        nameLabel: 'Tên thương hiệu',
        urlLabel: 'Logo URL',
        initialName: initial?.name,
        initialDescription: initial?.description,
        initialUrl: initial?.logoUrl,
      ),
    );
    if (value == null) return;

    setState(() => _submitting = true);
    final result = initial == null
        ? await BrandService.createBrand(
            name: value.name,
            description: value.description,
            logoUrl: value.url,
          )
        : await BrandService.updateBrand(
            initial.id,
            name: value.name,
            description: value.description,
            logoUrl: value.url,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      _showSnack('Lưu thương hiệu thành công', success: true);
      await _refreshCurrent();
    } else {
      _showSnack(result.error ?? 'Lưu thương hiệu thất bại');
    }
  }

  Future<void> _confirmDelete(dynamic item) async {
    final isCategory = item is CategoryDTO;
    final name = isCategory ? item.name : (item as BrandDTO).name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Xóa ${isCategory ? 'danh mục' : 'thương hiệu'}?',
          style: AppTypography.headingMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn chắc chắn muốn xóa "$name"?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: AppTypography.buttonSm.copyWith(color: AppColors.mute),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Xóa',
              style: AppTypography.buttonSm.copyWith(color: AppColors.sale),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);
    late final bool isSuccess;
    String? error;

    if (isCategory) {
      final result = await CategoryService.deleteCategory(
        (item as CategoryDTO).id,
      );
      isSuccess = result.isSuccess;
      error = result.error;
    } else {
      final result = await BrandService.deleteBrand((item as BrandDTO).id);
      isSuccess = result.isSuccess;
      error = result.error;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (isSuccess) {
      _showSnack('Xóa thành công', success: true);
      await _refreshCurrent();
    } else {
      _showSnack(error ?? 'Xóa thất bại');
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.success : AppColors.sale,
        content: Text(
          message,
          style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCategoryTab ? 'Danh mục sản phẩm' : 'Thương hiệu sản phẩm';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AdminAppBar(
        subtitle: 'Trang quản trị',
        title: 'Category & Brand',
        actions: [
          IconButton(
            onPressed: _submitting ? null : _loadAll,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.mute),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-catalog-create',
        onPressed: _submitting ? null : _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _isCategoryTab ? 'Thêm danh mục' : 'Thêm thương hiệu',
          style: AppTypography.buttonSm.copyWith(color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.accentPinkDeep,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SegmentedButton<_CatalogTab>(
              segments: const [
                ButtonSegment<_CatalogTab>(
                  value: _CatalogTab.categories,
                  icon: Icon(Icons.category_rounded),
                  label: Text('Category'),
                ),
                ButtonSegment<_CatalogTab>(
                  value: _CatalogTab.brands,
                  icon: Icon(Icons.local_offer_rounded),
                  label: Text('Brand'),
                ),
              ],
              selected: {_currentTab},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                setState(() => _currentTab = selection.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(
                  AppTypography.captionMd.copyWith(color: AppColors.ink),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                Text(
                  '$title (${_currentItems.length})',
                  style: AppTypography.captionSm.copyWith(
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _currentError != null && _currentItems.isEmpty
                ? _CatalogError(
                    message: _currentError!,
                    onRetry: _refreshCurrent,
                  )
                : RefreshIndicator(
                    color: AppColors.accentPinkDeep,
                    onRefresh: _refreshCurrent,
                    child: _currentItems.isEmpty
                        ? _CatalogEmpty(isCategoryTab: _isCategoryTab)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                            itemBuilder: (_, index) {
                              final item = _currentItems[index];
                              final name = item is CategoryDTO
                                  ? item.name
                                  : (item as BrandDTO).name;
                              return _CatalogNameTile(
                                name: name,
                                onTap: _submitting
                                    ? null
                                    : () => _openDetail(item),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemCount: _currentItems.length,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CatalogNameTile extends StatelessWidget {
  const _CatalogNameTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.hairlineSoft),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.captionMd.copyWith(color: AppColors.ink),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.stone),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogDetailScreen extends StatelessWidget {
  const _CatalogDetailScreen({
    required this.isCategory,
    required this.name,
    this.description,
    this.url,
  });

  final bool isCategory;
  final String name;
  final String? description;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AdminAppBar(
        subtitle: 'Trang quản trị',
        title: isCategory ? 'Chi tiết Category' : 'Chi tiết Brand',
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.hairlineSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tên',
                    style: AppTypography.captionSm.copyWith(
                      color: AppColors.mute,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: AppTypography.headingMd.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  if (description != null &&
                      description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Mô tả',
                      style: AppTypography.captionSm.copyWith(
                        color: AppColors.mute,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                  if (url != null && url!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      isCategory ? 'Ảnh URL' : 'Logo URL',
                      style: AppTypography.captionSm.copyWith(
                        color: AppColors.mute,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url!,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(_CatalogDetailAction.edit),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Chỉnh sửa'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(_CatalogDetailAction.delete),
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Xóa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sale,
                  side: const BorderSide(color: AppColors.sale),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityFormSheet extends StatefulWidget {
  const _EntityFormSheet({
    required this.title,
    required this.submitLabel,
    required this.nameLabel,
    required this.urlLabel,
    this.initialName,
    this.initialDescription,
    this.initialUrl,
  });

  final String title;
  final String submitLabel;
  final String nameLabel;
  final String urlLabel;
  final String? initialName;
  final String? initialDescription;
  final String? initialUrl;

  @override
  State<_EntityFormSheet> createState() => _EntityFormSheetState();
}

class _EntityFormSheetState extends State<_EntityFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _urlCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _urlCtrl = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(12, 0, 12, insets.bottom + 12),
        child: Material(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
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
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(labelText: widget.nameLabel),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'Mô tả (tuỳ chọn)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _urlCtrl,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      labelText: '${widget.urlLabel} (tuỳ chọn)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.of(context).pop(
                          _EntityFormValue(
                            name: _nameCtrl.text.trim(),
                            description: _descCtrl.text.trim(),
                            url: _urlCtrl.text.trim(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(widget.submitLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntityFormValue {
  const _EntityFormValue({
    required this.name,
    required this.description,
    required this.url,
  });

  final String name;
  final String description;
  final String url;
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.sale),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  const _CatalogEmpty({required this.isCategoryTab});

  final bool isCategoryTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.35,
          child: Center(
            child: Text(
              isCategoryTab
                  ? 'Chưa có danh mục nào'
                  : 'Chưa có thương hiệu nào',
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
            ),
          ),
        ),
      ],
    );
  }
}
