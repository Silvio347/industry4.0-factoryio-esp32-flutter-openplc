import 'package:factory_appflutter_tank/pages/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:factory_appflutter_tank/models/device.dart';

class DevicesTab extends StatefulWidget {
  const DevicesTab({super.key});
  @override
  _DevicesTabState createState() => _DevicesTabState();
}

class _DevicesTabState extends State<DevicesTab> {
  List<Device> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // --- SIMULAÇÃO LOCAL ---
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _devices = [
          Device(
            id: "dev123",
            name: "Tanque de Teste",
            type: "Sensor Ultrassônico",
            userId: "usr456",
            // preencha outros campos se existirem no seu Device model
          ),
        ];
        _isLoading = false;
      });
    });

    // --- DESCOMENTE para voltar a API real ---
    // _fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    if (_devices.isEmpty) {
      return Center(
        child: Text(
          'Nenhum dispositivo encontrado',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: ListTile(
            leading: const Icon(Icons.device_hub, color: Colors.blueAccent),
            title: Text(
              device.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Tipo: ${device.type}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(device: device),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
