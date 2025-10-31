import 'package:flutter/material.dart';
import 'base_controller.dart';

class SettingsController extends BaseController {
  static const String appVersion = '1.0.0';
  static const String appName = 'GymCraft';

  String getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      default:
        return 'Sistema';
    }
  }

  Future<void> performBackup() async {
    setLoading(true);
    try {
      // TODO: Implementar backup real
      await Future.delayed(const Duration(seconds: 1)); // Simular operação
      setError('Funcionalidade de backup em desenvolvimento');
    } catch (e) {
      setError('Erro ao fazer backup: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> performReset() async {
    setLoading(true);
    try {
      // TODO: Implementar reset real
      await Future.delayed(const Duration(seconds: 1)); // Simular operação
      setError('Funcionalidade de reset em desenvolvimento');
    } catch (e) {
      setError('Erro ao resetar dados: $e');
    } finally {
      setLoading(false);
    }
  }

  void showAppInfo() {
    // Esta função retorna dados para o dialog, não manipula UI
  }

  void showAboutInfo() {
    // Esta função retorna dados para o dialog, não manipula UI
  }

  List<String> getAboutSteps() {
    return [
      '1. Crie seus exercícios personalizados',
      '2. Monte seus treinos',
      '3. Organize em rotinas',
      '4. Execute e acompanhe seu progresso',
    ];
  }

  Map<String, String> getAppInfo() {
    return {
      'name': appName,
      'version': appVersion,
      'description': 'Seu aplicativo de treinos personalizado',
      'framework': 'Desenvolvido com Flutter',
    };
  }
}
