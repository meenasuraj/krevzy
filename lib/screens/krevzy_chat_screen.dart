import 'package:flutter/material.dart';

class KrevzyChatScreen extends StatefulWidget {
  final String conversationId;
  final String name;

  const KrevzyChatScreen({
    super.key,
    required this.conversationId,
    required this.name,
  });

  @override
  State<KrevzyChatScreen> createState() => _KrevzyChatScreenState();
}

class _KrevzyChatScreenState extends State<KrevzyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  final bool _isSending = false;
  final bool _isChatLocked = false;
  final bool _isUnlocked = true;
  final String currentUserId = 'user_123'; // Temporary ID

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    // TODO: Send message logic
    _messageController.clear();
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text(
                  'Add Money to Wallet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Top up your balance'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMoneyBottomSheet();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.red),
                title: const Text('Block User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ADD MONEY BOTTOM SHEET
  // ===========================================================================

  void _showAddMoneyBottomSheet() {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_card_rounded, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Add Money to Wallet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  hintText: 'Enter amount (e.g. 500)',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [100, 200, 500, 1000].map((amount) {
                  return ActionChip(
                    label: Text('+ ₹$amount'),
                    onPressed: () {
                      amountController.text = amount.toString();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text(
                    'Proceed to Pay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final amountText = amountController.text.trim();
                    if (amountText.isEmpty) return;

                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Processing payment for ₹$amountText...'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MESSAGES LIST & BUBBLE (PLACEHOLDERS)
  // ===========================================================================

  Widget _buildMessages() {
    return _buildEmptyConversation();
  }

  Widget _buildTypingIndicator() {
    return const SizedBox.shrink();
  }

  Widget _buildLockedView() {
    return const Center(
      child: Text('This chat is locked'),
    );
  }

  // ===========================================================================
  // EMPTY CONVERSATION PLACEHOLDER
  // ===========================================================================

  Widget _buildEmptyConversation() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send a message to start the conversation!',
            style: TextStyle(
              fontSize: 13.5,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INPUT BAR
  // ===========================================================================

  Widget _buildInputBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, -2),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 💰 WALLET BUTTON NEAR INPUT BAR
            IconButton(
              icon: Icon(
                Icons.account_balance_wallet_rounded,
                color: colorScheme.primary,
              ),
              tooltip: 'Add Money',
              onPressed: _showAddMoneyBottomSheet,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isChatLocked)
                    const Text(
                      '🔒 Locked Chat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 💰 WALLET BUTTON IN APPBAR
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            tooltip: 'Add Money to Wallet',
            onPressed: _showAddMoneyBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: _showChatMenu,
          ),
        ],
      ),
      body: !_isUnlocked
          ? _buildLockedView()
          : Column(
              children: [
                Expanded(child: _buildMessages()),
                _buildTypingIndicator(),
                _buildInputBar(),
              ],
            ),
    );
  }
}