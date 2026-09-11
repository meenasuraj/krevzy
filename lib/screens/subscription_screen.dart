import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 64),
          const SizedBox(height: 16),
          const Text(
            'KREVZY Premium',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Premium plans can include enhanced themes, media limits and creator features.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: const Text('Current plan'),
              subtitle: const Text('Free'),
              trailing: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Subscription checkout will be connected to the payment provider before launch.',
                      ),
                    ),
                  );
                },
                child: const Text('View plans'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
