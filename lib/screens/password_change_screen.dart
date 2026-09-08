import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});
  @override State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false, obscureCurrent = true, obscureNext = true, obscureConfirm = true;

  @override void dispose() { current.dispose(); next.dispose(); confirm.dispose(); super.dispose(); }

  Future<void> _change() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) { _msg('Please log in again.'); return; }
    if (current.text.isEmpty || next.text.length < 6 || next.text != confirm.text) {
      _msg('Enter your current password, a new password of at least 6 characters, and matching confirmation.'); return;
    }
    setState(() => loading = true);
    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: current.text);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(next.text);
      if (!mounted) return;
      _msg('Password changed successfully.');
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (mounted) _msg(e.code == 'wrong-password' || e.code == 'invalid-credential' ? 'Current password is incorrect.' : (e.message ?? e.code));
    } catch (e) { if (mounted) _msg('Unable to change password: $e'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Widget _field(TextEditingController c, String label, bool obscure, VoidCallback eye) => TextField(controller:c, obscureText:obscure, decoration:InputDecoration(labelText:label,border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:eye,icon:Icon(obscure?Icons.visibility_outlined:Icons.visibility_off_outlined))));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Change password')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Change your KREVZY password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('For security, we verify your current password before changing it.'),
      const SizedBox(height: 24),
      _field(current,'Current password',obscureCurrent,()=>setState(()=>obscureCurrent=!obscureCurrent)),
      const SizedBox(height: 14), _field(next,'New password',obscureNext,()=>setState(()=>obscureNext=!obscureNext)),
      const SizedBox(height: 14), _field(confirm,'Confirm new password',obscureConfirm,()=>setState(()=>obscureConfirm=!obscureConfirm)),
      const SizedBox(height: 24), SizedBox(width:double.infinity,height:50,child:FilledButton(onPressed:loading?null:_change,child:loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)):const Text('Change password'))),
    ]),
  );
}
