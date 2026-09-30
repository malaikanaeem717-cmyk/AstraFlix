// lib/screens/profile/edit_profile_screen.dart
// Edit display name + profile photo. Uses XFile bytes (not dart:io File) so
// this compiles and works on Flutter Web too, not just mobile — uploads to
// Firebase Storage, then saves the URL to Firestore.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/floating_icons_background.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController = TextEditingController(text: widget.user.displayName);

  Uint8List? _pickedBytes;
  String? _photoUrlOverride;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _pickedBytes = bytes;
        _error = null;
      });
      await _uploadPhoto(bytes);
    } catch (_) {
      setState(() => _error = 'Couldn\'t open the photo picker. Please try again.');
    }
  }

  Future<void> _uploadPhoto(Uint8List bytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      await ref
          .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 25));
      final url = await ref.getDownloadURL().timeout(const Duration(seconds: 15));
      setState(() => _photoUrlOverride = url);
    } on FirebaseException catch (e) {
      setState(() => _error = e.code == 'unauthorized'
          ? 'Upload blocked — Firebase Storage rules aren\'t set up for this project yet.'
          : 'Couldn\'t upload your photo (${e.code}). Please try again.');
    } catch (_) {
      setState(() => _error =
      'Upload timed out. Check your connection, or that Firebase Storage is enabled for this project.');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name can\'t be empty.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(firestoreServiceProvider).updateUserProfile(
        uid,
        displayName: name,
        photoUrl: _photoUrlOverride,
      );
      final authUser = FirebaseAuth.instance.currentUser;
      await authUser?.updateDisplayName(name);
      if (_photoUrlOverride != null) {
        await authUser?.updatePhotoURL(_photoUrlOverride);
      }

      if (mounted) context.pop();
    } catch (_) {
      setState(() => _error = 'Couldn\'t save your changes. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPhotoUrl = _photoUrlOverride ?? widget.user.photoUrl;

    return FloatingIconsBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                    onPressed: () => context.pop(),
                  ),
                  const Text('Edit Profile',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAvatarPicker(displayPhotoUrl),
                        const SizedBox(height: 24),

                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Poppins')),
                                ),
                              ],
                            ),
                          ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Display name', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins')),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Your name',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(widget.user.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Poppins')),
                        ),
                        const SizedBox(height: 26),
                        GradientButton(label: 'Save Changes', isLoading: _isSaving, onTap: _isUploadingPhoto ? null : _save),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(String? photoUrl) {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _pickPhoto,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
            ),
            child: _isUploadingPhoto
                ? const Center(child: AstraLoadingIndicator())
                : (_pickedBytes != null
                ? ClipOval(child: Image.memory(_pickedBytes!, fit: BoxFit.cover))
                : (photoUrl != null
                ? ClipOval(child: CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _initialsAvatar()))
                : _initialsAvatar())),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(widget.user.initials,
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
    );
  }
}