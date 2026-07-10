// ERS - Emotional Risk Score 情緒風險分析引擎
// 設計者：藍宥欣
// 三個串流：語言、生理、行為

class ERSInput {
  // 串流一：語言訊號（權重40%）
  final double speechRate;        // 語速（字/分鐘）
  final double negativeWordRatio; // 負面詞彙密度（0~1）
  final double pauseFrequency;    // 停頓頻率

  // 串流二：生理訊號（權重35%）
  final double moodScore;         // 情緒穩定度（0~100）
  final double stressScore;       // 心理負荷感（0~100）
  final double energyScore;       // 心理韌性值（0~100）

  // 串流三：行為訊號（權重25%）
  final double sleepDuration;     // 睡眠時數
  final double appUsageStreak;    // 連續使用天數
  final double checkInConsistency; // 打卡一致性

  const ERSInput({
    required this.speechRate,
    required this.negativeWordRatio,
    required this.pauseFrequency,
    required this.moodScore,
    required this.stressScore,
    required this.energyScore,
    required this.sleepDuration,
    required this.appUsageStreak,
    required this.checkInConsistency,
  });
}

class ERSResult {
  final double rawERS;       // 原始分數（0~100）
  final double adjustedERS;  // 個人基線校正後
  final String riskLevel;    // 'green' / 'yellow' / 'red'
  final String riskLabel;    // 顯示文字
  final Map<String, double> streamScores; // 三串流分數

  const ERSResult({
    required this.rawERS,
    required this.adjustedERS,
    required this.riskLevel,
    required this.riskLabel,
    required this.streamScores,
  });
}

// 個人基線（用來校正ERS）
class PersonalBaseline {
  final double avgMood;
  final double avgStress;
  final double avgEnergy;
  final double avgSleepDuration;
  final int sampleCount;

  const PersonalBaseline({
    this.avgMood = 50,
    this.avgStress = 50,
    this.avgEnergy = 50,
    this.avgSleepDuration = 7,
    this.sampleCount = 0,
  });
}
