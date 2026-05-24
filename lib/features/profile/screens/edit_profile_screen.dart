import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _phoneCtrl;

  Uint8List? _avatarBytes;
  String? _uploadedAvatarUrl;
  bool _uploadingAvatar = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _uploadingAvatar = true;
      _uploadedAvatarUrl = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'avatar.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      final res = await client.postMultipart(
        ApiEndpoints.uploadImage,
        formData: formData,
      );
      final raw = res.data;
      final json = raw is Map
          ? Map<String, dynamic>.from(raw as Map)
          : jsonDecode(raw.toString()) as Map<String, dynamic>;
      if (json['code'] != 0) throw Exception(json['msg']);
      // 上传返回顶层 path（相对路径）或 url（完整路径）
      final path = json['path'] as String? ?? json['url'] as String?;
      if (mounted) setState(() => _uploadedAvatarUrl = path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _avatarBytes = null;
          _uploadedAvatarUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('头像上传失败: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadingAvatar) return;
    setState(() => _isLoading = true);
    try {
      // 优先用本次上传的新路径；没有新上传则沿用已有的相对路径头像
      final existingAvatar = ref.read(authProvider).user?.avatar;
      final avatarToSend = _uploadedAvatarUrl ??
          (existingAvatar != null && existingAvatar.startsWith('/')
              ? existingAvatar
              : null);
      await ref.read(authProvider.notifier).updateProfile(
            nickname: _nicknameCtrl.text.trim(),
            phoneNumber: _phoneCtrl.text.trim(),
            avatarUrl: avatarToSend,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final existingAvatar = user?.avatar;
    final username = user?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: (_isLoading || _uploadingAvatar) ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── 头像 ──────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAvatar,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : (existingAvatar != null && existingAvatar.isNotEmpty
                              ? NetworkImage(existingAvatar) as ImageProvider
                              : null),
                      child: (_avatarBytes == null &&
                              (existingAvatar == null || existingAvatar.isEmpty))
                          ? Text(
                              (user?.nickname.isNotEmpty == true
                                      ? user!.nickname[0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 36,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  // 相机图标 overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAvatar,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _uploadingAvatar
                              ? AppColors.onSurfaceVariant
                              : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.background, width: 2),
                        ),
                        child: _uploadingAvatar
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            // ── @username 只读标签 ─────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const Gap(28),
            // ── 显示名称 ──────────────────────────────────────────
            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const Gap(16),
            // ── 手机号 ────────────────────────────────────────────
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '09XX XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Phone number is required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
