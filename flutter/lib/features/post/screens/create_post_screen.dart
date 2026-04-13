import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/post_controller.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String mediaPath;
  final String mediaType; // 'photo' oder 'video'

  const CreatePostScreen({
    super.key,
    required this.mediaPath,
    required this.mediaType,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  bool _isEAMarked = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _statusLabel = '';
  String? _errorMessage;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
      _statusLabel = '';
      _errorMessage = null;
    });
  }

  Future<void> _onPublish() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusLabel = 'Bereite vor...';
      _errorMessage = null;
    });

    final success =
        await ref.read(postControllerProvider.notifier).createPost(
              mediaPath: widget.mediaPath,
              type: widget.mediaType,
              caption: _captionController.text.trim(),
              isEAMarked: _isEAMarked,
            );

    if (!mounted) return;

    if (success) {
      setState(() {
        _uploadProgress = 1.0;
        _statusLabel = 'Fertig!';
      });
      // Small delay so user sees "Fertig!"
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beitrag veröffentlicht!'),
          backgroundColor: Colors.green,
        ),
      );
      // Pop back to feed (3 screens: CreatePost → Photo/VideoReview → Camera)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final err = ref.read(postControllerProvider).error;
      setState(() {
        _isUploading = false;
        _errorMessage = err?.toString() ?? 'Unbekannter Fehler';
        _statusLabel = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isUploading
              ? null
              : () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
        ),
        title: const Text(
          'Beitrag erstellen',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isUploading ? null : _onPublish,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Veröffentlichen',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Main scrollable content ───────────────────────────────────────
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medien-Vorschau
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.mediaType == 'photo'
                          ? (kIsWeb && widget.mediaPath.startsWith('blob:')
                              ? Image.network(
                                  widget.mediaPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, _) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                    size: 64,
                                  ),
                                )
                              : Image.file(
                                  File(widget.mediaPath),
                                  fit: BoxFit.cover,
                                ))
                          : Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      color: Colors.white54,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Video',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Caption
                  TextField(
                    controller: _captionController,
                    enabled: !_isUploading,
                    maxLines: 4,
                    maxLength: 500,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Was gibt\'s Neues?',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      counterStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── EA-TOGGLE ─────────────────────────────────────────────
                  GestureDetector(
                    onTap: _isUploading
                        ? null
                        : () => setState(() => _isEAMarked = !_isEAMarked),
                    child: Opacity(
                      opacity: _isUploading ? 0.5 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          border: Border.all(
                            color: const Color(0xFFFFB800),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.psychology,
                                  color: Color(0xFF856404),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'KI-Inhalt markieren',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF856404),
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _isEAMarked,
                                  activeTrackColor: const Color(0xFFFFB800),
                                  onChanged: _isUploading
                                      ? null
                                      : (v) => setState(() => _isEAMarked = v),
                                ),
                              ],
                            ),
                            if (_isEAMarked) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Ich bestätige, dass dieser Inhalt mit Künstlicher Intelligenz erstellt wurde.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF856404),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'KI-generierte Inhalte müssen markiert werden.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF856404),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info-Text
                  if (!_isEAMarked && !_isUploading)
                    const Text(
                      'Echte Fotos und Videos müssen nicht markiert werden.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),

                  const SizedBox(height: 100), // space for progress overlay
                ],
              ),
            ),
          ),

          // ── Upload progress overlay ────────────────────────────────────────
          if (_isUploading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status label
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusLabel.isEmpty
                                ? 'Verarbeitet...'
                                : _statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6C63FF),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.mediaType == 'video'
                          ? 'Video wird komprimiert — das kann einen Moment dauern'
                          : 'Foto wird komprimiert und hochgeladen',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Error overlay ──────────────────────────────────────────────────
          if (_errorMessage != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A0A0A),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: Colors.red, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Fehler beim Veröffentlichen',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _reset,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text('Abbrechen'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _reset();
                              _onPublish();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Erneut versuchen'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
