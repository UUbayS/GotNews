import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart' show themeNotifier;
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/preferences_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _usernameController.text = user.username ?? '';
      _emailController.text = user.email;
      _dobController.text = user.dateOfBirth ?? '';
      _genderController.text = user.gender ?? '';
      _addressController.text = user.address ?? '';
      _avatarUrl = user.avatarUrl;
    }
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    final success = await context.read<AuthService>().updateProfile(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      gender: _genderController.text.trim(),
      address: _addressController.text.trim(),
      avatarUrl: _avatarUrl,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } else {
      final error = context.read<AuthService>().lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  _isUploadingAvatar
                      ? CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : CircleAvatar(
                          radius: 40,
                          backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? NetworkImage(_avatarUrl!)
                              : const NetworkImage('https://via.placeholder.com/150'),
                          backgroundColor: Colors.grey.shade200,
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingAvatar ? null : _showAvatarUrlDialog,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildFieldLabel('Name:'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Username:'),
            TextFormField(
              controller: _usernameController,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Email:'),
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration(),
              readOnly: true, // Typically email changing requires re-verification
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Date of Birth:'),
                      TextFormField(
                        controller: _dobController,
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Gender:'),
                      TextFormField(
                        controller: _genderController,
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Address:'),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 32),

            // Appearance Section
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appearance',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildThemeOption(
                        context,
                        icon: Icons.phone_android,
                        label: 'System',
                        mode: ThemeMode.system,
                        currentMode: currentMode,
                      ),
                      _buildThemeOption(
                        context,
                        icon: Icons.light_mode,
                        label: 'Light',
                        mode: ThemeMode.light,
                        currentMode: currentMode,
                      ),
                      _buildThemeOption(
                        context,
                        icon: Icons.dark_mode,
                        label: 'Dark',
                        mode: ThemeMode.dark,
                        currentMode: currentMode,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E65F3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF2E65F3) : Colors.grey),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF2E65F3))
          : null,
      onTap: () async {
        themeNotifier.value = mode;
        final prefs = await PreferencesService.create();
        await prefs.setThemeMode(mode);
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showAvatarUrlDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2E65F3)),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2E65F3)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _isUploadingAvatar = true);

      try {
        final response = await ApiClient.postFile(
          '/auth/avatar',
          pickedFile.path,
          'file',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            _avatarUrl = data['avatarUrl'];
            _isUploadingAvatar = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Foto profil berhasil diupdate'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() => _isUploadingAvatar = false);
          if (mounted) {
            final error = jsonDecode(response.body)['message'] ?? 'Upload gagal';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isUploadingAvatar = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload gagal: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}