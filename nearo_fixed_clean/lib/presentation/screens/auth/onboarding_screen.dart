import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/nearo_user.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final AppUser appUser;

  const OnboardingScreen({super.key, required this.appUser});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController(text: '18');
  final _photoController = TextEditingController();
  final _bioController = TextEditingController();
  final _moodController = TextEditingController(text: 'Open to connect');
  final _instagramController = TextEditingController();
  final _telegramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  var _acceptedSafety = false;
  var _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _photoController.dispose();
    _bioController.dispose();
    _moodController.dispose();
    _instagramController.dispose();
    _telegramController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your Nearo profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Low-pressure, real-world connections.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
                validator: (value) => value == null || value.trim().length < 2 ? 'Nickname is required.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 18) return 'Nearo is 18+ for nightlife safety.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _ProfilePhotoPicker(
                selectedPhoto: _selectedPhoto,
                photoController: _photoController,
                onPickPhoto: _pickPhoto,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _moodController, decoration: const InputDecoration(labelText: 'Mood')),
              const SizedBox(height: 12),
              TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: 'Bio')),
              const SizedBox(height: 20),
              const Text('Optional socials', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(controller: _instagramController, decoration: const InputDecoration(labelText: 'Instagram')),
              const SizedBox(height: 12),
              TextFormField(controller: _telegramController, decoration: const InputDecoration(labelText: 'Telegram')),
              const SizedBox(height: 12),
              TextFormField(controller: _whatsappController, decoration: const InputDecoration(labelText: 'WhatsApp')),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _acceptedSafety,
                onChanged: (value) => setState(() => _acceptedSafety = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('I agree to respectful conduct, privacy-first contact reveal, and real-world safety rules.'),
              ),
              if (!_acceptedSafety) const Text('Safety agreement is required.', style: TextStyle(color: NearoTheme.mutedText)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enter Nearo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_acceptedSafety || !_formKey.currentState!.validate()) return;
    if (_selectedPhoto == null && !_photoController.text.trim().startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      var photoUrl = _photoController.text.trim();
      if (_selectedPhoto != null) {
        photoUrl = await ref.read(profilePhotoRepositoryProvider).uploadProfilePhoto(
              uid: widget.appUser.uid,
              image: _selectedPhoto!,
            );
      }
      await ref.read(authControllerProvider.notifier).completeOnboarding(
            appUser: widget.appUser,
            nickname: _nicknameController.text,
            age: int.parse(_ageController.text),
            photoUrl: photoUrl,
            bio: _bioController.text,
            mood: _moodController.text,
            socials: UserSocials(
              instagram: _instagramController.text,
              telegram: _telegramController.text,
              whatsapp: _whatsappController.text,
            ),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save profile. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (photo == null) return;
    setState(() {
      _selectedPhoto = photo;
      _photoController.clear();
    });
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  final XFile? selectedPhoto;
  final TextEditingController photoController;
  final VoidCallback onPickPhoto;

  const _ProfilePhotoPicker({
    required this.selectedPhoto,
    required this.photoController,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = photoController.text.trim().startsWith('http');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile photo', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: NearoTheme.surface,
                backgroundImage: hasUrl ? NetworkImage(photoController.text.trim()) : null,
                child: selectedPhoto == null && !hasUrl ? const Icon(Icons.person_add_alt_1) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPhoto?.name ?? (hasUrl ? 'Photo URL added' : 'Add a clear profile photo'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: onPickPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose photo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: photoController,
            decoration: const InputDecoration(labelText: 'Or paste photo URL'),
          ),
        ],
      ),
    );
  }
}
