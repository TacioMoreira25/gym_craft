import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/database_service.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import 'base_controller.dart';

class RoutineDetailController extends BaseController {
  final DatabaseService _databaseService = DatabaseService();
  final Routine routine;

  List<Workout> _workouts = [];
  bool _isReorderMode = false;

  List<Workout> get workouts => _workouts;
  bool get isReorderMode => _isReorderMode;

  RoutineDetailController({required this.routine});

  Future<void> loadData() async {
    setLoading(true);

    try {
      final workouts = await _databaseService.workouts.getWorkoutsByRoutine(
        routine.id!,
      );
      final orderedWorkouts = await _applyCustomOrder(workouts);

      _workouts = orderedWorkouts;
    } catch (e) {
      setError('Erro ao carregar dados: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<List<Workout>> _applyCustomOrder(List<Workout> workouts) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString('workout_order_${routine.id}');

      if (savedOrder == null) return workouts;

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<Workout> orderedWorkouts = [];

      for (int id in orderIds) {
        try {
          Workout workout = workouts.firstWhere((w) => w.id == id);
          orderedWorkouts.add(workout);
        } catch (e) {
          // Continue se não encontrar o workout
        }
      }

      for (Workout workout in workouts) {
        if (!orderedWorkouts.any((w) => w.id == workout.id)) {
          orderedWorkouts.add(workout);
        }
      }

      return orderedWorkouts;
    } catch (e) {
      return workouts;
    }
  }

  Future<void> saveWorkoutOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> workoutIds = _workouts.map((workout) => workout.id!).toList();
      await prefs.setString(
        'workout_order_${routine.id}',
        jsonEncode(workoutIds),
      );
    } catch (e) {
      setError('Erro ao salvar ordem dos treinos: $e');
    }
  }

  void enableReorderMode() {
    _isReorderMode = true;
    notifyListeners();
  }

  void exitReorderMode() {
    _isReorderMode = false;
    notifyListeners();
  }

  void reorderWorkouts(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _workouts.removeAt(oldIndex);
    _workouts.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> saveReorderAndExit() async {
    await saveWorkoutOrder();
    exitReorderMode();
  }

  Future<void> deleteWorkout(int workoutId) async {
    try {
      await _databaseService.workouts.deleteWorkout(workoutId);
      await loadData(); // Recarrega a lista
    } catch (e) {
      setError('Erro ao excluir treino: $e');
      rethrow;
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
