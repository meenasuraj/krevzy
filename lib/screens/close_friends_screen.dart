import 'package:flutter/material.dart';

import 'krevzy_people_list_screen.dart';

class CloseFriendsScreen extends StatelessWidget {
  const CloseFriendsScreen({super.key});
  @override
  Widget build(BuildContext context) => const KrevzyPeopleListScreen(
    title: 'Close Friends',
    collection: 'closeFriends',
    emptyText: 'No close friends yet.',
    icon: Icons.people_alt_outlined,
  );
}
