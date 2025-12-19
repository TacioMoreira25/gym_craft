import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../models/routine.dart';
import '../../data/services/database_service.dart';
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/snackbar_utils.dart';
import 'app_dialog.dart';

class EditRoutineDialog extends StatefulWidget {
  final Routine routine;
  final VoidCallback onUpdated;

  const EditRoutineDialog({
    Key? key,
    required this.routine,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends State<EditRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descriptionController = TextEditingController(
      text: widget.routine.description,
    );
    _isActive = widget.routine.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedRoutine = Routine(
        id: widget.routine.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: widget.routine.createdAt,
        isActive: _isActive,
      );

      await _databaseService.routines.updateRoutine(updatedRoutine);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdated();
        SnackBarUtils.showUpdateSuccess(
          context,
          'Rotina atualizada com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showOperationError(
          context,
          'atualizar rotina',
          e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Editar Rotina',
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Rotina',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRoutineName,
              ),
              const SizedBox(height: 16),

              // Campo Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Switch Ativo/Inativo
              Row(
                children: [
                  const Icon(Icons.toggle_on, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rotina Ativa',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ],
              ),

              // Informação adicional
              if (!_isActive) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rotinas inativas não aparecerão na lista principal',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _updateRoutine,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
