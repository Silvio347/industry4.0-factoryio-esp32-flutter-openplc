import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  void _editAccount(BuildContext context) {
    // TODO: Navegar para tela de edição de conta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar conta (a implementar)')),
    );
  }

  void _manageDevices(BuildContext context) {
    // TODO: Navegar para gerenciamento de dispositivos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gerenciar dispositivos (a implementar)')),
    );
  }

  void _deleteAccount(BuildContext context) {
    // TODO: Confirmar e chamar API para deletar conta
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir conta'),
        content: Text('Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Conta excluída (simulação)')),
              );
              // TODO: Navegar para tela de login ou sair do app
            },
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    // TODO: Limpar sessão e redirecionar para login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logout realizado (simulação)')),
    );
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.blueAccent,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: TextStyle(fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 16),
      children: [
        _buildOption(
          icon: Icons.person,
          label: 'Editar Conta',
          onTap: () => _editAccount(context),
        ),
        _buildOption(
          icon: Icons.devices,
          label: 'Gerenciar Dispositivos',
          onTap: () => _manageDevices(context),
        ),
        _buildOption(
          icon: Icons.delete_forever,
          label: 'Excluir Conta',
          iconColor: Colors.red,
          onTap: () => _deleteAccount(context),
        ),
        _buildOption(
          icon: Icons.logout,
          label: 'Sair',
          iconColor: Colors.grey,
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}
