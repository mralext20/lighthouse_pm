import 'package:flutter/foundation.dart';
import 'package:lighthouse_pm/data/Database.dart';
import 'package:lighthouse_pm/lighthouseProvider/LighthousePowerState.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:rxdart/rxdart.dart';

class LighthousePMBloc {
  final LighthouseDatabase db;
  final SettingsBloc settings;

  LighthousePMBloc(LighthouseDatabase db)
      : db = db,
        settings = SettingsBloc(db);

  Stream<List<Nickname>> get watchSavedNicknames => db.watchSavedNicknames;

  Stream<Nickname /* ? */ > watchNicknameForMacAddress(String macAddress) {
    return db.watchNicknameForMacAddress(macAddress);
  }

  Future<int> insertNickname(Nickname nickname) =>
      db.insertNewNickname(nickname);

  Future deleteNicknames(List<String> macAddresses) =>
      db.deleteNicknames(macAddresses);

  Stream<List<NicknamesLastSeenJoin>> watchSavedNicknamesWithLastSeen() {
    return db.watchSavedNicknamesWithLastSeen();
  }

  Future<int> insertLastSeenDevice(LastSeenDevice lastSeen) {
    return db.insertLastSeenDevice(lastSeen);
  }

  Future<void> deleteAllLastSeen() {
    return db.deleteAllLastSeen();
  }

  void close() {
    db.close();
  }
}

class SettingsBloc {
  final LighthouseDatabase db;

  SettingsBloc(this.db);

  //IDS
  static const DEFAULT_SLEEP_STATE_ID = 1;

  Stream<LighthousePowerState> getSleepStateAsStream(
      {LighthousePowerState defaultValue = LighthousePowerState.SLEEP}) {
    final dbStream = (db.select(db.simpleSettings)
          ..where((tbl) => tbl.id.equals(DEFAULT_SLEEP_STATE_ID)))
        .watch()
        .map((event) {
      if (event.length >= 1 && event[0].data != null) {
        try {
          final data = int.parse(event[0].data, radix: 10);
          return LighthousePowerState.fromId(data);
        } on FormatException {
          debugPrint('Could not convert data returned to a string');
        }
      }
      return null;
    });
    return MergeStream([Stream.value(defaultValue), dbStream]);
  }

  Future<void> insertSleepState(LighthousePowerState sleepState) {
    assert(
        sleepState == LighthousePowerState.SLEEP ||
            sleepState == LighthousePowerState.STANDBY,
        'The new sleep state cannot be ${sleepState.text.toUpperCase()}');
    return db.into(db.simpleSettings).insert(
        SimpleSetting(
            id: DEFAULT_SLEEP_STATE_ID, data: sleepState.id.toString()),
        mode: InsertMode.insertOrReplace);
  }
}
