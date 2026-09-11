import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});
  @override State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  String? currentId;
  bool preparing = true;

  @override void initState() { super.initState(); _prepare(); }
  Future<void> _prepare() async {
    try {
      await SessionService.ensureSession();
      currentId = await SessionService.getSessionId();
    } catch (e) { debugPrint('Session prepare: $e'); }
    if (mounted) setState(() => preparing = false);
  }

  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not signed in')));
    if (preparing) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final stream = FirebaseFirestore.instance.collection('users').doc(uid).collection('sessions').snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Where you are logged in')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _Error(text: 'Unable to load sessions.\n${snapshot.error}');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((d) => d.data()['endedAt'] == null).toList();
          docs.sort((a, b) {
            final av = a.data()['lastActiveAt'];
            final bv = b.data()['lastActiveAt'];
            final at = av is Timestamp ? av : Timestamp.fromMillisecondsSinceEpoch(0);
            final bt = bv is Timestamp ? bv : Timestamp.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          if (docs.isEmpty) return const Center(child: Text('No active KREVZY sessions found.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final id = data['sessionId']?.toString() ?? docs[i].id;
              final current = id == currentId;
              return Card(child: ListTile(
                leading: Icon(current ? Icons.phone_android_rounded : Icons.devices_other_rounded),
                title: Text(data['device']?.toString() ?? 'KREVZY device'),
                subtitle: Text('${data['platform'] ?? 'Mobile'}\nStarted ${_format(data['startedAt'])} • Active ${_format(data['lastActiveAt'])}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () async {
                    try {
                      if (current) {
                        await SessionService.endSession();
                        await FirebaseAuth.instance.signOut();
                      } else {
                        await SessionService.revokeSession(id);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session signed out.')));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to sign out: $e')));
                    }
                  },
                ),
              ));
            },
          );
        },
      ),
    );
  }

  static String _format(dynamic value) => value is Timestamp ? value.toDate().toLocal().toString().split('.').first : '—';
}

class _Error extends StatelessWidget {
  final String text;
  const _Error({required this.text});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, textAlign: TextAlign.center)));
}
