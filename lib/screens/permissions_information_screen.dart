import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PermissionsInformationScreen extends StatefulWidget {
  const PermissionsInformationScreen({super.key});
  @override
  State<PermissionsInformationScreen> createState() =>
      _PermissionsInformationScreenState();
}

class _PermissionsInformationScreenState
    extends State<PermissionsInformationScreen> {
  bool loading = true, exporting = false;
  Map<String, dynamic> data = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final s = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      if (mounted)setState(() {data = s.data() ?? {};loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _msg('Unable to load account information: $e');
      }
    }
  }

  void _msg(String x) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));
  Future<void> _export() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    setState(() => exporting = true);
    try {
      final out = Map<String, dynamic>.from(data);
      out.remove('password');
      out['uid'] = u.uid;
      out['email'] = u.email;
      out['exportedAt'] = DateTime.now().toUtc().toIso8601String();
      final safeOut = _makeJsonSafe(out);
      final text = const JsonEncoder.withIndent('  ').convert(safeOut);
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'KREVZY account information'),
      );
    } catch (e) {
      _msg('Unable to export information: $e');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  dynamic _makeJsonSafe(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key.toString(), _makeJsonSafe(value)),
      );
    }
    if (value is Iterable) {
      return value.map(_makeJsonSafe).toList();
    }
    return value;
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Your permission and information')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ListTile(
                title: Text(
                  'Account information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Review the information currently stored for your KREVZY account.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'Not available',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Username'),
                subtitle: Text(data['username']?.toString() ?? 'Not set'),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('User ID'),
                subtitle: Text(
                  FirebaseAuth.instance.currentUser?.uid ?? 'Not available',
                ),
              ),
              const Divider(),
              const ListTile(
                title: Text('Device permissions'),
                subtitle: Text(
                  'Camera, photos, microphone, location and notifications are controlled by your device operating system.',
                ),
              ),
              FilledButton.icon(
                onPressed: exporting ? null : _export,
                icon: const Icon(Icons.download_outlined),
                label: Text(
                  exporting ? 'Preparing...' : 'Export my information',
                ),
              ),
            ],
          ),
  );
}
