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
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ==========================================================================
  // DISABLED MEDIA MESSAGE
  // ==========================================================================

  void _showMediaComingSoon(String type) {
    _showMessage('$type upload will be available after Storage setup.');
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final captionLength = _captionController.text.length;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================================
            // HEADER
            // ==================================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: colorScheme.onPrimary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Post',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Share something with your community.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==================================================================
            // POST TYPE CARD
            // ==================================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.text_fields_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text Post',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Write your thoughts and start a conversation.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ==================================================================
            // WRITE AREA
            // ==================================================================
            Text(
              'What\'s on your mind?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: TextField(
                controller: _captionController,
                focusNode: _captionFocusNode,
                enabled: !_isPosting,
                maxLines: 9,
                minLines: 7,
                maxLength: _maxCaptionLength,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Write something you want to share...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Character counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Your post will be saved to KREVZY.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$captionLength / $_maxCaptionLength',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: captionLength > _maxCaptionLength
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ==================================================================
            // MEDIA OPTIONS
            // ==================================================================
            Text(
              'Add to your post',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _MediaOption(
                    icon: Icons.photo_outlined,
                    title: 'Photo',
                    subtitle: 'Coming soon',
                    onTap: _isPosting
                        ? null
                        : () {
                            _showMediaComingSoon('Photo');
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MediaOption(
                    icon: Icons.videocam_outlined,
                    title: 'Video',
                    subtitle: 'Coming soon',
                    onTap: _isPosting
                        ? null
                        : () {
                            _showMediaComingSoon('Video');
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==================================================================
            // POST BUTTON
            // ==================================================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isPosting ? null : _createPost,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isPosting
                      ? const Row(
                          key: ValueKey('posting'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Posting...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          key: ValueKey('post'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 21),
                            SizedBox(width: 10),
                            Text(
                              'Create Post',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================================
            // INFO CARD
            // ==================================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 19,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Your text post will appear in the Home feed '
                      'and will be linked to your KREVZY account.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
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

// ============================================================================
// MEDIA OPTION
// ============================================================================

class _MediaOption extends StatelessWidget {
  const _MediaOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(
                    alpha: enabled ? 1 : 0.55,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: colorScheme.primary.withValues(
                    alpha: enabled ? 1 : 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
