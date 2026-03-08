import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/bills/bills_state.dart';
import 'package:where_ma_money_go/screens/add_bill.dart';
import 'package:where_ma_money_go/widgets/bill_widget.dart';

class BillsScreen extends StatefulWidget {
  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BillsBloc>().add(LoadBills());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bills'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<BillsBloc>().add(LoadBills());
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddBillScreen()),
              );
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<BillsBloc, BillsState>(
          builder: (context, state) {
            if (state is BillsLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is BillsLoaded) {
              return state.bills.isEmpty
                  ? Center(child: Text('No bills found'))
                  : ListView.builder(
                      itemCount: state.bills.length,
                      itemBuilder: (context, index) {
                        final bill = state.bills[index];
                        return BillWidget(bill: bill);
                      },
                    );
            } else if (state is BillsError) {
              return Center(child: Text('Failed to load bills'));
            }
            return Container();
          },
        ),
      ),
    );
  }
}
