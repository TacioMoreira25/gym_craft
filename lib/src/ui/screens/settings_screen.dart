import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsController(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Configurações'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          body: ListView(
            children: [
              // Seção Aparência
              _buildSectionHeader(context, 'Aparência'),
              _buildThemeOption(context),

              const Divider(height: 32),

              // Seção Aplicativo
              _buildSectionHeader(context, 'Aplicativo'),
              _buildAppInfoTile(context, controller),
              _buildAboutTile(context, controller),

              const Divider(height: 32),

              // Seção Dados
              _buildSectionHeader(context, 'Dados'),
              _buildBackupTile(context, controller),
              _buildResetTile(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildThemeOption(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final controller = context.read<SettingsController>();

        return ExpansionTile(
          leading: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Tema'),
          subtitle: Text(controller.getThemeName(themeProvider.themeMode)),
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

  Widget _buildAppInfoTile(
    BuildContext context,
    SettingsController controller,
  ) {
    return ListTile(
      leading: Icon(
        Icons.info_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Informações do App'),
      subtitle: Text(
        '${SettingsController.appName} v${SettingsController.appVersion}',
      ),
      onTap: () => _showAppInfoDialog(context, controller),
    );
  }

  Widget _buildAboutTile(BuildContext context, SettingsController controller) {
    return ListTile(
      leading: Icon(
        Icons.help_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Sobre'),
      subtitle: const Text('Como usar o aplicativo'),
      onTap: () => _showAboutDialog(context, controller),
    );
  }

  Widget _buildBackupTile(BuildContext context, SettingsController controller) {
    return ListTile(
      leading: Icon(Icons.backup, color: Theme.of(context).colorScheme.primary),
      title: const Text('Backup dos Dados'),
      subtitle: const Text('Exportar seus dados'),
      onTap: controller.isLoading
          ? null
          : () => _handleBackup(context, controller),
      trailing: controller.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  Widget _buildResetTile(BuildContext context, SettingsController controller) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.restore, color: theme.colorScheme.error),
      title: Text(
        'Restaurar Dados',
        style: TextStyle(color: theme.colorScheme.error),
      ),
      subtitle: const Text('Apagar todos os dados do aplicativo'),
      onTap: controller.isLoading
          ? null
          : () => _showResetDialog(context, controller),
      trailing: controller.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  void _showAppInfoDialog(BuildContext context, SettingsController controller) {
    final appInfo = controller.getAppInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appInfo['name']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versão: ${appInfo['version']}'),
            const SizedBox(height: 8),
            Text(appInfo['description']!),
            const SizedBox(height: 8),
            Text(appInfo['framework']!),
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
  }

  void _showAboutDialog(BuildContext context, SettingsController controller) {
    final steps = controller.getAboutSteps();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como usar o GymCraft'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(step),
                  ),
                )
                .toList(),
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
  }

  Future<void> _handleBackup(
    BuildContext context,
    SettingsController controller,
  ) async {
    await controller.performBackup();

    if (context.mounted && controller.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: Colors.orange,
        ),
      );
      controller.clearError();
    }
  }

  void _showResetDialog(BuildContext context, SettingsController controller) {
    final theme = Theme.of(context);

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
              _showFinalConfirmationDialog(context, controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmationDialog(
    BuildContext context,
    SettingsController controller,
  ) {
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
              await _handleReset(context, controller);
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

  Future<void> _handleReset(
    BuildContext context,
    SettingsController controller,
  ) async {
    await controller.performReset();

    if (context.mounted && controller.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: Colors.orange,
        ),
      );
      controller.clearError();
    }
  }
}
