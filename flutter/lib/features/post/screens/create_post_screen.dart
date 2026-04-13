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
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _onPublish() async {
    if (_isLoading) return;

    final caption = _captionController.text.trim();

    setState(() => _isLoading = true);

    final success = await ref.read(postControllerProvider.notifier).createPost(
      mediaPath: widget.mediaPath,
      type: widget.mediaType,
      caption: caption,
      isEAMarked: _isEAMarked,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beitrag veröffentlicht!'),
          backgroundColor: Colors.green,
        ),
      );
      // Back to feed (pop 3 screens: CreatePost -> Photo/VideoReview -> Camera)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Veröffentlichen'),
          backgroundColor: Colors.red,
        ),
      );
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
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
              onPressed: _isLoading ? null : _onPublish,
              child: _isLoading
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
      body: SingleChildScrollView(
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

            // ─── EA-TOGGLE: PROMINENT ───
            // Gelber Hintergrund, 2px Border, Icon, Switch
            GestureDetector(
              onTap: () => setState(() => _isEAMarked = !_isEAMarked),
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
                          onChanged: (v) => setState(() => _isEAMarked = v),
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

            const SizedBox(height: 16),

            // Info-Text
            if (!_isEAMarked)
              const Text(
                'Echte Fotos und Videos müssen nicht markiert werden.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
