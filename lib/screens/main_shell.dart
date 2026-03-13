import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_bloc.dart';
import 'package:where_ma_money_go/blocs/bills/bills_event.dart';
import 'package:where_ma_money_go/blocs/savings/saving_bloc.dart';
import 'package:where_ma_money_go/blocs/savings/saving_event.dart';
import 'package:where_ma_money_go/blocs/envelop/envelop_bloc.dart';
import 'package:where_ma_money_go/blocs/envelop/envelop_event.dart';
import 'package:where_ma_money_go/providers/theme/theme_provider.dart';
import 'package:where_ma_money_go/screens/bills.dart';
import 'package:where_ma_money_go/screens/dashboard.dart';
import 'package:where_ma_money_go/screens/notes.dart';
import 'package:where_ma_money_go/screens/settings.dart';
import 'package:where_ma_money_go/screens/digital_envelop.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    BillsScreen(),
    NotesScreen(),
    DigitalEnvelopScreen(),
    SettingsScreen(),
  ];

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    _refreshBlocs();
  }

  void _refreshBlocs() {
    context.read<BillsBloc>().add(LoadBills());
    context.read<SavingBloc>().add(LoadSavings());
    context.read<EnvelopBloc>().add(LoadEnvelops());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        fixedColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        onTap: _onTabTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Facturas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cases_rounded),
            label: 'Sobres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuraciones',
          ),
        ],
      ),
    );
  }
}
