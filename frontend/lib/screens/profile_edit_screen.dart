import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cropController = TextEditingController();
  final _locationController = TextEditingController();

  String _soilType = 'Loam';
  String _cropStage = 'Vegetative';
  String _language = 'English';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cropController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final profile = await UserService.getProfile(uid);
    if (profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _cropController.text = profile.cropType;
      _locationController.text = profile.location;
      _soilType = profile.soilType.isEmpty ? 'Loam' : profile.soilType;
      _cropStage =
          profile.cropStage.isEmpty ? 'Vegetative' : profile.cropStage;
      _language = profile.language.isEmpty ? 'English' : profile.language;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) return;
    try {
      setState(() => _isSaving = true);
      final profile = UserProfileModel(
        uid: uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        cropType: _cropController.text.trim(),
        location: _locationController.text.trim(),
        language: _language,
        soilType: _soilType,
        cropStage: _cropStage,
      );
      await UserService.createOrUpdateProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile update failed.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration:
                                const InputDecoration(labelText: 'Full Name'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter name'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                                labelText: 'Phone Number'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter phone'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _cropController,
                            decoration: const InputDecoration(
                                labelText: 'Primary Crop'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter crop type'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                                labelText: 'Farm Location'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter location'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _soilType,
                            decoration: const InputDecoration(
                              labelText: 'Primary Soil Type',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Loam', child: Text('Loam')),
                              DropdownMenuItem(
                                  value: 'Clay', child: Text('Clay')),
                              DropdownMenuItem(
                                  value: 'Sandy', child: Text('Sandy')),
                              DropdownMenuItem(
                                  value: 'Silty', child: Text('Silty')),
                              DropdownMenuItem(
                                  value: 'Black', child: Text('Black')),
                              DropdownMenuItem(
                                  value: 'Red', child: Text('Red')),
                            ],
                            onChanged: (value) =>
                                setState(() => _soilType = value ?? 'Loam'),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _cropStage,
                            decoration: const InputDecoration(
                              labelText: 'Crop Stage',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Seedling',
                                  child: Text('Seedling')),
                              DropdownMenuItem(
                                  value: 'Vegetative',
                                  child: Text('Vegetative')),
                              DropdownMenuItem(
                                  value: 'Flowering',
                                  child: Text('Flowering')),
                              DropdownMenuItem(
                                  value: 'Fruiting',
                                  child: Text('Fruiting')),
                              DropdownMenuItem(
                                  value: 'Mature',
                                  child: Text('Mature')),
                            ],
                            onChanged: (value) => setState(
                              () => _cropStage = value ?? 'Vegetative',
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _language,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Language',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'English', child: Text('English')),
                              DropdownMenuItem(
                                  value: 'Hindi', child: Text('Hindi')),
                            ],
                            onChanged: (value) =>
                                setState(() => _language = value ?? 'English'),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
