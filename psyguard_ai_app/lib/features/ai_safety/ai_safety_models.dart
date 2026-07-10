// AI安全介入邏輯
// 設計者：藍宥欣
// 三級介入系統

enum InterventionLevel {
  green,   // 第一級：自動推送心靈雞湯
  yellow,  // 第二級：AI主動發起關懷對話
  red,     // 第三級：系統提示聯絡輔導室
}

class InterventionConfig {
  final InterventionLevel level;
  final String message;
  final String? actionLabel;
  final String? actionRoute;
  final bool notifyCounselor;

  const InterventionConfig({
    required this.level,
    required this.message,
    this.actionLabel,
    this.actionRoute,
    this.notifyCounselor = false,
  });
}

class AISafetyEngine {
  // 根據ERS分數決定介入等級
  InterventionConfig evaluate(double ersScore, int consecutiveRedDays) {
    // 第三級：紅區（ERS>=70 且連續3天）
    if (ersScore >= 70 && consecutiveRedDays >= 3) {
      return const InterventionConfig(
        level: InterventionLevel.red,
        message: '守護精靈注意到你最近狀態需要支持，輔導老師已收到通知，是否需要今天和老師聊聊？',
        actionLabel: '好的，我想聊聊',
        actionRoute: '/safety',
        notifyCounselor: true,
      );
    }

    // 第三級：ERS>=70 單次
    if (ersScore >= 70) {
      return const InterventionConfig(
        level: InterventionLevel.red,
        message: '你今天承受了很多，守護精靈在這裡陪你。需要我幫你聯絡輔導室嗎？',
        actionLabel: '查看支援資源',
        actionRoute: '/safety',
        notifyCounselor: false,
      );
    }

    // 第二級：黃區（ERS 45~70）
    if (ersScore >= 45) {
      return const InterventionConfig(
        level: InterventionLevel.yellow,
        message: '最近感覺如何？守護精靈想和你說說話 💙',
        actionLabel: '和AI聊聊',
        actionRoute: '/chat',
        notifyCounselor: false,
      );
    }

    // 第一級：綠區
    return const InterventionConfig(
      level: InterventionLevel.green,
      message: '今天狀態不錯！繼續保持 ✨',
      notifyCounselor: false,
    );
  }

  // 高風險語言偵測
  bool detectHighRiskLanguage(String text) {
    const highRiskKeywords = [
      '不想活', '死', '消失', '沒有意義', '放棄',
      '撐不下去', '太累了', '不想了', '結束',
    ];
    return highRiskKeywords.any((kw) => text.contains(kw));
  }
}
