import 'package:drift/drift.dart';

// 三層隱私架構（藍宥欣設計）
// Layer 1：日記層（本地，永遠不上傳）
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
}

// Layer 2：分析層（只存ERS分數，去識別化）
class ERSRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get anonymousId => text()();
  RealColumn get ersScore => real()();
  TextColumn get riskLevel => text()();
  RealColumn get languageScore => real()();
  RealColumn get physicalScore => real()();
  RealColumn get behaviorScore => real()();
  DateTimeColumn get date => dateTime()();
}

// Layer 3：通報層（只在Safety Flow啟動時才用）
class AlertRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get anonymousId => text()();
  TextColumn get alertType => text()();
  DateTimeColumn get triggeredAt => dateTime()();
  BoolColumn get counselorNotified =>
      boolean().withDefault(const Constant(false))();
}
