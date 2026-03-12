import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        fixedColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
