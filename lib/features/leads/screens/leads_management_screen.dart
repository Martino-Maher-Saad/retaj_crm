import 'package:flutter/material.dart';
import 'package:retaj_crm/data/models/profile_model.dart';

class LeadsManagementScreen extends StatelessWidget {
  final ProfileModel user;
  const LeadsManagementScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Leads Management Screen'),),);
  }
}
