import 'package:flutter/material.dart';

import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();

  final FocusNode _captionFocusNode = FocusNode();

  bool _isPosting = false;

  static const int _maxCaptionLength = 500;

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocusNode.dispose();
    super.dispose();
  }

  // ==========================================================================
  // CREATE POST
  // ==========================================================================

  Future<void> _createPost() async {
    final caption = _captionController.text.trim();

    if (caption.isEmpty) {
      _showMessage('Please write something first.');
      _captionFocusNode.requestFocus();
      return;
    }

    if (caption.length > _maxCaptionLength) {
      _showMessage(
        'Caption can contain maximum $_maxCaptionLength characters.',
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await PostService.createPost(
        caption: caption,
        mediaUrl: '',
        mediaType: 'text',
      );

      if (!mounted) {
        return;
      }

      _captionController.clear();
      _captionFocusNode.unfocus();

      _showMessage('Post created successfully! 🎉');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(_cleanErrorMessage(e));
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPosting = false;
    });
  }

  // ==========================================================================
  // ERROR MESSAGE
  // ==========================================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission-denied') ||
        message.contains('missing or insufficient permissions')) {
      return 'Permission denied. Please check Firestore Rules.';
    }

    if (message.contains('user is not logged in')) {
      return 'Please login again.';
    }

    if (message.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'Could not create post. Please try again.';
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final captionLength = _captionController.text.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // TITLE
            // ----------------------------------------------------------------

            const Text(
              'Create Post',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Share something with your Gapshap community.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------------
            // TEXT POST CARD
            // ----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.edit_note, size: 55),
                  const SizedBox(height: 12),
                  Text(
                    'Text Post',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Photo & video posts will be added next.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------------
            // CAPTION
            // ----------------------------------------------------------------
            TextField(
              controller: _captionController,
              focusNode: _captionFocusNode,
              enabled: !_isPosting,
              maxLines: 8,
              minLines: 5,
              maxLength: _maxCaptionLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'What do you want to share?',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8, top: 14),
                  child: Icon(Icons.chat_outlined),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(width: 2),
                ),
                counterText: ' $captionLength / $_maxCaptionLength',
              ),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // PHOTO / VIDEO
            // ----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPosting
                        ? null
                        : () {
                            _showMessage(
                              'Photo upload will be available after '
                              'Storage setup.',
                            );
                          },
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPosting
                        ? null
                        : () {
                            _showMessage(
                              'Video upload will be available after '
                              'Storage setup.',
                            );
                          },
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------------
            // CREATE POST BUTTON
            // ----------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _isPosting ? null : _createPost,
                icon: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isPosting ? 'Posting...' : 'Create Post',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // INFORMATION
            // ----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your post will be saved to your Gapshap account '
                      'and shown in the Home feed.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
