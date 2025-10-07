import 'package:flutter/material.dart';
import 'devices_tab.dart';
import 'settings_tab.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            Image.asset('assets/images/fire.png', height: 30),
            SizedBox(width: 8),
            Text('FireFlow', style: TextStyle(fontSize: 20)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Dispositivos'),
            Tab(text: 'Configurações'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DevicesTab(),
          SettingsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              shape: CircleBorder(),
              onPressed: () {
                // Adicionar função para "Adicionar dispositivo"
              },
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
