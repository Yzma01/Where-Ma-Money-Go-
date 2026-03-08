import 'package:flutter/material.dart';

class AddBillScreen extends StatefulWidget {
  @override
  State<AddBillScreen> createState() => _AddBillState();
}

class _AddBillState extends State<AddBillScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Bill')),
      body: SafeArea(child: Center(child: Text('Add Bill Screen'))),
    );
  }
}
