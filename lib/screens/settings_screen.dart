import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          // Seção Aparência
          _buildSectionHeader('Aparência'),
          _buildThemeOption(),
          
          const Divider(height: 32),
          
          // Seção Aplicativo
          _buildSectionHeader('Aplicativo'),
          _buildAppInfoTile(),
          _buildAboutTile(),
          
          const Divider(height: 32),
          
          // Seção Dados
          _buildSectionHeader('Dados'),
          _buildBackupTile(),
          _buildResetTile(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeOption() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ExpansionTile(
          leading: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Tema'),
          subtitle: Text(_getThemeName(themeProvider.themeMode)),
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              subtitle: const Text('Sempre usar tema claro'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Escuro'),
              subtitle: const Text('Sempre usar tema escuro'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sistema'),
              subtitle: const Text('Seguir configuração do sistema'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      default:
        return 'Sistema';
    }
  }

  Widget _buildAppInfoTile() {
    return ListTile(
      leading: Icon(
        Icons.info_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Informações do App'),
      subtitle: const Text('GymCraft v1.0.0'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('GymCraft'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versão: 1.0.0'),
                SizedBox(height: 8),
                Text('Seu aplicativo de treinos personalizado'),
                SizedBox(height: 8),
                Text('Desenvolvido com Flutter'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: Icon(
        Icons.help_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Sobre'),
      subtitle: const Text('Como usar o aplicativo'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Como usar o GymCraft'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Crie seus exercícios personalizados'),
                  SizedBox(height: 8),
                  Text('2. Monte seus treinos'),
                  SizedBox(height: 8),
                  Text('3. Organize em rotinas'),
                  SizedBox(height: 8),
                  Text('4. Execute e acompanhe seu progresso'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupTile() {
    return ListTile(
      leading: Icon(
        Icons.backup,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Backup dos Dados'),
      subtitle: const Text('Exportar seus dados'),
      onTap: () {
        // Implementar backup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidade de backup em desenvolvimento'),
          ),
        );
      },
    );
  }

  Widget _buildResetTile() {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        Icons.restore,
        color: theme.colorScheme.error,
      ),
      title: Text(
        'Restaurar Dados',
        style: TextStyle(color: theme.colorScheme.error),
      ),
      subtitle: const Text('Apagar todos os dados do aplicativo'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Restauração'),
            content: const Text(
              'Esta ação irá apagar TODOS os seus dados (exercícios, treinos, rotinas, histórico). Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmReset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: const Text('Restaurar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmReset() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ÚLTIMA CONFIRMAÇÃO'),
        content: const Text(
          'Tem certeza absoluta? Todos os dados serão perdidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implementar reset
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade de reset em desenvolvimento'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('CONFIRMAR RESET'),
          ),
        ],
      ),
    );
  }
}