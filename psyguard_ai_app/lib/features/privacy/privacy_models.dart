// 隱私架構設計
// 設計者：藍宥欣
// 核心原則：去識別化、分層授權、學生信任感

enum DataAccessLevel {
  studentOnly,    // 只有學生本人可見（日記、對話原文）
  counselorStats, // 輔導老師可見（量化數值、PR值）
  adminAlert,     // 管理員警示（紅燈個案通知）
}

class PrivacyConfig {
  // 學生同意書狀態
  final bool hasConsent;
  final bool consentForCounselor;  // 同意輔導老師查看統計
  final bool consentForAlert;      // 同意紅燈時通報輔導室
  final DateTime? consentDate;

  const PrivacyConfig({
    this.hasConsent = false,
    this.consentForCounselor = false,
    this.consentForAlert = false,
    this.consentDate,
  });
}

class AnonymizedData {
  // 去識別化後的數據（可給輔導老師看的）
  final double ersScore;           // ERS分數
  final String riskLevel;          // 風險等級
  final double moodTrend;          // 情緒趨勢斜率
  final double stressTrend;        // 壓力趨勢斜率
  final int consecutiveRedDays;    // 連續紅燈天數

  const AnonymizedData({
    required this.ersScore,
    required this.riskLevel,
    required this.moodTrend,
    required this.stressTrend,
    required this.consecutiveRedDays,
  });

  // 是否需要主動通報
  bool get needsAlert =>
      riskLevel == 'red' && consecutiveRedDays >= 3 ||
      moodTrend <= -5.0 ||  // 急速惡化
      stressTrend >= 5.0;
}
