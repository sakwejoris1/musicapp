import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  int _price = AppConstants.songPriceMin;
  String _genre = AppConstants.genres.first;
  File? _audioFile;
  File? _videoFile;
  File? _coverFile;
  bool _uploading = false;
  String _uploadType = 'song'; // 'song' | 'album'

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _uploadType = _tab.index == 0 ? 'song' : 'album'));
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _audioFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickCover() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result != null) setState(() => _coverFile = File(result.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFile == null) {
      _showError('Please select an audio file');
      return;
    }
    setState(() => _uploading = true);
    try {
      final formData = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        'genre': _genre,
        'price': _price,
        'audio': await MultipartFile.fromFile(_audioFile!.path),
        if (_coverFile != null)
          'cover': await MultipartFile.fromFile(_coverFile!.path),
        if (_videoFile != null)
          'video': await MultipartFile.fromFile(_videoFile!.path),
      });
      await ApiService().uploadSong(formData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload successful!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError(e.toString());
    }
    setState(() => _uploading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: Text(l.uploadSong),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [Tab(text: l.songs), Tab(text: l.albums)],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover picker
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3), width: 1.5,
                        style: BorderStyle.solid),
                    image: _coverFile != null
                        ? DecorationImage(
                            image: FileImage(_coverFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _coverFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.primary, size: 40),
                            const SizedBox(height: 8),
                            Text(l.selectCover,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: _uploadType == 'song' ? l.songTitle : l.albumTitle,
                  prefixIcon: const Icon(Icons.title, color: AppColors.textSecondary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Genre dropdown
              DropdownButtonFormField<String>(
                initialValue: _genre,
                dropdownColor: AppColors.darkCard,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l.genre,
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textSecondary),
                ),
                items: AppConstants.genres
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _genre = v ?? _genre),
              ),
              const SizedBox(height: 16),

              // Price slider
              Text(
                '${_uploadType == 'song' ? l.songPrice : l.albumPrice}: $_price FCFA',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Slider(
                value: _price.toDouble(),
                min: _uploadType == 'song'
                    ? AppConstants.songPriceMin.toDouble()
                    : AppConstants.albumPriceMin.toDouble(),
                max: _uploadType == 'song'
                    ? AppConstants.songPriceMax.toDouble()
                    : AppConstants.albumPriceMax.toDouble(),
                divisions: _uploadType == 'song' ? 5 : 25,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.darkSurface,
                label: '$_price FCFA',
                onChanged: (v) => setState(() => _price = v.round()),
              ),
              const SizedBox(height: 16),

              // Audio file
              _FilePicker(
                label: l.selectAudio,
                icon: Icons.audio_file_outlined,
                file: _audioFile,
                onPick: _pickAudio,
              ),
              const SizedBox(height: 12),

              // Video file (optional)
              _FilePicker(
                label: '${l.selectVideo} (optional)',
                icon: Icons.video_file_outlined,
                file: _videoFile,
                onPick: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.video);
                  if (result != null && result.files.single.path != null) {
                    setState(() => _videoFile = File(result.files.single.path!));
                  }
                },
              ),
              const SizedBox(height: 32),

              // Content policy notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.invalidContent,
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _submit,
                  child: _uploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(l.uploading),
                          ],
                        )
                      : Text(l.uploadSuccess.replaceAll('!', '').isNotEmpty
                          ? _uploadType == 'song' ? l.uploadSong : l.uploadAlbum
                          : 'Upload'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.label,
    required this.icon,
    required this.file,
    required this.onPick,
  });
  final String label;
  final IconData icon;
  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.darkSurface,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: file != null ? AppColors.success : AppColors.textSecondary,
                size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? file!.path.split('/').last : label,
                style: TextStyle(
                  color: file != null ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              file != null ? Icons.check_circle_outline : Icons.upload_outlined,
              color: file != null ? AppColors.success : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
