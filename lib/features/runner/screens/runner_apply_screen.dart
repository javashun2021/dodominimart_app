import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/runner_application_model.dart';
import '../providers/runner_provider.dart';
import '../data/runner_repository.dart';

class RunnerApplyScreen extends ConsumerStatefulWidget {
  final RunnerApplicationModel? existing;
  const RunnerApplyScreen({super.key, this.existing});

  @override
  ConsumerState<RunnerApplyScreen> createState() => _RunnerApplyScreenState();
}

class _RunnerApplyScreenState extends ConsumerState<RunnerApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _phoneCtrl;

  XFile? _pickedFile;
  Uint8List? _imageBytes;
  String? _uploadedPath; // 上传成功后后端返回的相对路径
  bool _uploading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.existing?.realName ?? '');
    _idCtrl    = TextEditingController(text: widget.existing?.idNumber ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    // 重新申请时保留原来的图片路径（用户可选择重新上传）
    _uploadedPath = widget.existing?.idPhotoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _pickedFile = file;
      _imageBytes = bytes;
      _uploadedPath = null; // 重置，等新上传完成
    });

    await _uploadImage(file, bytes);
  }

  Future<void> _uploadImage(XFile file, Uint8List bytes) async {
    setState(() => _uploading = true);
    try {
      final client = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: DioMediaType.parse(
              file.mimeType ?? 'image/jpeg'),
        ),
      });
      final response =
          await client.postMultipart(ApiEndpoints.uploadImage, formData: formData);
      final json = response.data as Map<String, dynamic>;
      if (json['code'] != 0) throw Exception(json['msg']);
      final data = json['data'];
      // 后端可能返回 { path: "...", url: "..." } 或直接返回字符串路径
      final path = data is Map
          ? (data['path'] ?? data['url'])?.toString()
          : data?.toString();
      if (path == null) throw Exception('Upload failed: no path returned');
      if (!mounted) return;
      setState(() => _uploadedPath = path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickedFile = null;
        _imageBytes = null;
        _uploadedPath = widget.existing?.idPhotoUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your ID photo'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(runnerRepositoryProvider).submitApplication(
            realName: _nameCtrl.text.trim(),
            idNumber: _idCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            idPhotoUrl: _uploadedPath,
          );
      if (!mounted) return;
      ref.invalidate(runnerApplicationProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted! Awaiting review.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReapply = widget.existing?.isRejected == true;
    final hasExistingPhoto = widget.existing?.resolvedIdPhoto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isReapply ? 'Reapply as Runner' : 'Apply as Runner',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拒绝原因提示
              if (isReapply && widget.existing?.rejectReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Previous rejection: ${widget.existing!.rejectReason}',
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
              ],

              const Text('Personal Information',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.onBackground)),
              const Gap(4),
              const Text(
                'Your information will be verified by our team before approval.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const Gap(20),

              _field(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Juan dela Cruz',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              _field(
                controller: _idCtrl,
                label: 'ID Number',
                hint: '1234-5678',
                icon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              _field(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: '09171234567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const Gap(24),

              // ID 照片区块
              const Text('ID Photo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.onBackground)),
              const Gap(4),
              const Text(
                'Upload a clear photo of your government-issued ID (front side).',
                style: TextStyle(
                    fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const Gap(12),

              GestureDetector(
                onTap: _uploading || _submitting ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _uploadedPath != null
                          ? AppColors.success.withValues(alpha: 0.6)
                          : AppColors.border,
                      width: _uploadedPath != null ? 1.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _buildPhotoArea(hasExistingPhoto),
                  ),
                ),
              ),

              if (_uploadedPath != null && !_uploading) ...[
                const Gap(8),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _pickedFile != null ? 'Photo uploaded' : 'Using existing photo',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _uploading || _submitting ? null : _pickImage,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Change'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],

              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_submitting || _uploading) ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Application'),
                ),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoArea(bool hasExistingPhoto) {
    // 正在上传
    if (_uploading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            Gap(12),
            Text('Uploading...', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    // 新选的图片预览
    if (_imageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_imageBytes!, fit: BoxFit.cover),
          if (_uploadedPath != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 16),
              ),
            ),
        ],
      );
    }

    // 已有照片（重新申请时）
    if (hasExistingPhoto && _uploadedPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.existing!.resolvedIdPhoto!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _emptyPhotoPlaceholder(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Tap to change photo',
                      style: TextStyle(
                          color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 空状态
    return _emptyPhotoPlaceholder();
  }

  Widget _emptyPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined,
            size: 40,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
        const Gap(10),
        const Text('Tap to upload ID photo',
            style: TextStyle(
                fontSize: 13, color: AppColors.onSurfaceVariant)),
        const Gap(4),
        const Text('JPG / PNG, max 5MB',
            style:
                TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
