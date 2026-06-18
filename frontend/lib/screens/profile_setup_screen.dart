import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';
import '../services/user_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.uid});

  final String uid;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cropController = TextEditingController();
  final _locationController = TextEditingController();
  String _soilType = 'Loam';
  String _cropStage = 'Vegetative';
  String _language = 'English';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cropController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isSaving = true);
      final profile = UserProfileModel(
        uid: widget.uid,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved. Redirecting...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter phone'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cropController,
                      decoration:
                          const InputDecoration(labelText: 'Primary Crop'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter crop type'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _locationController,
                      decoration:
                          const InputDecoration(labelText: 'Farm Location'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter location'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _soilType,
                      decoration:
                          const InputDecoration(labelText: 'Primary Soil Type'),
                      items: const [
                        DropdownMenuItem(value: 'Loam', child: Text('Loam')),
                        DropdownMenuItem(value: 'Clay', child: Text('Clay')),
                        DropdownMenuItem(value: 'Sandy', child: Text('Sandy')),
                        DropdownMenuItem(value: 'Silty', child: Text('Silty')),
                        DropdownMenuItem(value: 'Black', child: Text('Black')),
                        DropdownMenuItem(value: 'Red', child: Text('Red')),
                      ],
                      onChanged: (value) =>
                          setState(() => _soilType = value ?? 'Loam'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _cropStage,
                      decoration:
                          const InputDecoration(labelText: 'Crop Stage'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Seedling',
                          child: Text('Seedling'),
                        ),
                        DropdownMenuItem(
                          value: 'Vegetative',
                          child: Text('Vegetative'),
                        ),
                        DropdownMenuItem(
                          value: 'Flowering',
                          child: Text('Flowering'),
                        ),
                        DropdownMenuItem(
                          value: 'Fruiting',
                          child: Text('Fruiting'),
                        ),
                        DropdownMenuItem(
                          value: 'Mature',
                          child: Text('Mature'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _cropStage = value ?? 'Vegetative'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      decoration: const InputDecoration(
                          labelText: 'Preferred Language'),
                      items: const [
                        DropdownMenuItem(
                            value: 'English', child: Text('English')),
                        DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Profile'),
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
