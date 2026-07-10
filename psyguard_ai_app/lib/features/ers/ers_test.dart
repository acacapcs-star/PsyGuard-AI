import 'ers_engine.dart';
import 'ers_models.dart';

void main() {
  final engine = ERSEngine();
  final baseline = PersonalBaseline(
    avgMood: 60,
    avgStress: 40,
    avgEnergy: 65,
    avgSleepDuration: 7.5,
    sampleCount: 14,
  );

  // ── 情境一：綠燈（狀態良好）──────────────────
  final green = engine.calculate(
    ERSInput(
      speechRate: 300,
      negativeWordRatio: 0.1,
      pauseFrequency: 1,
      moodScore: 80,
      stressScore: 20,
      energyScore: 75,
      sleepDuration: 8,
      appUsageStreak: 10,
      checkInConsistency: 0.9,
    ),
    baseline,
  );
  print('=== 情境一：綠燈 ===');
  print('Raw ERS: ${green.rawERS.toStringAsFixed(1)}');
  print('Adjusted ERS: ${green.adjustedERS.toStringAsFixed(1)}');
  print('風險等級: ${green.riskLabel}');
  print('串流分數: ${green.streamScores}');
  print('');

  // ── 情境二：黃燈（需要留意）──────────────────
  final yellow = engine.calculate(
    ERSInput(
      speechRate: 200,
      negativeWordRatio: 0.45,
      pauseFrequency: 5,
      moodScore: 45,
      stressScore: 60,
      energyScore: 40,
      sleepDuration: 5.5,
      appUsageStreak: 3,
      checkInConsistency: 0.5,
    ),
    baseline,
  );
  print('=== 情境二：黃燈 ===');
  print('Raw ERS: ${yellow.rawERS.toStringAsFixed(1)}');
  print('Adjusted ERS: ${yellow.adjustedERS.toStringAsFixed(1)}');
  print('風險等級: ${yellow.riskLabel}');
  print('串流分數: ${yellow.streamScores}');
  print('');

  // ── 情境三：紅燈（需要關注）──────────────────
  final red = engine.calculate(
    ERSInput(
      speechRate: 130,
      negativeWordRatio: 0.8,
      pauseFrequency: 10,
      moodScore: 15,
      stressScore: 85,
      energyScore: 10,
      sleepDuration: 3,
      appUsageStreak: 0,
      checkInConsistency: 0.1,
    ),
    baseline,
  );
  print('=== 情境三：紅燈 ===');
  print('Raw ERS: ${red.rawERS.toStringAsFixed(1)}');
  print('Adjusted ERS: ${red.adjustedERS.toStringAsFixed(1)}');
  print('風險等級: ${red.riskLabel}');
  print('串流分數: ${red.streamScores}');
}
