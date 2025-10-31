import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/database_service.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import 'base_controller.dart';

class HomeController extends BaseController {
  final DatabaseService _databaseService = DatabaseService();

  List<Routine> _routines = [];
  bool _isReorderMode = false;
  final Map<int, List<Workout>> _workoutsByRoutine = {};
  final Set<int> _expandedRoutines = {};
  final Set<int> _loadingRoutineWorkouts = {};

  List<Routine> get routines => _routines;
  bool get isReorderMode => _isReorderMode;
  Map<int, List<Workout>> get workoutsByRoutine => _workoutsByRoutine;
  Set<int> get expandedRoutines => _expandedRoutines;
  Set<int> get loadingRoutineWorkouts => _loadingRoutineWorkouts;

  Future<void> initialize() async {
    await loadRoutines();
  }

  Future<void> loadRoutines() async {
    setLoading(true);
    try {
      final routines = await _databaseService.routines.getAllRoutines();
      final orderedRoutines = await _applyCustomOrder(routines);
      _routines = orderedRoutines;
    } catch (e) {
      setError('Erro ao carregar rotinas: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> toggleExpand(Routine routine) async {
    final id = routine.id!;
    if (_expandedRoutines.contains(id)) {
      _expandedRoutines.remove(id);
      notifyListeners();
      return;
    }

    _expandedRoutines.add(id);
    notifyListeners();

    if (!_workoutsByRoutine.containsKey(id)) {
      await loadWorkoutsForRoutine(id);
    }
  }

  Future<void> loadWorkoutsForRoutine(int routineId) async {
    if (_loadingRoutineWorkouts.contains(routineId)) return;

    _loadingRoutineWorkouts.add(routineId);
    notifyListeners();

    try {
      final workouts = await _databaseService.workouts.getWorkoutsByRoutine(
        routineId,
      );
      final ordered = await _applyWorkoutOrder(routineId, workouts);
      _workoutsByRoutine[routineId] = ordered;
    } catch (e) {
      setError('Erro ao carregar treinos: $e');
    } finally {
      _loadingRoutineWorkouts.remove(routineId);
      notifyListeners();
    }
  }

  Future<List<Workout>> _applyWorkoutOrder(
    int routineId,
    List<Workout> workouts,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrder = prefs.getString('workout_order_$routineId');
      if (savedOrder == null) return workouts;

      final orderIds = List<int>.from(jsonDecode(savedOrder));
      final ordered = <Workout>[];

      for (final id in orderIds) {
        final wIndex = workouts.indexWhere((w) => w.id == id);
        if (wIndex != -1) ordered.add(workouts[wIndex]);
      }

      for (final w in workouts) {
        if (!ordered.any((ow) => ow.id == w.id)) ordered.add(w);
      }

      return ordered;
    } catch (_) {
      return workouts;
    }
  }

  Future<void> refreshRoutineWorkouts(int routineId) async {
    if (_expandedRoutines.contains(routineId)) {
      await loadWorkoutsForRoutine(routineId);
    }
  }

  Future<List<Routine>> _applyCustomOrder(List<Routine> routines) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString('routine_order');

      if (savedOrder == null) {
        return routines;
      }

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<Routine> orderedRoutines = [];

      for (int id in orderIds) {
        try {
          Routine routine = routines.firstWhere((r) => r.id == id);
          orderedRoutines.add(routine);
        } catch (e) {
          // Continue se não encontrar a routine
        }
      }

      for (Routine routine in routines) {
        if (!orderedRoutines.any((r) => r.id == routine.id)) {
          orderedRoutines.add(routine);
        }
      }

      return orderedRoutines;
    } catch (e) {
      return routines;
    }
  }

  Future<void> saveRoutineOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> routineIds = _routines.map((routine) => routine.id!).toList();
      await prefs.setString('routine_order', jsonEncode(routineIds));
    } catch (e) {
      setError('Erro ao salvar ordem das rotinas: $e');
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

  void reorderRoutines(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Routine item = _routines.removeAt(oldIndex);
    _routines.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> saveReorderAndExit() async {
    await saveRoutineOrder();
    exitReorderMode();
  }

  Future<void> deleteRoutine(int routineId) async {
    try {
      setLoading(true);
      await _databaseService.routines.deleteRoutine(routineId);
      await loadRoutines();
    } catch (e) {
      setError('Erro ao deletar rotina: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteWorkout(int workoutId) async {
    try {
      await _databaseService.workouts.deleteWorkout(workoutId);
    } catch (e) {
      setError('Erro ao deletar treino: $e');
      rethrow;
    }
  }

  Future<void> saveWorkoutOrder(int routineId, List<Workout> workouts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutIds = workouts.map((w) => w.id!).toList();
      await prefs.setString('workout_order_$routineId', jsonEncode(workoutIds));
    } catch (e) {
      setError('Erro ao salvar ordem dos treinos: $e');
    }
  }

  String formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
