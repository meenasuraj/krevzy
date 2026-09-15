import 'package:flutter/material.dart';

import 'personal_profile_details_screen.dart';
import 'password_security_screen.dart';
import 'connected_experience_screen.dart';
import 'permissions_information_screen.dart';
import 'ad_preferences_screen.dart';
import 'subscription_screen.dart';
import 'media_gallery_screen.dart';
import 'manage_account_screen.dart';

class AccountCenterScreen extends StatelessWidget {
  const AccountCenterScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account Centre', style: TextStyle(fontWeight: FontWeight.bold))),
    body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Container(margin: const EdgeInsets.fromLTRB(16,16,16,10),padding: const EdgeInsets.all(18),decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),gradient: const LinearGradient(colors:[Color(0xFFFFC7EA),Color(0xFFD9CCFF),Color(0xFFBEEBFF)])),child: const Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Text('KREVZY Account Centre',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:Color(0xFF111B55))),SizedBox(height:6),Text('Manage your profile, security, connected experiences and account controls.',style:TextStyle(color:Color(0xFF26305F)))])),
      _section('Account'),
      _tile(context,Icons.person_outline,'Personal and profile details','Name, username and bio',const PersonalProfileDetailsScreen()),
      _tile(context,Icons.password_outlined,'Password and security','Password, sessions and security',const PasswordSecurityScreen()),
      _tile(context,Icons.hub_outlined,'Connected experience','Contacts, suggestions and cross-device settings',const ConnectedExperienceScreen()),
      _section('Information & preferences'),
      _tile(context,Icons.verified_user_outlined,'Your permission and information','Permissions, downloads and account information',const PermissionsInformationScreen()),
      _tile(context,Icons.ads_click_outlined,'Ad preference','Personalized and activity-based ad controls',const AdPreferencesScreen()),
      _tile(context,Icons.workspace_premium_outlined,'Subscription','Manage your KREVZY plan',const SubscriptionScreen()),
      _tile(context,Icons.photo_library_outlined,'Your Media gallery','Photos and videos you have posted',const MediaGalleryScreen()),
      _section('Account control'),
      _tile(context,Icons.manage_accounts_outlined,'Manage account','Deactivate, delete or log out',const ManageAccountScreen()),
    ]));
  static Widget _section(String s)=>Padding(padding:const EdgeInsets.fromLTRB(20,20,20,8),child:Text(s,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800,letterSpacing:.4)));
  static Widget _tile(BuildContext c,IconData i,String t,String s,Widget page)=>ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:20,vertical:5),leading:Container(width:44,height:44,decoration:BoxDecoration(borderRadius:BorderRadius.circular(14),color:Theme.of(c).colorScheme.primary.withValues(alpha:.10)),child:Icon(i)),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text(s),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page)));
}
