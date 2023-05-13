import 'package:dongbaek/models/schedule.dart';
import 'package:dongbaek/proto/grpc.pbgrpc.dart';
import 'package:dongbaek/repositories/schedule_repository.dart';
import 'package:dongbaek/utils/pb_utils.dart';
import 'package:grpc/grpc.dart';

class GrpcScheduleRepository implements ScheduleRepository {
  final scheduleServiceApi = ScheduleServiceClient(
    ClientChannel(
      'localhost',
      port: 9090,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    ),
  );

  @override
  Future<void> addSchedule(ScheduleData s) async {
    final request = CreateScheduleRequest(title: s.title);
    await scheduleServiceApi.createSchedule(request);
  }

  @override
  Future<Schedule> getSchedule(ScheduleId id) async {
    return scheduleServiceApi
        .getSchedule(GetScheduleRequest(scheduleId: id.value))
        .asStream()
        .single
        .then((response) => response.schedule)
        .then((pbSchedule) => pbSchedule.toSchedule());
  }

  @override
  Future<List<Schedule>> getSchedules(DateTime currentDate) async {
    final response = await scheduleServiceApi.getSchedules(GetSchedulesRequest());
    return response.schedules.map((pbSchedule) => pbSchedule.toSchedule()).toList();
  }

  @override
  Future<void> completeSchedule(ScheduleId scheduleId, DateTime endDateTime) async {
    final getScheduleRequest = GetScheduleRequest(scheduleId: scheduleId.value);
    final pbSchedule = (await scheduleServiceApi.getSchedule(getScheduleRequest)).schedule;
    pbSchedule.finishDate = PbUtils.asPbTimestamp(endDateTime);
    final replaceScheduleRequest = ReplaceScheduleRequest(schedule: pbSchedule);
    await scheduleServiceApi.replaceSchedule(replaceScheduleRequest);
  }

  @override
  Future<void> removeSchedule(ScheduleId scheduleId) async {
    await scheduleServiceApi.deleteSchedule(DeleteScheduleRequest(scheduleId: scheduleId.value));
  }
}
