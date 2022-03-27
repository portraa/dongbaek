import 'package:dongbaek/models/progress.dart';
import 'package:dongbaek/repositories/progress_repository.dart';
import 'package:dongbaek/utils/datetime_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalProgressRepository implements ProgressRepository {
  final Future<SharedPreferences> _sf = SharedPreferences.getInstance();

  @override
  Future<Map<int, Progress>> getProgressMap(DateTime targetDate) async {
    final scheduleIds = await _findScheduleIds(targetDate);
    final entryFutures = scheduleIds.map((scheduleId) async {
      final key = _formatProgressKey(scheduleId, targetDate);
      final completeTimes = await _findCompleteTimes(key);
      return MapEntry(scheduleId, Progress(completeTimes));
    });
    final entries = await Stream.fromFutures(entryFutures).toList();
    return Map.fromEntries(entries);
  }

  @override
  Future<void> addProgress(int scheduleId, DateTime completeTime) async {
    await _addScheduleId(scheduleId, completeTime);
    final key = _formatProgressKey(scheduleId, completeTime);
    final lastCompleteTimes = await _findCompleteTimes(key);
    final completeTimes = (lastCompleteTimes + [completeTime]).map((dateTime) => dateTime.toString()).toList();
    (await _sf).setStringList(key, completeTimes);
  }

  Future<List<DateTime>> _findCompleteTimes(String key) async {
    return (((await _sf).getStringList(key) ?? []).map((dtStr) => DateTime.parse(dtStr))).toList();
  }

  Future<List<int>> _findScheduleIds(DateTime date) async {
    final key = _formatScheduleIdsKey(date);
    return ((await _sf).getStringList(key)?.map((idStr) => int.parse(idStr)))?.toList() ?? [];
  }

  Future<void> _addScheduleId(int scheduleId, DateTime dateTime) async {
    final key = _formatScheduleIdsKey(dateTime);
    final beforeScheduleIds = await _findScheduleIds(dateTime);
    if (!beforeScheduleIds.contains(scheduleId)) {
      (await _sf).setStringList(key, (beforeScheduleIds + [scheduleId]).map((id) => id.toString()).toList());
    }
  }

  String _formatScheduleIdsKey(DateTime date) => "scheduleIds_${DateTimeUtils.asEpochDay(date)}";

  String _formatProgressKey(int scheduleId, DateTime date) =>
      "progresses_${scheduleId}_${DateTimeUtils.asEpochDay(date)}";
}
