import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../app_theme.dart';
import '../main.dart';

class ProfileView extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String phoneNumber;
  final String dob;
  final String gender;
  final String? profileImage;
  final String jobTitle;
  final String address;
  final String bio;

  final Function(String, String, String, String, String, String, String, String?) onSave;
  final VoidCallback onCancel;
  final VoidCallback onSignOut;

  const ProfileView({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.phoneNumber,
    required this.dob,
    required this.gender,
    this.profileImage,
    required this.jobTitle,
    required this.address,
    required this.bio,
    required this.onSave,
    required this.onCancel,
    required this.onSignOut,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _jobTitleController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;

  late String _selectedGender;

  String? _persistedImagePath;
  String? _editingImagePath;

  bool _isEditing = false;

  // App Preferences
  bool _biometricEnabled = false;
  bool _darkModeEnabled = true;
  bool _use24HourFormat = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadPersistedData();
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profileImage != oldWidget.profileImage &&
        (_persistedImagePath == null || _persistedImagePath!.isEmpty)) {
      final path = widget.profileImage;
      if (path != null && path.isNotEmpty) {
        setState(() => _persistedImagePath = path);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _jobTitleController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _dobController = TextEditingController(text: widget.dob);
    _jobTitleController = TextEditingController(text: widget.jobTitle);
    _addressController = TextEditingController(text: widget.address);
    _bioController = TextEditingController(text: widget.bio);
    _selectedGender = widget.gender.isEmpty ? 'Other' : widget.gender;
  }

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    String? resolved;
    final saved = prefs.getString('profile_image_${widget.userEmail}');
    if (saved != null && saved.isNotEmpty) {
      if (saved.startsWith('http') || File(saved).existsSync()) {
        resolved = saved;
      }
    }

    if (resolved == null) {
      final prop = widget.profileImage;
      if (prop != null && prop.isNotEmpty) {
        if (prop.startsWith('http') || File(prop).existsSync()) {
          resolved = prop;
          await prefs.setString('profile_image_${widget.userEmail}', prop);
        }
      }
    }

    setState(() {
      _persistedImagePath = resolved;
      _biometricEnabled = prefs.getBool('biometric_enabled_${widget.userEmail}') ?? false;
      _darkModeEnabled = appThemeNotifier.value == ThemeMode.dark;
      _use24HourFormat = prefs.getBool('24h_format_${widget.userEmail}') ?? false;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool('${key}_${widget.userEmail}', value);
    } else if (value is String) {
      await prefs.setString('${key}_${widget.userEmail}', value);
    }
  }

  void _enterEditMode() {
    _editingImagePath = _persistedImagePath;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    _nameController.text = widget.userName;
    _phoneController.text = widget.phoneNumber;
    _dobController.text = widget.dob;
    _jobTitleController.text = widget.jobTitle;
    _addressController.text = widget.address;
    _bioController.text = widget.bio;
    _selectedGender = widget.gender.isEmpty ? 'Other' : widget.gender;
    _editingImagePath = null;
    widget.onCancel();
    setState(() => _isEditing = false);
  }

  Future<void> _saveEdit() async {
    final prefs = await SharedPreferences.getInstance();

    if (_editingImagePath != null && _editingImagePath!.isNotEmpty) {
      await prefs.setString('profile_image_${widget.userEmail}', _editingImagePath!);
    } else {
      await prefs.remove('profile_image_${widget.userEmail}');
    }

    setState(() {
      _persistedImagePath = _editingImagePath;
      _editingImagePath = null;
    });

    widget.onSave(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _dobController.text.trim(),
      _selectedGender,
      _jobTitleController.text.trim(),
      _addressController.text.trim(),
      _bioController.text.trim(),
      _persistedImagePath,
    );

    if (mounted) setState(() => _isEditing = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null && mounted) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = p.basename(image.path);
        final String savedPath = p.join(appDocDir.path, fileName);
        await File(image.path).copy(savedPath);
        setState(() => _editingImagePath = savedPath);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to pick image. Please check permissions.', isError: true);
    }
  }

  ImageProvider? _resolveImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    final file = File(path);
    if (file.existsSync()) return FileImage(file);
    return null;
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        if (!canCheck || !isSupported) {
          _showSnack('Biometric auth not available on this device.', isError: true);
          return;
        }
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric lock',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (authenticated) {
          setState(() => _biometricEnabled = true);
          await _savePreference('biometric_enabled', true);
        }
      } catch (e) {
        debugPrint('Biometric error: $e');
      }
    } else {
      setState(() => _biometricEnabled = false);
      await _savePreference('biometric_enabled', false);
    }
  }

  void _showSnack(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: isError
          ? Colors.redAccent
          : isSuccess
              ? const Color(0xFF10B981)
              : const Color(0xFFF08A82),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showChangePasswordDialog() {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFFF08A82), size: 20),
            const SizedBox(width: 8),
            Text('Change Password',
                style: TextStyle(
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField('Current Password', controller: currentPwCtrl, obscureText: true),
            const SizedBox(height: 10),
            _buildDialogTextField('New Password', controller: newPwCtrl, obscureText: true),
            const SizedBox(height: 10),
            _buildDialogTextField('Confirm New Password', controller: confirmPwCtrl, obscureText: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.themeTextSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Password updated successfully!', isSuccess: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF08A82),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(String hint,
      {TextEditingController? controller, bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeTextPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.themeTextSecondary.withValues(alpha: 0.6), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 18 : 36,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 18),
            _buildProfileSummaryCard(isMobile),
            const SizedBox(height: 18),
            if (_isEditing) _buildEditForm(isMobile) else _buildViewContent(isMobile),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'User ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF08A82),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your personal account & preferences',
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (!_isEditing)
          InkWell(
            onTap: _enterEditMode,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF08A82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _cancelEdit,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.themeTextPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _saveEdit,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF08A82),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ─── Profile Summary Card ───
  Widget _buildProfileSummaryCard(bool isMobile) {
    final activePath = _isEditing ? _editingImagePath : _persistedImagePath;
    final imageProvider = _resolveImage(activePath);

    final displayName = _isEditing
        ? (_nameController.text.trim().isEmpty ? 'User' : _nameController.text.trim())
        : (widget.userName.isEmpty ? 'User' : widget.userName);

    final displayJob = _isEditing
        ? (_jobTitleController.text.trim().isEmpty ? 'Role not set' : _jobTitleController.text.trim())
        : (widget.jobTitle.isEmpty ? 'Role not set' : widget.jobTitle);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: context.themeTextPrimary.withValues(alpha: 0.06),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.themeTextPrimary,
                        ),
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF08A82),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayJob,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFF08A82),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
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

  // ─── View Content (Standard structured list cards) ───
  Widget _buildViewContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Details Section ──
        _buildSectionTitle('ACCOUNT DETAILS', Icons.person_outline_rounded),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.themeCardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildDetailTile('Full Name', widget.userName.isEmpty ? 'Not set' : widget.userName, Icons.badge_outlined),
              _buildDivider(),
              _buildDetailTile('Email', widget.userEmail, Icons.email_outlined),
              _buildDivider(),
              _buildDetailTile('Phone', widget.phoneNumber.isEmpty ? 'Not set' : widget.phoneNumber, Icons.phone_outlined),
              _buildDivider(),
              _buildDetailTile('Date of Birth', widget.dob.isEmpty ? 'Not set' : widget.dob, Icons.cake_outlined),
              _buildDivider(),
              _buildDetailTile('Gender', widget.gender.isEmpty ? 'Not set' : widget.gender, Icons.wc_outlined),
              _buildDivider(),
              _buildDetailTile('Address', widget.address.isEmpty ? 'Not set' : widget.address, Icons.location_on_outlined),
              _buildDivider(),
              _buildDetailTile('Bio', widget.bio.isEmpty ? 'No bio added yet' : widget.bio, Icons.short_text_rounded),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Preferences Section ──
        _buildSectionTitle('PREFERENCES', Icons.tune_rounded),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.themeCardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildSwitchTile(
                title: 'Dark Theme',
                subtitle: 'Enable dark system appearance',
                icon: Icons.dark_mode_outlined,
                value: _darkModeEnabled,
                onChanged: (val) {
                  setState(() => _darkModeEnabled = val);
                  appThemeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'Biometric Lock',
                subtitle: 'Require FaceID / Fingerprint on launch',
                icon: Icons.fingerprint_rounded,
                value: _biometricEnabled,
                onChanged: _toggleBiometric,
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: '24-Hour Format',
                subtitle: 'Display time in 24h clock',
                icon: Icons.access_time_rounded,
                value: _use24HourFormat,
                onChanged: (val) {
                  setState(() => _use24HourFormat = val);
                  _savePreference('24h_format', val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Security & Actions ──
        _buildSectionTitle('SECURITY & ACTIONS', Icons.security_rounded),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.themeCardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildActionTile(
                title: 'Change Password',
                icon: Icons.lock_outline_rounded,
                onTap: _showChangePasswordDialog,
              ),
              _buildDivider(),
              _buildActionTile(
                title: 'Clear Cache',
                icon: Icons.cleaning_services_outlined,
                onTap: () => _showSnack('Cache cleared successfully!', isSuccess: true),
              ),
              _buildDivider(),
              _buildActionTile(
                title: 'Sign Out',
                icon: Icons.logout_rounded,
                isDestructive: true,
                onTap: widget.onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Edit Form ───
  Widget _buildEditForm(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeTextPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditField('Full Name', _nameController, Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _buildEditField('Job Title / Role', _jobTitleController, Icons.work_outline_rounded),
          const SizedBox(height: 14),
          _buildEditField('Phone Number', _phoneController, Icons.phone_outlined),
          const SizedBox(height: 14),
          _buildEditField('Date of Birth', _dobController, Icons.cake_outlined),
          const SizedBox(height: 14),
          _buildEditField('Address', _addressController, Icons.location_on_outlined),
          const SizedBox(height: 14),
          _buildEditField('Bio', _bioController, Icons.short_text_rounded, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFF08A82)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.themeTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.themeTextSecondary),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.themeTextSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.themeTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.themeTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.themeTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFF08A82),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : context.themeTextPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isDestructive ? Colors.redAccent : context.themeTextSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: context.themeTextSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.themeTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.themeTextPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: context.themeTextSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Divider(
        height: 1,
        thickness: 1,
        color: context.themeTextPrimary.withValues(alpha: 0.04),
        indent: 14,
        endIndent: 14,
      );
}
