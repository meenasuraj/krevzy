import 'package:flutter/material.dart';

import '../services/krevzy_social_settings_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});
  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String lang = 'English';
  final langs = ['English', 'Hindi', 'Hinglish'];
  Future<void> save(String v) async {
    setState(() {
      lang = v;
    });
    await KrevzySocialSettingsService.setValue('language', v);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Languages')),
    body: RadioGroup<String>(
      groupValue: lang,
      onChanged: (x) {
        if (x != null) {
          save(x);
        }
      },
      child: ListView(
        children: langs
            .map((v) => RadioListTile<String>(title: Text(v), value: v))
            .toList(),
      ),
    ),
  );
}
