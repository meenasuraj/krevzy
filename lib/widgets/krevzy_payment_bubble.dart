import 'package:flutter/material.dart';

import '../models/krevzy_payment.dart';

class KrevzyPaymentBubble extends StatelessWidget {
  final KrevzyPayment payment;
  final bool isMe;

  const KrevzyPaymentBubble({
    super.key,
    required this.payment,
    required this.isMe,
  });

  Color _statusColor(BuildContext context, KrevzyPaymentStatus status) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case KrevzyPaymentStatus.success:
        return Colors.green;

      case KrevzyPaymentStatus.pending:
      case KrevzyPaymentStatus.processing:
        return Colors.orange;

      case KrevzyPaymentStatus.failed:
        return scheme.error;

      case KrevzyPaymentStatus.cancelled:
        return Colors.grey;

      case KrevzyPaymentStatus.draft:
        return scheme.primary;
    }
  }

  String _statusText(KrevzyPaymentStatus status) {
    switch (status) {
      case KrevzyPaymentStatus.success:
        return 'Successful';

      case KrevzyPaymentStatus.processing:
        return 'Processing';

      case KrevzyPaymentStatus.pending:
        return 'Pending';

      case KrevzyPaymentStatus.failed:
        return 'Failed';

      case KrevzyPaymentStatus.cancelled:
        return 'Cancelled';

      case KrevzyPaymentStatus.draft:
        return 'Draft';
    }
  }

  IconData _statusIcon(KrevzyPaymentStatus status) {
    switch (status) {
      case KrevzyPaymentStatus.success:
        return Icons.check_circle_rounded;

      case KrevzyPaymentStatus.processing:
        return Icons.sync_rounded;

      case KrevzyPaymentStatus.pending:
        return Icons.schedule_rounded;

      case KrevzyPaymentStatus.failed:
        return Icons.error_rounded;

      case KrevzyPaymentStatus.cancelled:
        return Icons.cancel_rounded;

      case KrevzyPaymentStatus.draft:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final statusColor = _statusColor(context, payment.status);

    return Container(
      constraints: const BoxConstraints(maxWidth: 310),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isMe ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_rupee_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'You sent' : 'Payment received',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(payment.status), size: 17, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  _statusText(payment.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          if (payment.note.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              payment.note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],

          const SizedBox(height: 10),

          Text(
            'Test reference: ${payment.transactionRef}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
