import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialHandle;
  final String initialBio;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialHandle,
    required this.initialBio,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _handleController = TextEditingController(text: widget.initialHandle);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Here you would typically save changes to local storage or backend
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'handle': _handleController.text.trim(),
      'bio': _bioController.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
            elevation: 0.5,
            title: Text(
              'Edit Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _saveProfile,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeNotifier.primaryColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Avatar Change Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                          child: Text(
                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'S',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: themeNotifier.primaryColor,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: themeNotifier.primaryColor,
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Change profile photo picker coming soon!')),
                        );
                      },
                      child: Text(
                        'Change Profile Photo',
                        style: TextStyle(color: themeNotifier.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Input Fields
              _buildTextField(
                label: 'Name',
                controller: _nameController,
                themeNotifier: themeNotifier,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Username / Handle',
                controller: _handleController,
                prefixText: '@',
                themeNotifier: themeNotifier,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Bio',
                controller: _bioController,
                maxLines: 3,
                themeNotifier: themeNotifier,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required AppThemeNotifier themeNotifier,
    String? prefixText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: themeNotifier.isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixStyle: TextStyle(color: themeNotifier.isDarkMode ? Colors.white54 : Colors.black54),
            filled: true,
            fillColor: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}