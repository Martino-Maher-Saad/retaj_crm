import 'package:flutter/material.dart';

import '../../../core/widgets/custom_search_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: CustomSearchBar(),
          ),
          Center(
            child: Text('Dashboard Screen'),
          ),
        ],
      ),
    );
  }
}
