import 'package:flutter/material.dart';

class SavingPlan extends StatefulWidget {
  const SavingPlan({super.key});

  @override
  State<SavingPlan> createState() => _SavingPlanState();
}

class _SavingPlanState extends State<SavingPlan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Saving Plan')));
  }
}
