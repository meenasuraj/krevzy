import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/wallet_service.dart';
import 'add_money_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const Color _background = Color(0xFFF8F7FF);
  static const Color _primary = Color(0xFF625B9B);

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }
    return 'Pending';
  }

  String _statusText(dynamic value) {
    final status = (value ?? 'unknown').toString().toLowerCase();
    switch (status) {
      case 'success':
      case 'verified':
      case 'completed':
        return 'Completed';
      case 'pending':
      case 'submitted':
        return 'Pending';
      case 'failed':
      case 'failure':
        return 'Failed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletService = WalletService.instance;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'KREVZY Wallet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _background,
        foregroundColor: const Color(0xFF20202A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<double>(
        stream: walletService.balanceStream(),
        initialData: 0,
        builder: (context, balanceSnapshot) {
          final balance = balanceSnapshot.data ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF625B9B), Color(0xFF8278C2)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddMoneyScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Money'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Balance changes only after trusted payment verification.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20202A),
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: walletService.transactionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _InfoCard(
                      icon: Icons.info_outline_rounded,
                      text: 'Unable to load transactions right now.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const _InfoCard(
                      icon: Icons.receipt_long_outlined,
                      text: 'No verified wallet transactions yet.',
                    );
                  }

                  return Card(
                    elevation: 0,
                    color: const Color(0xFFF0EEFF),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final status = _statusText(data['status']);
                        final rawAmount = data['amount'];
                        final amount = rawAmount is num
                            ? rawAmount.toDouble()
                            : double.tryParse(rawAmount?.toString() ?? '') ?? 0;

                        final type =
                            (data['type'] ?? data['direction'] ?? 'payment')
                                .toString()
                                .toLowerCase();
                        final credit =
                            type == 'credit' ||
                            type == 'topup' ||
                            type == 'received';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (credit ? Colors.green : _primary)
                                .withValues(alpha: 0.10),
                            child: Icon(
                              credit
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: credit ? Colors.green : _primary,
                            ),
                          ),
                          title: Text(
                            (data['title'] ??
                                    data['description'] ??
                                    (credit ? 'Wallet credit' : 'Payment'))
                                .toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${_formatDate(data['createdAt'])} • $status',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${credit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: credit
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF0EEFF),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF625B9B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF555361)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
