import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database_executor.dart';
import '../network/ai_local_messages.dart';

part 'app_database.g.dart';

class ChatSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get lastRiskLevel => text().withDefault(const Constant('low'))();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(ChatSessions, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get riskTag => text().nullable()();
}

class ChatContextSummaries extends Table {
  TextColumn get sessionId => text().references(ChatSessions, #id)();
  TextColumn get summary => text()();
  IntColumn get summarizedUntilMessageId => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {sessionId};
}

class DailyCheckins extends Table {
  DateTimeColumn get date => dateTime()();
  IntColumn get moodScore => integer()();
  IntColumn get stressScore => integer()();
  IntColumn get energyScore => integer()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {date};
}

class SleepLogs extends Table {
  DateTimeColumn get date => dateTime()();
  RealColumn get sleepHours => real()();
  IntColumn get difficulty => integer()();
  DateTimeColumn get bedtime => dateTime()();
  DateTimeColumn get waketime => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => {date};
}

class RiskSnapshots extends Table {
  DateTimeColumn get date => dateTime()();
  TextColumn get riskLevel => text()();
  IntColumn get riskScore => integer()();
  TextColumn get reasonsJson => text()();

  @override
  Set<Column<Object>>? get primaryKey => {date};
}

class ToolUsages extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get toolId => text()();
  IntColumn get durationSec => integer()();
  BoolColumn get completed => boolean()();
}

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get time => dateTime().withDefault(currentDateAndTime)();
  TextColumn get eventType => text()();
  TextColumn get metaJson => text()();
}

class AiReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get rangeDays => integer()();
  TextColumn get content => text()();
}

