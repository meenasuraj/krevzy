import 'package:flutter/material.dart';
import '../services/krevzy_social_settings_service.dart';

class MessageStoryRepliesScreen extends StatefulWidget {
  const MessageStoryRepliesScreen({super.key});
  @override State<MessageStoryRepliesScreen> createState() => _MessageStoryRepliesScreenState();
}
class _MessageStoryRepliesScreenState extends State<MessageStoryRepliesScreen> {
  String messages = 'Everyone', replies = 'Everyone';
  Future<void> save(String k, String v) async => KrevzySocialSettingsService.setValue(k, v);
  Widget choice(String title, String key, String value, List<String> items) {
    return ListTile(title: Text(title), subtitle: Text(value), trailing: DropdownButton<String>(value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) {
      if (v != null) {
        setState(() { if (key == 'messages') { messages = v; } else { replies = v; } });
        save(key, v);
      }
    }));
  }
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Message and story replies')), body: ListView(children: [choice('Who can message you', 'messages', messages, ['Everyone', 'People you follow', 'No one']), choice('Who can reply to your stories', 'story_replies', replies, ['Everyone', 'People you follow', 'Close Friends', 'No one'])]));
}

class TagsMentionsScreen extends StatefulWidget {
  const TagsMentionsScreen({super.key});
  @override State<TagsMentionsScreen> createState() => _TagsMentionsScreenState();
}
class _TagsMentionsScreenState extends State<TagsMentionsScreen> {
  String tags = 'Everyone', mentions = 'Everyone';
  bool loading = true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { try { final d=await KrevzySocialSettingsService.getSettings(); if(!mounted)return; setState((){tags=d['tags']?.toString()??'Everyone';mentions=d['mentions']?.toString()??'Everyone';loading=false;}); } catch(e){ if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Unable to load tag settings: $e')));} } }
  Future<void> save(String k, String v) async { try{await KrevzySocialSettingsService.setValue(k,v);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Setting saved.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Unable to save: $e')));}}
  Widget row(String title, String key, String value) => ListTile(title:Text(title),subtitle:Text(value),trailing:DropdownButton<String>(value:value,items:['Everyone','People you follow','No one'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v){if(v!=null){setState(()=>key=='tags'?tags=v:mentions=v);save(key,v);}}));
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Tags and mentions')),body:loading?const Center(child:CircularProgressIndicator()):ListView(children:[row('Who can tag you','tags',tags),row('Who can mention you','mentions',mentions),const ListTile(title:Text('Manual approval'),subtitle:Text('Use this control before tagged content appears on your profile.'))]));
}
class LimitInteractionsScreen extends StatefulWidget {
  const LimitInteractionsScreen({super.key});
  @override State<LimitInteractionsScreen> createState() => _LimitInteractionsScreenState();
}
class _LimitInteractionsScreenState extends State<LimitInteractionsScreen> {
  bool enabled = false; int duration = 1;
  Future<void> save() async { await KrevzySocialSettingsService.setValue('limit_interactions', enabled); await KrevzySocialSettingsService.setValue('limit_interactions_days', duration); }
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Limit interactions')), body: ListView(padding: const EdgeInsets.all(8), children: [SwitchListTile(title: const Text('Limit interactions'), subtitle: const Text('Reduce unwanted comments, messages and mentions.'), value: enabled, onChanged: (v) { setState(() { enabled = v; }); save(); }), ListTile(title: const Text('Duration'), trailing: DropdownButton<int>(value: duration, items: [1, 3, 7, 14].map((v) => DropdownMenuItem(value: v, child: Text('$v days'))).toList(), onChanged: (v) { if (v != null) { setState(() { duration = v; }); save(); } }))]));
}
