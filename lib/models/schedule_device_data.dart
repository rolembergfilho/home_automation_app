import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/utils/custom_exception.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/models/device_data.dart';

class Schedule {
  int _dvID, _scheduleID;
  String _deviceName,
      _roomName,
      _startTime,
      _endTime,
      _repetition,
      _afterStatus,
      _createdDate;
  Schedule(
      this._scheduleID,
      this._dvID,
      this._deviceName,
      this._roomName,
      this._startTime,
      this._endTime,
      this._repetition,
      this._afterStatus,
      _createdDate);
  Schedule.map(dynamic obj) {
    this._dvID = null;
    if (obj['dvID'] != null) {
      this._dvID = int.parse(obj['dvID']);
    }
    if (obj['scheduleID'] != null) {
      this._scheduleID = int.parse(obj['scheduleID']);
    }
    this._deviceName = obj['deviceName'];
    this._roomName = obj['roomName'];
    this._startTime = obj['startTime'];
    this._endTime = obj['endTime'];
    this._repetition = obj['repetition'];
    this._afterStatus = obj['afterStatus'];
    this._createdDate = obj['createdDate'];
  }
  int get dvID => _dvID;
  int get scheduleID => _scheduleID;
  String get deviceName => _deviceName;
  String get roomName => _roomName;
  String get startTIme => _startTime;
  String get endTime => _endTime;
  String get repetition => _repetition;
  String get afterStatus => _afterStatus;
  String get createdDate => _createdDate;

  Map<String, dynamic> toMap() {
    Map obj = new Map();
    obj['dvID'] = this._dvID.toString();
    obj['scheduleID'] = this._scheduleID.toString();
    obj['deviceName'] = this._deviceName;
    obj['roomName'] = this._roomName;
    obj['startTime'] = this._startTime;
    obj['endTime'] = this._endTime;
    obj['repetition'] = this._repetition;
    obj['afterStatus'] = this._afterStatus;
    obj['createdDate'] = this._createdDate;
    return obj;
  }

  @override
  String toString() {
    return dvID.toString();
  }
}

class RequestSchedule {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final finalURL = baseURL + "/schedule_device.php";

  Future<List<Schedule>> getSchedule(
      User user, String deviceName, String roomName) async {
    return _netUtil.post(finalURL, body: {
      "action": "2",
      "email": user.email,
      "deviceName": deviceName,
      "roomName": roomName,
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      int total = int.parse(res['totalRows'].toString());
      List<Schedule> scheduleList = new List<Schedule>();
      for (int i = 0; i < total; i++) {
        scheduleList.add(Schedule.map(res['scheduleInfo'][i]));
      }
      return scheduleList;
    });
  }

  Future<String> setSchedule(
      User user,
      Room room,
      Device device,
      String startTime,
      String endTime,
      String repetition,
      String afterStatus) async {
    return _netUtil.post(finalURL, body: {
      "action": "1",
      "email": user.email,
      "deviceName": device.dvName,
      "roomName": room.roomName,
      "startTime": startTime,
      "endTime": endTime,
      "repetition": repetition,
      "afterStatus": afterStatus,
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return res['data'];
    });
  }

  Future<String> removeSchedule(User user, Schedule schedule) async {
    return _netUtil.post(finalURL, body: {
      "action": "4",
      "email": user.email,
      "scheduleID": schedule.scheduleID.toString()
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return res['data'];
    });
  }

  Future<List<Schedule>> getScheduleList(User user) async {
    return _netUtil.post(finalURL, body: {
      "action": "3",
      "email": user.email,
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      try {
        int total = int.parse(res['totalRows'].toString());
        List<Schedule> scheduleList = new List<Schedule>();
        for (int i = 0; i < total; i++) {
          scheduleList.add(Schedule.map(res['scheduledDevice'][i]));
        }
        return scheduleList;
      } on Exception catch (error) {
        return null;
      }
    });
  }

  Future<String> removeScheduleForDevice(
      User user, Device device, Room room) async {
    return _netUtil.post(finalURL, body: {
      "action": "5",
      "email": user.email,
      "deviceName": device.dvName.toString(),
      "roomName": room.roomName.toString(),
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return res['data'];
    });
  }
}

abstract class ScheduleContract {
  void onScheduleSuccess(String message);
  void onScheduleError(String errorTxt);
}

class SchedulePresenter {
  ScheduleContract _view;
  RequestSchedule api = new RequestSchedule();
  SchedulePresenter(this._view);
  doSetSchedule(User user, Room room, Device device, String startTime,
      String endTime, String repetition, String afterStatus) async {
    try {
      String message = await api.setSchedule(
          user, room, device, startTime, endTime, repetition, afterStatus);
      _view.onScheduleSuccess(message);
    } on Exception catch (error) {
      _view.onScheduleError(error.toString());
    }
  }

  doRemoveSchedule(User user, Schedule schedule) async {
    try {
      String message = await api.removeSchedule(user, schedule);
      _view.onScheduleSuccess(message);
    } on Exception catch (error) {
      _view.onScheduleError(error.toString());
    }
  }

  doRemoveScheduleForDevice(User user, Device device, Room room) async {
    try {
      String message = await api.removeScheduleForDevice(user, device, room);
      _view.onScheduleSuccess(message);
    } on Exception catch (error) {
      _view.onScheduleError(error.toString());
    }
  }
}