@DriftDatabase(
  tables: [
    ChatSessions,
    ChatMessages,
    ChatContextSummaries,
    DailyCheckins,
    SleepLogs,
    RiskSnapshots,
    ToolUsages,
    AuditLogs,
    AiReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openAppDatabaseExecutor(name: 'psyguard_ai_mvp'));

  AppDatabase.memory() : super(openInMemoryDatabaseExecutor());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(aiReports);
        }
        if (from < 3) {
          await m.createTable(chatContextSummaries);
        }
        if (from < 4) {
          await customStatement('''
            UPDATE daily_checkins
            SET
              mood_score = CASE
                WHEN mood_score BETWEEN 0 AND 4 THEN mood_score * 25
                ELSE mood_score
              END,
              stress_score = CASE
                WHEN stress_score BETWEEN 0 AND 4 THEN stress_score * 25
                ELSE stress_score
              END,
              energy_score = CASE
                WHEN energy_score BETWEEN 0 AND 4 THEN energy_score * 25
                ELSE energy_score
              END
          ''');
        }
      },
    );
  }

  DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> clearAllData() async {
    await transaction(() async {
      await batch((b) {
        b.deleteAll(chatMessages);
        b.deleteAll(chatContextSummaries);
        b.deleteAll(chatSessions);
        b.deleteAll(dailyCheckins);
        b.deleteAll(sleepLogs);
        b.deleteAll(riskSnapshots);
        b.deleteAll(toolUsages);
        b.deleteAll(auditLogs);
        b.deleteAll(aiReports);
      });
    });
  }

  Future<void> saveAiReport({
    required int rangeDays,
    required String content,
  }) async {
    await into(
      aiReports,
    ).insert(AiReportsCompanion.insert(rangeDays: rangeDays, content: content));
  }

  Future<List<AiReport>> getAllAiReports() {
    return (select(
      aiReports,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<String> ensureDefaultSession() async {
    final existing =
        await (select(chatSessions)
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    final sessionId = const Uuid().v4();
    await into(
      chatSessions,
    ).insert(ChatSessionsCompanion.insert(id: sessionId));
    return sessionId;
  }

  Stream<List<ChatMessage>> watchSessionMessages(String sessionId) {
    return (select(chatMessages)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<ChatMessage>> getSessionMessages(String sessionId) {
    return (select(chatMessages)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> insertChatMessage({
    required String sessionId,
    required String role,
    required String content,
    String? riskTag,
  }) async {
    await into(chatMessages).insert(
      ChatMessagesCompanion.insert(
        sessionId: sessionId,
        role: role,
        content: content,
        riskTag: Value(riskTag),
      ),
    );
  }

  Future<void> cleanupLocalOnlyAiArtifacts() async {
    await transaction(() async {
      await (delete(chatMessages)..where(
            (tbl) =>
                tbl.role.equals('ai') &
                tbl.content.isIn(localOnlyAssistantReplies.toList()),
          ))
          .go();

      final summaries = await select(chatContextSummaries).get();
      final contaminatedSessionIds = summaries
          .where(
            (summary) =>
                localOnlyAssistantReplies.any(summary.summary.contains),
          )
          .map((summary) => summary.sessionId)
          .toList();

      if (contaminatedSessionIds.isEmpty) {
        return;
      }

      await (delete(
        chatContextSummaries,
      )..where((tbl) => tbl.sessionId.isIn(contaminatedSessionIds))).go();
    });
  }

  Future<void> updateSessionRisk(String sessionId, String riskLevel) {
    return (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(lastRiskLevel: Value(riskLevel)),
    );
  }

  Future<ChatContextSummary?> getChatContextSummary(String sessionId) {
    return (select(
      chatContextSummaries,
    )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
  }

  Future<void> upsertChatContextSummary({
    required String sessionId,
    required String summary,
    required int summarizedUntilMessageId,
  }) async {
    await into(chatContextSummaries).insertOnConflictUpdate(
      ChatContextSummariesCompanion.insert(
        sessionId: sessionId,
        summary: summary,
        summarizedUntilMessageId: summarizedUntilMessageId,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> upsertDailyCheckin({
    required DateTime date,
    required int mood,
    required int stress,
    required int energy,
    String? note,
  }) async {
    final normalized = normalizeDay(date);
    await into(dailyCheckins).insertOnConflictUpdate(
      DailyCheckinsCompanion.insert(
        date: normalized,
        moodScore: _normalizePercentScore(mood),
        stressScore: _normalizePercentScore(stress),
        energyScore: _normalizePercentScore(energy),
        note: Value(note),
      ),
    );
  }

  int _normalizePercentScore(int value) => value.clamp(0, 100);

  Future<void> upsertSleepLog({
    required DateTime date,
    required double sleepHours,
    required int difficulty,
    required DateTime bedtime,
    required DateTime waketime,
  }) async {
    final normalized = normalizeDay(date);
    await into(sleepLogs).insertOnConflictUpdate(
      SleepLogsCompanion.insert(
        date: normalized,
        sleepHours: sleepHours,
        difficulty: difficulty,
        bedtime: bedtime,
        waketime: waketime,
      ),
    );
  }

  Future<void> upsertRiskSnapshot({
    required DateTime date,
    required String riskLevel,
    required int riskScore,
    required List<String> reasons,
  }) async {
    await into(riskSnapshots).insertOnConflictUpdate(
      RiskSnapshotsCompanion.insert(
        date: normalizeDay(date),
        riskLevel: riskLevel,
        riskScore: riskScore,
        reasonsJson: jsonEncode(reasons),
      ),
    );
  }

  Future<void> insertToolUsage({
    required DateTime date,
    required String toolId,
    required int durationSec,
    required bool completed,
  }) {
    return into(toolUsages).insert(
      ToolUsagesCompanion.insert(
        date: date,
        toolId: toolId,
        durationSec: durationSec,
        completed: completed,
      ),
    );
  }

  Future<void> logAudit({
    required String eventType,
    required Map<String, dynamic> meta,
  }) {
    return into(auditLogs).insert(
      AuditLogsCompanion.insert(
        eventType: eventType,
        metaJson: jsonEncode(meta),
      ),
    );
  }

  Future<List<ChatMessage>> getMessagesSince(DateTime since) {
    return (select(
      chatMessages,
    )..where((t) => t.createdAt.isBiggerOrEqualValue(since))).get();
  }

  Future<List<DailyCheckin>> getCheckinsSince(DateTime since) {
    return (select(
      dailyCheckins,
    )..where((t) => t.date.isBiggerOrEqualValue(since))).get();
  }

  Future<List<SleepLog>> getSleepLogsSince(DateTime since) {
    return (select(
      sleepLogs,
    )..where((t) => t.date.isBiggerOrEqualValue(since))).get();
  }

  Future<List<ToolUsage>> getToolUsageSince(DateTime since) {
    return (select(
      toolUsages,
    )..where((t) => t.date.isBiggerOrEqualValue(since))).get();
  }

  Future<List<ToolUsage>> getAllToolUsages() {
    return (select(
      toolUsages,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  Future<List<DailyCheckin>> getAllCheckins() {
    return (select(
      dailyCheckins,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  Future<List<SleepLog>> getAllSleepLogs() {
    return (select(
      sleepLogs,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  Future<RiskSnapshot?> getLatestRiskSnapshot() {
    return (select(riskSnapshots)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DailyCheckin?> getTodayCheckin() {
    final today = normalizeDay(DateTime.now());
    return (select(
      dailyCheckins,
    )..where((t) => t.date.equals(today))).getSingleOrNull();
  }

  Future<SleepLog?> getTodaySleepLog() {
    final today = normalizeDay(DateTime.now());
    return (select(
      sleepLogs,
    )..where((t) => t.date.equals(today))).getSingleOrNull();
  }

  Future<Map<String, dynamic>> buildSummaryData({int days = 7, bool isZh = true}) async {
    final since = normalizeDay(
      DateTime.now().subtract(Duration(days: days - 1)),
    );
    final checkins = await getCheckinsSince(since);
    final sleeps = await getSleepLogsSince(since);
    final risks =
        await (select(riskSnapshots)
              ..where((t) => t.date.isBiggerOrEqualValue(since))
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();
    final tools = await getToolUsageSince(since);

    final allReasons = <String>[];
    for (final risk in risks) {
      final decoded = jsonDecode(risk.reasonsJson) as List<dynamic>;
      allReasons.addAll(decoded.map((e) => e.toString()));
    }

    final reasonCount = <String, int>{};
    for (final reason in allReasons) {
      reasonCount.update(reason, (v) => v + 1, ifAbsent: () => 1);
    }

    final sortedReasons = reasonCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 🔒 reasons 依語言翻譯（原本存中文，英文模式匯出翻英）
    String localizeReason(String zh) {
      if (isZh) return zh;
      const table = {
        '當下心情明顯偏低': 'Mood clearly low',
        '當下心情偏低': 'Mood low',
        '當下心情略低': 'Mood slightly low',
        '當下壓力明顯偏高': 'Stress clearly high',
        '當下壓力偏高': 'Stress high',
        '當下壓力略高': 'Stress slightly high',
        '當下活力明顯偏低': 'Energy clearly low',
        '當下活力偏低': 'Energy low',
        '心情低落且壓力偏高': 'Low mood with high stress',
        '心情低落且活力偏低': 'Low mood with low energy',
        '當下狀態穩定': 'Stable',
        '目前指標穩定，建議持續每日檢視': 'Indicators are stable — keep checking in daily',
      };
      return table[zh] ?? zh;
    }

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'windowDays': days,
      'last7Days': {
        'moodTrend': checkins
            .map(
              (c) => {
                'date': c.date.toIso8601String(),
                'moodScore': c.moodScore,
                'stressScore': c.stressScore,
                'energyScore': c.energyScore,
              },
            )
            .toList(),
        'sleepTrend': sleeps
            .map(
              (s) => {
                'date': s.date.toIso8601String(),
                'sleepHours': s.sleepHours,
                'difficulty': s.difficulty,
              },
            )
            .toList(),
        'riskTrend': risks
            .map(
              (r) => {
                'date': r.date.toIso8601String(),
                'riskLevel': r.riskLevel,
                'riskScore': r.riskScore,
              },
            )
            .toList(),
      },
      'topReasons': sortedReasons
          .take(5)
          .map((e) => {'reason': localizeReason(e.key), 'count': e.value})
          .toList(),
      'helpActions': {
        'toolUsageCount': tools.length,
        'completedToolCount': tools.where((t) => t.completed).length,
      },
      // 🔒 去識別化聲明（對齊摘要：僅分享分數，不含日記）
      'privacy': {
        'deIdentified': true,
        'note': isZh
            ? '此報告僅含情緒分數與統計，不含任何日記內容，可安全分享給家長或輔導人員。'
            : 'This report contains only mood scores and statistics, no diary content. Safe to share with guardians or counselors.',
      },
    };
  }
}
