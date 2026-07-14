import 'package:flutter/material.dart';

import '../../models/api/address_dto.dart';
import '../../services/address_service.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet to create a new shipping address.
///
/// Latitude / longitude are required by the API but the app has no map
/// picker yet, so [AddressRequest] supplies a sensible default (HCMC).
class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({super.key});

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  bool _isDefault = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _street.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await AddressService.createAddress(
      AddressRequest(
        receiverName: _name.text.trim(),
        phone: _phone.text.trim(),
        streetAddress: _street.text.trim(),
        isDefault: _isDefault,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isSuccess) {
      Navigator.of(context).pop(result.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(result.error ?? 'Failed to add address',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimary)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('New address', style: AppTypography.headingMd),
              const SizedBox(height: 16),
              _Field(
                controller: _name,
                label: 'Receiver name',
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _phone,
                label: 'Phone number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 8) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _street,
                label: 'Street address',
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                activeThumbColor: AppColors.accentPinkDeep,
                title: Text('Set as default address',
                    style: AppTypography.bodyMd),
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    onTap: _saving ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.onPrimary),
                                ),
                              )
                            : Text('Save address',
                                style: AppTypography.buttonMd
                                    .copyWith(color: AppColors.onPrimary)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      style: AppTypography.bodyMd,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMd.copyWith(color: AppColors.mute),
        filled: true,
        fillColor: AppColors.softCloud,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accentPink, width: 2),
        ),
      ),
    );
  }
}
